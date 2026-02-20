// ...existing imports...
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/hierarchical_location_selector.dart';
import 'package:aboglumbo_bbk_panel/common_widget/saving_stack.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/hierarchical_location.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../common_widget/map_picker_page.dart';
import '/models/categories.dart';
import '/models/service.dart';

class AddServicesDevPage extends StatefulWidget {
  const AddServicesDevPage({super.key, this.service});
  final ServiceModel? service;

  @override
  State<AddServicesDevPage> createState() => _AddServicesDevPageState();
}

class _AddServicesDevPageState extends State<AddServicesDevPage> {
  /// Call this after deleting a service to remove it from all highlighted services

  final _formKey = GlobalKey<FormState>();

  bool contentLoading = true;
  List<CategoryModel> categories = [];
  bool isSaving = false;
  double? imageUploadProgress;

  bool isActive = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameArController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController descriptionArController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  XFile? selectedImage;
  CategoryModel? selectedCategory;
  List<SelectedCity> selectedCities = [];

  final arabicFullRegex = RegExp(r'''^[\u0600-\u06FF
       \u0750-\u077F
       \u08A0-\u08FF
       \uFB50-\uFDFF
       \uFE70-\uFEFF
       \u0660-\u0669
       \u06F0-\u06F9
       \u200C-\u200F
       \s\n\r\d
       \.\,\!\?\،\؛\؟\:\-\(\)\[\]\"\'\\u061F]+$''', multiLine: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      // Load categories
      await loadCategories();

      // Fill contents after loading
      fillContents();
    } catch (e) {
      log('Error initializing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadData ??
                  'Failed to load data',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> loadCategories() async {
    try {
      var response = await AppFirestore.categoriesCollectionRef
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        categories = response.docs.map((e) {
          return CategoryModel.fromQuerySnapshot(e);
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadCategories ??
                  'Failed to load categories',
            ),
            action: SnackBarAction(
              label: AppLocalizations.of(context)?.retry ?? 'Retry',
              onPressed: loadCategories,
            ),
          ),
        );
      }
      rethrow;
    }
  }

  void fillContents() {
    if (widget.service != null) {
      nameController.text = widget.service!.name ?? '';
      nameArController.text = widget.service!.name_ar ?? '';
      descriptionController.text = widget.service!.description ?? '';
      descriptionArController.text = widget.service!.description_ar ?? '';
      priceController.text = widget.service!.price.toString();
      isActive = widget.service!.isActive;

      // Restore hierarchical location data
      // Support both old district-based and new city-based formats
      if (widget.service!.locations.isNotEmpty) {
        selectedCities = [];
        for (final locationJsonStr in widget.service!.locations) {
          if (locationJsonStr == null || locationJsonStr.isEmpty) continue;
          try {
            final locationMap =
                jsonDecode(locationJsonStr) as Map<String, dynamic>;

            // Check if it's old format (has districtId) or new format (city only)
            if (locationMap.containsKey('districtId')) {
              // Old format - convert to city-based (avoid duplicates)
              final oldDistrict = SelectedDistrict.fromJson(locationMap);
              final newCity = oldDistrict.toSelectedCity();
              if (!selectedCities.any((c) => c.cityId == newCity.cityId)) {
                selectedCities.add(newCity);
              }
            } else {
              // New format - use directly
              selectedCities.add(SelectedCity.fromJson(locationMap));
            }
          } catch (e) {
            log('Error parsing location: $e');
          }
        }
      } else {
        selectedCities = [];
      }

      try {
        selectedCategory = categories.firstWhere(
          (element) => element.id == widget.service?.category,
        );
      } catch (e) {
        log('Error: $e');
      }

      setState(() {});
    }
    if (widget.service == null) {
      priceController.text = '0';
    }

    // Set loading to false when data is filled
    setState(() => contentLoading = false);
  }

  Future pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => selectedImage = image);
      await cropImage();
    }
  }

  Future cropImage() async {
    CroppedFile? res = await ImageCropper().cropImage(
      sourcePath: selectedImage!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
        ),
      ],
    );

    if (res != null) {
      setState(() => selectedImage = XFile(res.path));
    } else {
      final bool? shouldKeepImage = await showCropConfirmDialog(context);

      if (shouldKeepImage != true) {
        setState(() => selectedImage = null);
      }
      // If shouldKeepImage is true, we keep the original selectedImage as is
    }
  }

  Future saveContent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);
      try {
        ServiceModel service = ServiceModel(
          name: nameController.text.trim(),
          name_ar: nameArController.text.trim(),
          description: descriptionController.text.trim(),
          description_ar: descriptionArController.text.trim(),
          price: double.tryParse(priceController.text.trim()),
          category: selectedCategory?.id,
          locations: selectedCities.isNotEmpty
              ? selectedCities
                    .map((city) => jsonEncode(city.toJson()))
                    .toList()
                    .cast<String?>()
              : <String?>[],
          isActive: isActive,
          updatedAt: Timestamp.now(),
        );
        if (widget.service != null) {
          service = service.copyWith(
            id: widget.service!.id,
            locations: selectedCities.isNotEmpty
                ? selectedCities
                      .map((city) => jsonEncode(city.toJson()))
                      .toList()
                      .cast<String?>()
                : <String?>[],
          );
        } else {
          service.createdAt = Timestamp.now();
        }

        String? imageUrl;

        if (selectedImage != null) {
          // upload image and get the url
          final ref = AppFireStorage.servicesStorageRef.child(
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
          final uploadTask = ref.putFile(File(selectedImage!.path));
          uploadTask.snapshotEvents.listen((event) {
            setState(() {
              imageUploadProgress =
                  event.bytesTransferred.toDouble() /
                  event.totalBytes.toDouble();
            });
          });

          await uploadTask;
          imageUrl = await ref.getDownloadURL();
        }

        if (imageUrl != null) {
          service = service.copyWith(image: imageUrl);
        }

        if (widget.service == null) {
          await AppFirestore.servicesCollectionRef.add(service.toJson());
        } else {
          // Check if the document exists before updating
          final docRef = AppFirestore.servicesCollectionRef.doc(
            widget.service!.id,
          );
          final docSnapshot = await docRef.get();

          if (!docSnapshot.exists) {
            throw Exception(
              'Service document not found. Please refresh and try again.',
            );
          }

          await docRef.update(service.toEditJson(previous: widget.service!));
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.service == null
                    ? AppLocalizations.of(context)!.serviceAddedSuccessfully
                    : AppLocalizations.of(context)!.serviceUpdatedSuccessfully,
              ),
            ),
          );
        }
      } catch (e) {
        log('Error saving service: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.service == null
                    ? AppLocalizations.of(context)?.failedToCreateService ??
                          'Failed to create service'
                    : AppLocalizations.of(context)?.failedToUpdateService ??
                          'Failed to update service',
              ),
              action: SnackBarAction(
                label: AppLocalizations.of(context)?.retry ?? 'Retry',
                onPressed: saveContent,
              ),
            ),
          );
        }
      }
    }
    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    // final isArabic = AppLocalizations.of(context)?.localeName == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.service == null
              ? AppLocalizations.of(context)!.addService
              : AppLocalizations.of(context)!.editService,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: saveContent),
        ],
      ),
      body: SavingStackWidget(
        isSaving: isSaving,
        isLoading: contentLoading,
        progress: imageUploadProgress,
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
                    } else if (!arabicFullRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.textMustBeInArabic;
                    }

                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.description ??
                        'Description',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterADescription;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: descriptionArController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.descriptionArabic ??
                        'Description (Arabic)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterDescriptionInArabic;
                    } else if (!arabicFullRegex.hasMatch(value)) {
                      return AppLocalizations.of(context)!.textMustBeInArabic;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.inspectionFee ?? 'Price',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value == '') {
                      priceController.text = '0';
                      return null;
                    }
                    return null;
                  },
                ),
              ),

              // Hierarchical Location Selector Field
              InkWell(
                onTap: (){
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context)=>
                      LocationMapPicker(

                      )
                      ));
                },
                  child: Container(
                    child:Text("Select Locations")
                  )),
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 16),
              //   child: HierarchicalLocationSelector(
              //     selectedCities: selectedCities,
              //     onChanged: (cities) {
              //
              //       setState(() {
              //         selectedCities = cities;
              //       });
              //     },
              //     // Location selection is now optional
              //     validator: null,
              //   ),
              // ),
// Text(selectedCities.length.toString()),

              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FilledButton(
                  onPressed: pickImage,
                  child: Text(
                    AppLocalizations.of(context)?.pickImage ?? 'Pick Image',
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: selectedImage != null
                        ? Image.file(
                            File(selectedImage!.path),
                            height: 130,
                            width: 130,
                          )
                        : widget.service?.image != null
                        ? CachedNetworkImage(
                            imageUrl: widget.service?.image ?? "",
                            height: 130,
                            width: 130,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<CategoryModel>(
                  value: selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem<CategoryModel>(
                      value: category,
                      child: Text(
                        AppLocalizations.of(context)?.localeName == 'ar'
                            ? category.name_ar ?? category.name ?? ''
                            : category.name ?? '',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCategory = value);
                  },
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.category ?? 'Category',
                  ),
                  validator: (value) {
                    if (value == null) {
                      return AppLocalizations.of(
                        context,
                      )?.pleaseSelectACategory;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SwitchListTile(
                  title: Text(AppLocalizations.of(context)?.active ?? 'Active'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
