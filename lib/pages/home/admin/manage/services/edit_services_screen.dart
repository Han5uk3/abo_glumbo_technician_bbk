// ...existing imports...
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/new_text_field.dart';
import 'package:aboglumbo_bbk_panel/common_widget/saving_stack.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/hierarchical_location.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
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
  final TextEditingController nameUrController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController descriptionArController = TextEditingController();
  final TextEditingController descriptionUrController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController onWorkHourPriceController =
      TextEditingController();
  final TextEditingController offWorkHourPriceController =
      TextEditingController();
  final TextEditingController workStartTimeController = TextEditingController();
  final TextEditingController workEndTimeController = TextEditingController();
  final TextEditingController discountPercentageController =
      TextEditingController();

  XFile? selectedImage;
  CategoryModel? selectedCategory;
  List<SelectedCity> selectedCities = [];
  List<Map<String, dynamic>> mapSelectedLocations = [];
  List<int> workingDays = [
    1,
    2,
    3,
    4,
    6,
    7,
  ]; // Default: all days except Friday (5)

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

  String _getDayName(int day, BuildContext context) {
    switch (day) {
      case 1:
        return AppLocalizations.of(context)?.monday ?? 'Monday';
      case 2:
        return AppLocalizations.of(context)?.tuesday ?? 'Tuesday';
      case 3:
        return AppLocalizations.of(context)?.wednesday ?? 'Wednesday';
      case 4:
        return AppLocalizations.of(context)?.thursday ?? 'Thursday';
      case 5:
        return AppLocalizations.of(context)?.friday ?? 'Friday';
      case 6:
        return AppLocalizations.of(context)?.saturday ?? 'Saturday';
      case 7:
        return AppLocalizations.of(context)?.sunday ?? 'Sunday';
      default:
        return '';
    }
  }

  Future<void> _initializeData() async {
    try {
      // Load categories
      await loadCategories();

      // Fill contents after loading
      fillContents();

      // Fetch map-based locations
      await fetchMapLocations();
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
      nameUrController.text = widget.service!.name_ur ?? '';
      descriptionController.text = widget.service!.description ?? '';
      descriptionArController.text = widget.service!.description_ar ?? '';
      descriptionUrController.text = widget.service!.description_ur ?? '';
      priceController.text = widget.service!.price.toString();
      onWorkHourPriceController.text =
          widget.service!.onWorkHourPrice?.toString() ?? '0';
      offWorkHourPriceController.text =
          widget.service!.offWorkHourPrice?.toString() ?? '0';
      workStartTimeController.text = widget.service!.workStartTime ?? '08:00';
      workEndTimeController.text = widget.service!.workEndTime ?? '17:00';
      isActive = widget.service!.isActive;
      discountPercentageController.text =
          widget.service!.discountPercentage?.toString() ?? '0';
      workingDays = List<int>.from(widget.service!.workingDays ?? [1, 2, 3, 4, 6, 7]);

      // Restore hierarchical location data
      // Support both old district-based and new city-based formats
      if (widget.service!.locations?.isNotEmpty == true) {
        selectedCities = [];
        for (final locationJsonStr in widget.service!.locations!) {
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
      onWorkHourPriceController.text = '0';
      offWorkHourPriceController.text = '0';
      discountPercentageController.text = '0';
      workStartTimeController.text = '08:00';
      workEndTimeController.text = '17:00';
    }

    // Set loading to false when data is filled
    setState(() => contentLoading = false);
  }

  Future<void> fetchMapLocations() async {
    if (widget.service != null) {
      try {
        var snapshot = await AppFirestore.locationsCollectionRef
            .where('service_id', isEqualTo: widget.service!.id)
            .get();

        if (snapshot.docs.isNotEmpty) {
          var data = snapshot.docs.first.data() as Map<String, dynamic>;
          setState(() {
            mapSelectedLocations = List<Map<String, dynamic>>.from(
              data['locations'] ?? [],
            );
          });
        }
      } catch (e) {
        log('Error fetching map locations: $e');
      }
    }
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
    if (isSaving) return;

    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);
      try {
        ServiceModel service = ServiceModel(
          name: nameController.text.trim(),
          name_ar: nameArController.text.trim(),
          name_ur: nameUrController.text.trim(),
          description: descriptionController.text.trim(),
          description_ar: descriptionArController.text.trim(),
          description_ur: descriptionUrController.text.trim(),
          price: double.tryParse(priceController.text.trim()),
          onWorkHourPrice: double.tryParse(
            onWorkHourPriceController.text.trim(),
          ),
          offWorkHourPrice: double.tryParse(
            offWorkHourPriceController.text.trim(),
          ),
          workStartTime: workStartTimeController.text.trim(),
          workEndTime: workEndTimeController.text.trim(),
          workingDays: workingDays,
          category: selectedCategory?.id,
          locations: selectedCities.isNotEmpty
              ? selectedCities
                    .map((city) => jsonEncode(city.toJson()))
                    .toList()
                    .cast<String?>()
              : <String?>[],
          isActive: isActive,
          discountPercentage:
              double.tryParse(discountPercentageController.text.trim()) ?? 0,
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
            if (mounted) {
              setState(() {
                final total = event.totalBytes.toDouble();
                imageUploadProgress = total > 0
                    ? event.bytesTransferred.toDouble() / total
                    : 0;
              });
            }
          });

          await uploadTask;
          imageUrl = await ref.getDownloadURL();
        }

        if (imageUrl != null) {
          service = service.copyWith(image: imageUrl);
        }

        if (widget.service == null) {
          final addedDocRef = await AppFirestore.servicesCollectionRef.add(
            service.toJson(),
          );
          await saveMapLocations(addedDocRef.id);
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

          final updateData = service.toEditJson(previous: widget.service!);
          if (updateData.isNotEmpty) {
            await docRef.update(updateData);
          }
          await saveMapLocations(widget.service!.id!);
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

  Future<void> saveMapLocations(String serviceId) async {
    try {
      var snapshot = await AppFirestore.locationsCollectionRef
          .where('service_id', isEqualTo: serviceId)
          .get();

      final dataToSave = {
        'service_id': serviceId,
        'category_id': selectedCategory?.id,
        'locations': mapSelectedLocations
            .map(
              (l) => {
                'polygon': l['polygon'],
                'priority': l['priority'],
                'en_name': l['en_name'],
                'ar_name': l['ar_name'],
                'lat': l['lat'],
                'lng': l['lng'],
              },
            )
            .toList(),
        'updatedAt': Timestamp.now(),
      };

      if (snapshot.docs.isEmpty) {
        if (mapSelectedLocations.isNotEmpty) {
          await AppFirestore.locationsCollectionRef.add(dataToSave);
        }
      } else {
        if (mapSelectedLocations.isEmpty) {
          await snapshot.docs.first.reference.delete();
        } else {
          await snapshot.docs.first.reference.update(dataToSave);
        }
      }
    } catch (e) {
      log('Error saving map locations: $e');
      rethrow;
    }
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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isSaving ? null : saveContent,
          ),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)?.active ?? 'Active'),
                value: isActive,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() {
                    isActive = value;
                  });
                },
              ),
              Divider(),
              SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.category,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<CategoryModel>(
                  dropdownColor: Colors.white,
                  value: selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem<CategoryModel>(
                      value: category,
                      child: Text(
                        category.nameLocalized(
                              languageCode:
                                  AppLocalizations.of(context)?.localeName ??
                                      'en',
                            ) ??
                            category.name ??
                            '',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCategory = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    hintText: AppLocalizations.of(context)?.choose ?? 'choose',
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
              Text(
                AppLocalizations.of(context)!.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewTextField(
                  controller: nameController,
                  hintText: AppLocalizations.of(context)?.name ?? 'Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)?.pleaseEnterAName;
                    }
                    return null;
                  },
                ),
              ),
              Text(
                AppLocalizations.of(context)!.nameArabic,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewTextField(
                  controller: nameArController,
                  hintText:
                      AppLocalizations.of(context)?.nameArabic ??
                      'Name (Arabic)',
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
              Text(
                "Name (Urdu)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewTextField(
                  controller: nameUrController,
                  hintText: 'Name (Urdu)',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name in Urdu';
                    }
                    return null;
                  },
                ),
              ),
              Text(
                AppLocalizations.of(context)!.description,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewTextField(
                  controller: descriptionController,
                  hintText:
                      AppLocalizations.of(context)?.description ??
                      'Description',
                  isDescription: true,
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
              Text(
                AppLocalizations.of(context)!.descriptionArabic,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewTextField(
                  controller: descriptionArController,
                  isDescription: true,
                  hintText:
                      AppLocalizations.of(context)?.descriptionArabic ??
                      'Description (Arabic)',
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
              Text(
                "Description (Urdu)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewTextField(
                  controller: descriptionUrController,
                  isDescription: true,
                  hintText: 'Description (Urdu)',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description in Urdu';
                    }
                    return null;
                  },
                ),
              ),

              Text(
                AppLocalizations.of(context)!.workHoursPricing,
                style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: workStartTimeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          hintText:
                              AppLocalizations.of(context)?.choose ?? 'choose',
                          labelStyle: TextStyle(color: Colors.black),
                          labelText: AppLocalizations.of(
                            context,
                          )?.workStartTime,
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: int.parse(
                                workStartTimeController.text.split(':')[0],
                              ),
                              minute: int.parse(
                                workStartTimeController.text.split(':')[1],
                              ),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              workStartTimeController.text =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: workEndTimeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          hintText:
                              AppLocalizations.of(context)?.choose ?? 'choose',
                          labelStyle: TextStyle(color: Colors.black),
                          labelText: AppLocalizations.of(context)?.workEndTime,
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: int.parse(
                                workEndTimeController.text.split(':')[0],
                              ),
                              minute: int.parse(
                                workEndTimeController.text.split(':')[1],
                              ),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              workEndTimeController.text =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)?.workingDays ?? 'Working Days',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                  final isSelected = workingDays.contains(day);
                  return FilterChip(
                    label: Text(
                      _getDayName(day, context),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          workingDays.add(day);
                        } else {
                          workingDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: NewTextField(
                        keyboardType: TextInputType.number,
                        labelText: AppLocalizations.of(context)!.onWorkPrice,
                        hintText: AppLocalizations.of(context)!.onWorkPrice,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(
                              context,
                            )?.pleaseEnterAnOnWorkPrice;
                          }
                          return null;
                        },
                        controller: onWorkHourPriceController,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: NewTextField(
                        keyboardType: TextInputType.number,
                        controller: offWorkHourPriceController,
                        hintText: AppLocalizations.of(context)!.offWorkPrice,
                        labelText: AppLocalizations.of(context)!.offWorkPrice,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(
                              context,
                            )!.pleaseEnterOffWorkPrice;
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewTextField(
                  keyboardType: TextInputType.number,
                  controller: priceController,
                  hintText: AppLocalizations.of(context)!.generalPrice,
                  labelText: AppLocalizations.of(context)!.generalPrice,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterAGeneralPrice;
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewTextField(
                  keyboardType: TextInputType.number,
                  controller: discountPercentageController,
                  hintText:
                      AppLocalizations.of(context)?.discountPercentage ??
                      'Discount Percentage (%)',
                  labelText:
                      AppLocalizations.of(context)?.discountPercentage ??
                      'Discount Percentage (%)',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )?.pleaseEnterADiscountPercentage;
                    }
                    final perc = double.tryParse(value);
                    if (perc == null || perc < 0 || perc > 100) {
                      return 'Enter a value between 0 and 100';
                    }
                    return null;
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.availableLocations,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (selectedCities.isNotEmpty)
                        Text(
                          "${selectedCities.length} hierarchy selected",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      if (mapSelectedLocations.isNotEmpty)
                        Text(
                          AppLocalizations.of(context)!.locationsSelectedCount(
                            mapSelectedLocations.length,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Hierarchical Location Selector Field
              SizedBox(
                height: 50,
                child: eButton(
                  onPressed: () async {
                    final List<Map<String, dynamic>>? result =
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationMapPicker(
                              initialLocations: mapSelectedLocations,
                            ),
                          ),
                        );

                    if (result != null) {
                      setState(() {
                        mapSelectedLocations = result;
                      });
                    }
                  },
                  context: context,
                  backgroundColor: AppColors.primary,
                  text: AppLocalizations.of(context)!.chooseLocations,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.image,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Directionality.of(context) == TextDirection.rtl
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: pickImage,
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
                              : widget.service?.image != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.service?.image ?? "",
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 130,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(context)?.pickImage ??
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
            ],
          ),
        ),
      ),
    );
  }
}
