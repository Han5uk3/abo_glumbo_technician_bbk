import 'dart:io';

import 'package:aboglumbo_bbk_panel/common_widget/saving_stack.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/regex.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aboglumbo_bbk_panel/helpers/image_picker_helper.dart';
import 'package:image_picker/image_picker.dart';

class AddNewCategories extends StatefulWidget {
  final CategoryModel? category;
  const AddNewCategories({super.key, this.category});

  @override
  State<AddNewCategories> createState() => _AddNewCategoriesState();
}

class _AddNewCategoriesState extends State<AddNewCategories> {
  final _formKey = GlobalKey<FormState>();
  bool isActive = false;
  XFile? selectedImage;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameArController = TextEditingController();
  final TextEditingController nameUrController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController descriptionArController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    _fillOutFields();
    super.initState();
  }

  void _fillOutFields() {
    if (widget.category != null) {
      nameController.text = widget.category!.name ?? '';
      nameArController.text = widget.category!.name_ar ?? '';
      nameUrController.text = widget.category!.name_ur ?? '';
      isActive = widget.category!.isActive ?? false;
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePickerConfigs.pickCategoryImage(context);

      if (image == null) return;

      setState(() {
        selectedImage = image;
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.imageLoadError ??
                  'Error picking image: ${e.toString()}',
            ),

            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveCategory() async {
    final isLoading =
        context.read<ManageAppBloc>().state is AddingCategory ||
        context.read<ManageAppBloc>().state is UpdatingCategory;
    if (isLoading) return;

    final hasImage = selectedImage != null || widget.category?.svg != null;

    if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectAnImage ??
                'Please select an image.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (widget.category == null) {
      try {
        await checkCategoryExistence(nameController.text.trim());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.categoryAlreadyExists),
            backgroundColor: Colors.red,
          ),
        );
        return; // Stop execution if duplicate found
      }
    }

    if (_formKey.currentState!.validate()) {
      final category = CategoryModel(
        id: widget.category?.id,
        name: nameController.text.trim(),
        name_ar: nameArController.text.trim(),
        name_ur: nameUrController.text.trim(),
        isActive: isActive,
        icon: widget.category?.icon,
        svg: widget.category?.svg,
      );

      if (widget.category == null) {
        await checkCategoryExistence(nameController.text.trim());
        // Adding new category
        context.read<ManageAppBloc>().add(
          AddCategoryEvent(category, imageFile: selectedImage),
        );
      } else {
        // Updating existing category
        context.read<ManageAppBloc>().add(
          UpdateCategoryEvent(category, imageFile: selectedImage),
        );
      }
    }
  }

  checkCategoryExistence(String categoryName) async {
    try {
      final category = await AppFirestore.categoriesCollectionRef
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();
      if (category.docs.isNotEmpty) {
        throw Exception(
          AppLocalizations.of(context)?.categoryNameAlreadyExists ??
              'Category name already exists',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    nameArController.dispose();
    nameUrController.dispose();
    descriptionController.dispose();
    descriptionArController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    return BlocConsumer<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is CategoryAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.categoryAddedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is CategoryUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.categoryUpdatedSuccessfully ??
                    'Category updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is CategoryAddError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.errorAddingCategory ?? 'Error adding category'}: ${state.error}',
              ),
            ),
          );
        } else if (state is CategoryUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.errorUpdatingCategory ?? 'Error updating category'}: ${state.error}',
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AddingCategory || state is UpdatingCategory;

        return PopScope(
          canPop: !isLoading,
          child: AbsorbPointer(
            absorbing: isLoading,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  widget.category == null
                      ? AppLocalizations.of(context)!.addCategory
                      : AppLocalizations.of(context)!.editCategory,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: isLoading ? null : _saveCategory,
                  ),
                ],
              ),
              body: SavingStackWidget(
                isSaving: isLoading,
                isLoading: false,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: safePadding.bottom,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: nameController,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)?.name ?? 'Name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(
                                context,
                              )?.pleaseEnterAName;
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: nameArController,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)?.nameArabic ??
                                'Name (Arabic)',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(
                                context,
                              )!.pleaseEnterNameInArabic;
                            } else if (!Regex.arabicFullRegex.hasMatch(value)) {
                              return AppLocalizations.of(
                                context,
                              )!.textMustBeInArabic;
                            }

                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: nameUrController,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Name (Urdu)',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter name in Urdu';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)?.active ??
                                    'Active',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Switch(
                              activeThumbColor: AppColors.primary,
                              value: isActive,
                              onChanged: isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        isActive = value;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.image ?? 'Image',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment:
                            Directionality.of(context) == TextDirection.rtl
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: isLoading ? null : _pickImage,
                            child: DottedBorder(
                              color: Colors.grey.withOpacity(0.5),
                              strokeWidth: 1.5,
                              dashPattern: const [6, 4],
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  color: Colors.grey.withOpacity(0.05),
                                  child: selectedImage != null
                                      ? Image.file(
                                          File(selectedImage!.path),
                                          fit: BoxFit.cover,
                                          width: 130,
                                          height: 130,
                                        )
                                      : widget.category?.svg != null
                                      ? CachedNetworkImage(
                                          imageUrl: widget.category?.svg ?? "",
                                          fit: BoxFit.cover,
                                          width: 130,
                                          height: 130,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        )
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons
                                                  .add_photo_alternate_outlined,
                                              size: 32,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              AppLocalizations.of(
                                                    context,
                                                  )?.pickImage ??
                                                  'Pick Image',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
