import 'dart:io';

import 'package:aboglumbo_bbk_panel/common_widget/crop_confirm_dialog.dart';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/saving_stack.dart';
import 'package:aboglumbo_bbk_panel/common_widget/snackbar.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/bloc/login_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/login/otp.dart';
import 'package:aboglumbo_bbk_panel/services/auth_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class EditProfile extends StatefulWidget {
  final UserModel? workerData;
  const EditProfile({super.key, this.workerData});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  String? profileImageUrl = null;
  bool isLoading = false;
  bool isPhoneNumberUpdated = false;
  bool _isUpdatingPhone = false;
  int? _resendToken;

  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  Position? _currentPosition;
  Placemark? _placeMark;
  bool _isFetchingLocation = false;
  String? _locationError;

  XFile? selectedImage;
  XFile? selectedProfileImage;
  List<String> selectedCertifications = [];
  List<PlatformFile> certifications = [];

  // Job categories and selected job roles
  Map<String, Map<String, String>> jobCategories = {};
  List<String> selectedJobRoles = [];
  bool isCategoriesLoading = true;

  // Helper getter to check if all data is loaded
  bool get isDataLoading => isCategoriesLoading;

  Future<int?> _showSourceSelector() async {
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                AppLocalizations.of(context)?.selectSource ?? 'Select Source',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)?.camera ?? 'Camera'),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(AppLocalizations.of(context)?.files ?? 'Files'),
              onTap: () => Navigator.pop(context, 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIdImage() async {
    final source = await _showSourceSelector();
    if (source == null) return;

    try {
      XFile? image;
      bool isImage = true;

      if (source == 0) {
        // Camera
        final ImagePicker picker = ImagePicker();
        image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
      } else {
        // Files
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          if (file.path != null) {
            image = XFile(file.path!);
            final ext = file.extension?.toLowerCase();
            isImage = ['jpg', 'jpeg', 'png'].contains(ext);
          }
        }
      }

      if (image != null) {
        if (isImage) {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            compressQuality: 80,
            maxWidth: 2048,
            maxHeight: 2048,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle:
                    AppLocalizations.of(context)?.cropDocument ??
                    'Crop Document',
                toolbarColor: AppColors.primary,
                toolbarWidgetColor: Colors.white,
                statusBarColor: AppColors.primary,
              ),
              IOSUiSettings(
                title:
                    AppLocalizations.of(context)?.cropDocument ??
                    'Crop Document',
              ),
            ],
          );

          if (croppedFile != null) {
            setState(() {
              selectedImage = XFile(croppedFile.path);
            });
          }
        } else {
          setState(() {
            selectedImage = image;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking ID image: $e');
      }
    }
  }

  Future<void> _pickCertifications() async {
    final source = await _showSourceSelector();
    if (source == null) return;

    try {
      if (source == 0) {
        // Camera
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (image != null) {
          final file = File(image.path);
          final size = await file.length();

          // Validate size
          if (size > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${image.name} ${AppLocalizations.of(context)?.fileTooLarge ?? 'is too large (max 5MB)'}',
                  ),
                ),
              );
            }
            return;
          }

          setState(() {
            certifications.add(
              PlatformFile(name: image.name, path: image.path, size: size),
            );
          });
        }
      } else {
        // Files
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
          allowMultiple: true,
        );

        if (result != null) {
          // Validate file sizes
          for (var file in result.files) {
            if (file.size > 5 * 1024 * 1024) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${file.name} ${AppLocalizations.of(context)?.fileTooLarge ?? 'is too large (max 5MB)'}',
                    ),
                  ),
                );
              }
              return;
            }
          }

          setState(() {
            certifications.addAll(result.files);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking certifications: $e');
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.bgWhite,
            actionsAlignment: MainAxisAlignment.start,
            title: Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
            content: Text(
              AppLocalizations.of(context)?.areYouSureYouWantToDeleteThisFile ??
                  'Are you sure you want to remove this file?',
            ),
            actions: [
              eButton(
                onPressed: () => Navigator.pop(context, false),
                text: AppLocalizations.of(context)?.no ?? 'No',
                context: context,
                textColor: Colors.white,
                backgroundColor: AppColors.bgWhite,
              ),
              eButton(
                onPressed: () => Navigator.pop(context, true),
                text: AppLocalizations.of(context)?.remove ?? 'Remove',
                context: context,
                textColor: Colors.white,
                backgroundColor: Colors.red,
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _removeIdImage() async {
    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      setState(() {
        selectedImage = null;
      });
    }
  }

  Future<void> _removeCertification(int index) async {
    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      setState(() {
        certifications.removeAt(index);
      });
    }
  }

  void _showFullScreenImage(XFile file, BuildContext context) async {
    final ext = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                AppLocalizations.of(context)?.idDocument ?? 'ID Document',
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(File(file.path)),
              ),
            ),
          ),
        ),
      );
    } else {
      // For non-image files, try to open with system viewer
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open file: ${file.path}')),
          );
        }
      }
    }
  }

  void _viewCertification(PlatformFile file) async {
    if (file.path == null) return;
    final ext = file.extension?.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                AppLocalizations.of(context)?.idDocument ?? 'ID Document',
                style: GoogleFonts.dmSans(color: Colors.white),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(File(file.path!)),
              ),
            ),
          ),
        ),
      );
    } else {
      // For non-image files, try to open with system viewer
      final result = await OpenFilex.open(file.path!);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open file: ${file.path}')),
          );
        }
      }
    }
  }

  void fillContent() {
    if (widget.workerData != null) {
      // Set text controllers and simple fields (no setState needed)
      profileImageUrl = widget.workerData!.profileUrl;
      nameController.text = widget.workerData!.name ?? '';
      emailController.text = widget.workerData!.email ?? '';
      phoneController.text =
          "0${widget.workerData!.phone.toString().substring(4)}";
      selectedJobRoles = widget.workerData!.jobRoles ?? [];
      selectedCertifications = widget.workerData!.certifications ?? [];
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _placeMark = placemarks.isNotEmpty ? placemarks.first : null;
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
          _locationError = e.toString();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadJobCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        fillContent();
      }
    });
  }

  /// Load job categories from Firebase
  Future<void> _loadJobCategories() async {
    setState(() {
      isCategoriesLoading = true;
    });

    try {
      final categories = await AppServices.fetchJobCategories();
      setState(() {
        jobCategories = categories;
        isCategoriesLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        isCategoriesLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadCategories ??
                  'Failed to load job categories',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String getJobCategoryDisplayName(String key) {
    final currentLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
    final isArabic = currentLanguage == 'ar';
    return jobCategories[key]?[isArabic ? 'ar' : 'en'] ?? key;
  }

  String getJobCategoryKey(String displayName) {
    final currentLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
    final isArabic = currentLanguage == 'ar';

    for (var entry in jobCategories.entries) {
      if (entry.value[isArabic ? 'ar' : 'en'] == displayName) {
        return entry.key;
      }
    }
    return displayName;
  }

  void selectJobRolesBottomSheet() {
    List<String> tempSelectedJobRoles = List.from(selectedJobRoles);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentLanguage =
                AppLocalizations.of(context)?.localeName ?? 'en';
            final isArabic = currentLanguage == 'ar';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Drag handle
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.selectJobRoles ??
                                        'Select Job Roles',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tempSelectedJobRoles.length} ${AppLocalizations.of(context)?.selected ?? 'selected'}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selected roles preview (chips)

                      // Available roles list
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (jobCategories.isNotEmpty)
                              Text(
                                AppLocalizations.of(context)?.availableRoles ??
                                    'Available Roles',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            const SizedBox(height: 8),

                            ...jobCategories.entries.map((entry) {
                              final displayName =
                                  entry.value[isArabic ? 'ar' : 'en'] ??
                                  entry.value['en']!;
                              final isSelected =
                                  tempSelectedJobRoles.contains(displayName) ||
                                  tempSelectedJobRoles.contains(
                                    entry.value['en'],
                                  ) ||
                                  tempSelectedJobRoles.contains(
                                    entry.value['ar'],
                                  );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelectedJobRoles.removeWhere(
                                            (role) =>
                                                role == displayName ||
                                                role == entry.value['en'] ||
                                                role == entry.value['ar'],
                                          );
                                        } else {
                                          tempSelectedJobRoles.removeWhere(
                                            (role) =>
                                                role == displayName ||
                                                role == entry.value['en'] ||
                                                role == entry.value['ar'],
                                          );
                                          tempSelectedJobRoles.add(displayName);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.secondary.withOpacity(
                                                0.08,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.secondary.withOpacity(
                                                  0.3,
                                                )
                                              : Colors.grey[200]!,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Checkbox
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.secondary
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.secondary
                                                    : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    size: 16,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),

                                          // Role name
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 15,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                color: isSelected
                                                    ? AppColors.secondary
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Bottom action button
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: tempSelectedJobRoles.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      selectedJobRoles.clear();
                                      selectedJobRoles.addAll(
                                        tempSelectedJobRoles,
                                      );
                                    });
                                    Navigator.pop(context);
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)?.apply ?? 'Apply'} (${tempSelectedJobRoles.length})',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> pickImage(bool isProfile) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: isProfile ? 800 : 1200,
        maxHeight: isProfile ? 800 : 1200,
      );

      if (image != null) {
        final file = File(image.path);

        if (!await file.exists()) {
          return;
        }

        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.imageIsTooLargePleaseSelectAnImageSmallerThan5MB,
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        debugPrint('Selected image size: $fileSize bytes');

        if (isProfile) {
          setState(() => selectedProfileImage = image);
          await cropImage(true);
        } else {
          setState(() => selectedImage = image);
          await cropImage(false);
        }
      }
    } catch (e) {
      if (mounted) {
        // Handle error gracefully
      }
    }
  }

  Future<void> cropImage(bool isProfile) async {
    try {
      final sourcePath = isProfile
          ? selectedProfileImage!.path
          : selectedImage!.path;

      CroppedFile? res = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: isProfile
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle:
                AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: isProfile,
          ),
          IOSUiSettings(
            title: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
            aspectRatioLockEnabled: isProfile,
          ),
        ],
      );

      if (res != null) {
        if (isProfile) {
          setState(() => selectedProfileImage = XFile(res.path));
        } else {
          setState(() => selectedImage = XFile(res.path));
        }
      } else {
        final bool? shouldKeepImage = await showCropConfirmDialog(context);

        if (shouldKeepImage != true) {
          if (isProfile) {
            setState(() => selectedProfileImage = null);
          } else {
            setState(() => selectedImage = null);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.error}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return false;
    if (!phoneNumber.startsWith('05')) return false;
    if (phoneNumber.length != 10) return false;
    return true;
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.dmSans(
              color: backgroundColor == AppColors.yellow
                  ? Colors.grey.shade800
                  : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: backgroundColor ?? AppColors.yellow,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updatePhoneNumber() async {
    // Prevent multiple clicks
    if (_isUpdatingPhone) return;

    if (!_isValidPhoneNumber(phoneController.text)) {
      _showSnackBar(
        AppLocalizations.of(context)?.pleaseEnterAValidPhoneNumber ??
            'Invalid number',
        backgroundColor: AppColors.red,
      );
      return;
    }

    if (phoneController.text != widget.workerData?.phone) {
      if (mounted) {
        setState(() {
          isLoading = true;
          _isUpdatingPhone = true;
        });
      }

      bool isNumberAlreadyExists =
          await AppServices.checkCustomerPhoneNumberAlredyExist(
            phoneController.text,
            excludeUid: widget.workerData?.uid,
          );

      if (isNumberAlreadyExists) {
        if (mounted) {
          setState(() {
            isLoading = false;
            _isUpdatingPhone = false;
          });
        }
        _showSnackBar(
          AppLocalizations.of(context)?.phoneNumberAlreadyExists ?? '',
          backgroundColor: AppColors.yellow,
        );
        return;
      }

      if (phoneController.text.startsWith('05')) {
        if (mounted) setState(() => isPhoneNumberUpdated = true);
        final formattedPhone = '+966${phoneController.text.substring(1)}';

        await AuthServices().sendOTP(
          context,
          phoneNumber: formattedPhone,
          forceResendingToken: _resendToken,
          onCodeSent: (String verificationId, {int? resendToken}) {
            if (mounted) {
              setState(() {
                _resendToken = resendToken;
                isLoading = false;
                _isUpdatingPhone = false;
              });
            }
            showSnackBar(
              AppLocalizations.of(context)?.sendingOTP ?? 'Sending OTP...',
              backgroundColor: AppColors.primary,
              context,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpPage(
                  phoneNumber: phoneController.text,
                  verificationId: verificationId,
                  isFromProfile: true,
                ),
              ),
            );
          },
          onError: (FirebaseAuthException e) {
            if (mounted) {
              setState(() {
                isLoading = false;
                _isUpdatingPhone = false;
              });
            }
            String errorMessage;
            switch (e.code) {
              case 'too-many-requests':
                errorMessage =
                    AppLocalizations.of(context)?.tooManyAttempts ??
                    'Too many attempts. Please wait and try again.';
                break;
              case 'invalid-phone-number':
                errorMessage =
                    AppLocalizations.of(
                      context,
                    )?.pleaseEnterAValidPhoneNumber ??
                    'Please enter a valid phone number';
                break;
              default:
                errorMessage =
                    e.message ??
                    AppLocalizations.of(context)?.somethingWentWrongTryAgain ??
                    'Something went wrong. Please try again.';
            }
            _showSnackBar(errorMessage, backgroundColor: AppColors.red);
          },
        );
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
          _isUpdatingPhone = false;
        });
      }
      _showSnackBar(
        AppLocalizations.of(context)?.phoneNumberAlreadyUpdated ?? '',
        backgroundColor: AppColors.yellow,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: Text(locale.profileManagement),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is UpdateProfileSuccess) {
            if (state.isUpdated) {
              final updatedUser =
                  state.updatedUser ??
                  UserModel(
                    uid: widget.workerData?.uid ?? '',
                    role: 'technician',
                    name: nameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    location: _currentPosition != null
                        ? LocationModel.fromGPS(
                            lat: _currentPosition!.latitude,
                            lon: _currentPosition!.longitude,
                            placemark: _placeMark,
                          )
                        : widget.workerData?.location,
                    jobRoles: selectedJobRoles,
                    profileUrl: profileImageUrl,
                    lanCode: widget.workerData?.lanCode,
                    country: widget.workerData?.country,
                    createdAt: widget.workerData?.createdAt,
                    updatedAt: widget.workerData?.updatedAt,
                    isAdmin: widget.workerData?.isAdmin,
                    isVerified: widget.workerData?.isVerified,
                    docUrl: widget.workerData?.docUrl,
                    fcmToken: widget.workerData?.fcmToken,
                    liveLocation: widget.workerData?.liveLocation,
                  );

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  LocalStore.storeUserData(updatedUser);
                  context.read<LoginBloc>().add(RefreshUserData());

                  Navigator.pop(context, updatedUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(locale.profileUpdatedSuccessfully)),
                  );
                }
              });
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(locale.failedToUpdateProfile)),
                  );
                }
              });
            }
          }
        },
        builder: (context, state) {
          // Show loader while initial data is loading
          if (isDataLoading) {
            return Center(child: SizedBox(height: 24, child: Loader()));
          }

          return SavingStackWidget(
            isSaving: state is UpdateProfileLoading,
            isLoading: state is UpdateProfileLoading,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: safePadding.bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.grey2.withOpacity(0.3),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: selectedProfileImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      File(selectedProfileImage!.path),
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    ),
                                  )
                                : profileImageUrl != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: profileImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      placeholder: (context, url) => Center(
                                        child: Loader(
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => pickImage(true),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormWidget(
                      controller: nameController,
                      label: locale.yourName,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return locale.nameIsRequired;
                        } else if (value.trim().length < 3) {
                          return locale.enterAValidName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormWidget(
                      controller: emailController,
                      label: locale.emailAddress,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      readOnly: false,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!emailRegex.hasMatch(value)) {
                            return locale.pleaseEnterValidEmail;
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormWidget(
                          controller: phoneController,
                          label: locale.phoneNumber,
                          keyboardType: TextInputType.phone,
                          enabled: !_isUpdatingPhone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*'),
                            ),
                            LengthLimitingTextInputFormatter(10),
                          ],
                          suffixIcon: _isUpdatingPhone
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : TextButton(
                                  onPressed: _isUpdatingPhone
                                      ? null
                                      : _updatePhoneNumber,
                                  child: Text(locale.update),
                                ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return locale.pleaseEnterAValidPhoneNumber;
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text(
                            locale.phoneNumberFormatHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    // Location Fetch Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.location,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isFetchingLocation
                                  ? null
                                  : _getCurrentLocation,
                              icon: _isFetchingLocation
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.my_location),
                              label: Text(
                                _isFetchingLocation
                                    ? 'Fetching...'
                                    : (AppLocalizations.of(context)
                                            ?.useCurrentLocation ??
                                        'Use Current Location'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          if (_currentPosition != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_placeMark != null)
                                          Text(
                                            "${_placeMark!.locality ?? ''}, ${_placeMark!.administrativeArea ?? ''}",
                                            style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green.shade900,
                                            ),
                                          ),
                                        Text(
                                          "Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}",
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (widget.workerData?.location != null) ...[
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final loc = widget.workerData?.location;
                                final locationText =
                                    loc?.displayName ?? 'Location saved';
                                final lat = loc?.lat;
                                final lon = loc?.lon;
                                final coordText = (lat != null && lon != null)
                                    ? 'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}'
                                    : '';

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          AppColors.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              locationText,
                                              style: GoogleFonts.dmSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            if (coordText.isNotEmpty)
                                              Text(
                                                coordText,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 11,
                                                  color: AppColors.primary
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],

                          if (_locationError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _locationError!,
                              style: GoogleFonts.dmSans(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Replace TextFormWidget with custom job roles container
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.jobRoles,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: isCategoriesLoading
                              ? null
                              : selectJobRolesBottomSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 56),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.grey2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: selectedJobRoles.isEmpty
                                      ? Text(
                                          locale.selectJobRoles,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: selectedJobRoles.map((
                                            role,
                                          ) {
                                            return Chip(
                                              label: Text(
                                                getJobCategoryDisplayName(
                                                  getJobCategoryKey(role),
                                                ),
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              deleteIcon: const Icon(
                                                Icons.close,
                                                size: 16,
                                              ),
                                              onDeleted: () {
                                                setState(() {
                                                  selectedJobRoles.remove(role);
                                                });
                                              },
                                              backgroundColor: AppColors
                                                  .secondary
                                                  .withOpacity(0.1),
                                              labelStyle: TextStyle(
                                                color: AppColors.secondary,
                                              ),
                                              deleteIconColor:
                                                  AppColors.secondary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            );
                                          }).toList(),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: selectedJobRoles.isEmpty
                                      ? Colors.grey
                                      : AppColors.secondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ID Document Upload
                    Text(
                      '${locale.idDocument} *',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickIdImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        selectedImage == null &&
                                widget.workerData?.docUrl == null
                            ? locale.uploadIdDocument
                            : locale.changeIdDocument,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            selectedImage != null ||
                                widget.workerData?.docUrl != null
                            ? Colors.green
                            : AppColors.primary,
                      ),
                    ),

                    if (selectedImage != null)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: GestureDetector(
                          onTap: () =>
                              _showFullScreenImage(selectedImage!, context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.idDocument,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.open_in_new,
                                  color: Colors.grey.shade700,
                                ),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _removeIdImage(),
                                  child: Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (widget.workerData?.docUrl != null)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              final url = Uri.parse(widget.workerData!.docUrl!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${AppLocalizations.of(context)?.error ?? 'Error'}: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.idDocument,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.open_in_new,
                                  color: Colors.grey.shade700,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Certifications Upload
                    Text(
                      '${AppLocalizations.of(context)?.certifications ?? 'Certifications'} (${AppLocalizations.of(context)?.optional ?? 'Optional'})',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickCertifications,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        AppLocalizations.of(context)?.uploadCertifications ??
                            'Upload Certifications',
                      ),
                    ),

                    // Display newly picked certifications (Local Files)
                    if (certifications.isNotEmpty)
                      ...certifications.asMap().entries.map((entry) {
                        int index = entry.key;
                        PlatformFile file = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: GestureDetector(
                            onTap: () => _viewCertification(file),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade700),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    file.name,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.open_in_new,
                                    color: Colors.grey.shade700,
                                  ),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeCertification(index),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 10),

                    // Display existing certifications (URLs) - with tap to view
                    if (widget.workerData!.certifications != null &&
                        widget.workerData!.certifications!.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.workerData!.certifications!.length,
                        itemBuilder: (context, index) {
                          final certUrl =
                              widget.workerData!.certifications![index];
                          return Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: GestureDetector(
                              onTap: () => _viewCertificate(
                                certUrl,
                                'Certificate ${index + 1}',
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Certificate ${index + 1}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.open_in_new,
                                      color: Colors.grey.shade700,
                                    ),
                                    SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final confirm =
                                            await _showDeleteConfirmation();
                                        if (confirm) {
                                          setState(() {
                                            widget.workerData!.certifications!
                                                .removeAt(index);
                                          });
                                        }
                                      },
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.maxFinite,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            // Location is now GPS-based; no manual validation needed.

                            // Validation for job roles
                            if (selectedJobRoles.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    locale.pleaseSelectAtLeastOneJobRole,
                                  ),
                                ),
                              );
                              return;
                            }

                            // Build unified LocationModel from GPS data
                            final newLocation = _currentPosition != null
                                ? LocationModel.fromGPS(
                                    lat: _currentPosition!.latitude,
                                    lon: _currentPosition!.longitude,
                                    placemark: _placeMark,
                                  )
                                : widget.workerData?.location;

                            context.read<AccountBloc>().add(
                              UpdateProfileEvent(
                                user: UserModel(
                                  role: 'technician',
                                  uid: widget.workerData?.uid ?? '',
                                  name: nameController.text,
                                  email: emailController.text,
                                  phone: phoneController.text,
                                  location: newLocation,
                                  jobRoles: selectedJobRoles,
                                  profileUrl: profileImageUrl,
                                  lanCode: widget.workerData?.lanCode,
                                  country: widget.workerData?.country,
                                  createdAt: widget.workerData?.createdAt,
                                  updatedAt: widget.workerData?.updatedAt,
                                  isAdmin: widget.workerData?.isAdmin,
                                  isVerified: widget.workerData?.isVerified,
                                  docUrl: widget.workerData?.docUrl,
                                  fcmToken: widget.workerData?.fcmToken,
                                 
                                  liveLocation: widget.workerData?.liveLocation,
                                  certifications: widget
                                      .workerData!
                                      .certifications, // Pass existing (modified) certifications
                                ),
                                selectedIqamaImage: selectedImage,
                                selectedProfileImage: selectedProfileImage,
                                newCertifications:
                                    certifications, // Pass new certifications
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: state is UpdateProfileLoading
                            ? Loader(color: Colors.white, size: 20)
                            : Text(
                                locale.update,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _viewCertificate(String url, String fileName) async {
    try {
      final Uri uri = Uri.parse(url);

      // Remove canLaunchUrl check - just try to launch
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) {
        print('Error opening certificate: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotOpenFile),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
