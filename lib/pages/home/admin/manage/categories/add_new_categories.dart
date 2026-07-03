import 'dart:io';

import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/delete_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/removable_image.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/regex.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
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
  bool shouldRemoveExistingImage = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameArController = TextEditingController();
  final TextEditingController nameUrController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController descriptionArController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  XFile? selectedImage;
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

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        // Check if file exists
        final file = File(image.path);
        if (!await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)?.selectedFileCouldNotBeFound ??
                      'Selected file could not be found. Please try again.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          selectedImage = image;
          shouldRemoveExistingImage = false;
        });
        await cropImage();
      }
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

  Future cropImage() async {
    try {
      CroppedFile? res = await ImageCropper().cropImage(
        sourcePath: selectedImage!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
          ),
          IOSUiSettings(
            title: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            cancelButtonTitle: AppLocalizations.of(context)?.cancel ?? 'Cancel',
            doneButtonTitle: AppLocalizations.of(context)?.done ?? 'Done',
          ),
        ],
      );

      if (res != null) {
        setState(() {
          selectedImage = XFile(res.path);
          shouldRemoveExistingImage = false; // Ensure this is reset
        });
      } else {
        final bool? shouldKeepImage = await showCropConfirmDialog(context);

        if (shouldKeepImage != true) {
          setState(() {
            selectedImage = null;
            shouldRemoveExistingImage = false; // Reset this too
          });
        }
        // If shouldKeepImage is true, we keep the original selectedImage as is
        // and ensure shouldRemoveExistingImage is false
        else {
          setState(() {
            shouldRemoveExistingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.imageCropError ??
                  'Error cropping image',
            ),
          ),
        );
      }
    }
  }

  void _removeImage() {
    showDeleteConfirmDialog(context)
        .then((shouldDelete) {
          if (shouldDelete == true && mounted) {
            setState(() {
              if (selectedImage != null) {
                selectedImage = null;
              } else if (widget.category?.svg != null) {
                shouldRemoveExistingImage = true;
              }
            });
          }
        })
        .catchError((error) {
          debugPrint('Error showing delete confirmation dialog: $error');
        });
  }

  void _saveCategory() async {
    final isLoading =
        context.read<ManageAppBloc>().state is AddingCategory ||
        context.read<ManageAppBloc>().state is UpdatingCategory;
    if (isLoading) return;

    final hasImage =
        selectedImage != null ||
        (widget.category?.svg != null && !shouldRemoveExistingImage);

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

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.category == null
                  ? AppLocalizations.of(context)!.addCategory
                  : AppLocalizations.of(context)!.editCategory,
            ),
            actions: [
              if (!isLoading)
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveCategory,
                ),
              if (isLoading)
                Padding(
                  padding: EdgeInsets.only(right: 16, left: 16),
                  child: Loader(size: 10, color: Colors.white),
                ),
            ],
          ),
          body: Form(
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
                      labelText: AppLocalizations.of(context)?.name ?? 'Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)?.pleaseEnterAName;
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
                        return AppLocalizations.of(context)!.textMustBeInArabic;
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
                    decoration: const InputDecoration(labelText: 'Name (Urdu)'),
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
                          AppLocalizations.of(context)?.active ?? 'Active',
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        AppColors.primary,
                      ),
                    ),
                    onPressed: isLoading ? null : () => pickImage(),
                    icon: const Icon(Icons.image),
                    label: Text(
                      AppLocalizations.of(context)?.pickImage ?? 'Pick Image',
                    ),
                  ),
                ),
                if ((selectedImage != null) ||
                    (widget.category?.svg != null &&
                        !shouldRemoveExistingImage))
                  RemovableImageWidget(
                    key: ValueKey(
                      '${selectedImage?.path}_${shouldRemoveExistingImage}_${widget.category?.svg}',
                    ),
                    selectedImage: selectedImage,
                    networkImageUrl: !shouldRemoveExistingImage
                        ? widget.category?.svg
                        : null,
                    onRemove: isLoading ? null : _removeImage,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
