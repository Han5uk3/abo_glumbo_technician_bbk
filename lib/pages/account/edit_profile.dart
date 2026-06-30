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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/geohash_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  String? profileImageUrl;
  bool isLoading = false;
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
  PlatformFile? selectedSponsorWorkPermitFile;
  PlatformFile? selectedChamberOfCommerceFile;
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
                AppLocalizations.of(context)!.selectSource,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Future<void> _pickSponsorWorkPermit() async {
    final source = await _showSourceSelector();
    if (source == null) return;

    try {
      PlatformFile? file;
      if (source == 0) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          file = PlatformFile(
            name: image.name,
            path: image.path,
            size: await File(image.path).length(),
          );
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        );
        if (result != null) file = result.files.first;
      }

      if (file != null) {
        setState(() => selectedSponsorWorkPermitFile = file);
      }
    } catch (e) {
      debugPrint('Error picking sponsor permit: $e');
    }
  }

  Future<void> _pickChamberOfCommerce() async {
    final source = await _showSourceSelector();
    if (source == null) return;

    try {
      PlatformFile? file;
      if (source == 0) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          file = PlatformFile(
            name: image.name,
            path: image.path,
            size: await File(image.path).length(),
          );
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        );
        if (result != null) file = result.files.first;
      }

      if (file != null) {
        setState(() => selectedChamberOfCommerceFile = file);
      }
    } catch (e) {
      debugPrint('Error picking chamber approval: $e');
    }
  }

  void _viewPlatformFile(PlatformFile file) async {
    if (file.path == null) return;
    final ext = file.extension?.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
            body: Center(
              child: InteractiveViewer(child: Image.file(File(file.path!))),
            ),
          ),
        ),
      );
    } else {
      await OpenFilex.open(file.path!);
    }
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
                textColor: Colors.black,
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
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                AppLocalizations.of(context)?.idDocument ?? 'ID Document',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
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
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.cannotOpenFile(file.path ?? '') ??
                    'Cannot open file: ${file.path}',
              ),
            ),
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
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                AppLocalizations.of(context)?.idDocument ?? 'ID Document',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                ),
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
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.cannotOpenFile(file.path ?? '') ??
                    'Cannot open file: ${file.path}',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant EditProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workerData != oldWidget.workerData) {
      fillContent();
    }
  }

  void fillContent() {
    if (widget.workerData != null) {
      // Set text controllers and simple fields (no setState needed)
      profileImageUrl = widget.workerData!.profileUrl;
      nameController.text = widget.workerData!.name ?? '';
      emailController.text = widget.workerData!.email ?? '';
      final phoneStr = widget.workerData!.phone.toString();
      phoneController.text = phoneStr.startsWith('+966') 
          ? "0${phoneStr.substring(4)}" 
          : phoneStr;
      selectedJobRoles = widget.workerData!.jobRoles ?? [];
      selectedCertifications = widget.workerData!.certifications ?? [];

      // Initialize current position from last known location if available
      if (widget.workerData!.lastKnownLocation != null) {
        _currentPosition = Position(
          latitude: widget.workerData!.lastKnownLocation!.latitude,
          longitude: widget.workerData!.lastKnownLocation!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (LocalStore.isCurrentUserAdmin()) {
      setState(() {
        _isFetchingLocation = false;
      });
      return;
    }
    setState(() {
      _isFetchingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw AppLocalizations.of(context)?.locationServicesDisabled ??
            'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw AppLocalizations.of(context)?.locationPermissionDenied ??
              'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw AppLocalizations.of(context)?.locationPermissionDeniedForever ??
            'Location permissions are permanently denied.';
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
          final errorString = e.toString();
          if (e is LocationServiceDisabledException ||
              errorString.contains('Location services are disabled')) {
            _locationError =
                AppLocalizations.of(context)?.locationServicesDisabled ??
                'Location services are disabled.';
            _showLocationSettingsPrompt();
          } else if (e is PermissionDeniedException ||
              errorString.contains('User denied permissions') ||
              errorString.contains('Permission denied')) {
            _locationError =
                AppLocalizations.of(context)?.locationPermissionDenied ??
                'Location permissions are denied';
            _showPermissionSettingsPrompt();
          } else {
            _locationError = errorString;
          }
        });
      }
    }
  }

  void _showLocationSettingsPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)?.locationServicesDisabled ??
              'Location Services Disabled',
        ),
        content: Text(
          AppLocalizations.of(context)?.locationServicesDisabledPleaseEnable ??
              'Please enable location services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              AppLocalizations.of(context)?.openSettings ?? 'Open Settings',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionSettingsPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)?.locationPermissionDenied ??
              'Location Permission Denied',
        ),
        content: Text(
          AppLocalizations.of(context)?.locationPermissionDeniedPleaseGrant ??
              'Please grant location permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              AppLocalizations.of(context)?.openSettings ?? 'Open Settings',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
        // Normalize selected roles to keys if they are names
        selectedJobRoles = selectedJobRoles
            .map((role) => getJobCategoryKey(role))
            .toList();
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
    if (currentLanguage == 'ur') {
      return jobCategories[key]?['ur'] ??
          jobCategories[key]?['ar'] ??
          jobCategories[key]?['en'] ??
          key;
    } else if (currentLanguage == 'ar') {
      return jobCategories[key]?['ar'] ?? jobCategories[key]?['en'] ?? key;
    }
    return jobCategories[key]?['en'] ?? key;
  }

  String getJobCategoryKey(String role) {
    for (var entry in jobCategories.entries) {
      if (entry.key == role ||
          entry.value['en'] == role ||
          entry.value['ar'] == role) {
        return entry.key;
      }
    }
    return role;
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
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tempSelectedJobRoles.length} ${AppLocalizations.of(context)?.selected ?? 'selected'}',
                                    style: TextStyle(
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
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.5,
                                ),
                              ),
                            const SizedBox(height: 8),

                            ...jobCategories.entries.map((entry) {
                              final displayName = currentLanguage == 'ur'
                                  ? (entry.value['ur'] ??
                                        entry.value['ar'] ??
                                        entry.value['en'] ??
                                        '')
                                  : (currentLanguage == 'ar'
                                        ? (entry.value['ar'] ??
                                              entry.value['en'] ??
                                              '')
                                        : (entry.value['en'] ?? ''));
                              final isSelected = tempSelectedJobRoles.contains(
                                entry.key,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelectedJobRoles.remove(
                                            entry.key,
                                          );
                                        } else {
                                          tempSelectedJobRoles.add(entry.key);
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
                                              style: TextStyle(
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
                                  style: TextStyle(
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
            style: TextStyle(
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
        if (mounted) setState(() {});
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        title: Text(
          locale.profileManagement,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
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
                    phone: phoneController.text.startsWith('0') 
                        ? '+966${phoneController.text.substring(1)}'
                        : phoneController.text,
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
            isLoading: false,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 20,
                        bottom: safePadding.bottom + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileImage(),
                          const SizedBox(height: 32),
                          _buildSection(
                            title: locale.personalInformation,
                            icon: Icons.person_outline,
                            children: [
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
                                            child: Text(
                                              locale.update,
                                              style: TextStyle(
                                                color: AppColors.secondary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return locale
                                            .pleaseEnterAValidPhoneNumber;
                                      }
                                      return null;
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      top: 4,
                                    ),
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
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: locale.location,
                            icon: Icons.location_on_outlined,
                            children: [
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
                                      : const Icon(Icons.my_location, size: 18),
                                  label: Text(
                                    _isFetchingLocation
                                        ? 'Fetching...'
                                        : (locale.useCurrentLocation),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Show saved address if available
                              if (widget.workerData?.location != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget
                                                      .workerData
                                                      ?.location
                                                      ?.displayName ??
                                                  locale.locationSaved,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              "${locale.latitudeLabel}: ${widget.workerData!.location!.lat?.toStringAsFixed(4)}, ${locale.longitudeLabel}: ${widget.workerData!.location!.lon?.toStringAsFixed(4)}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (_locationError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _locationError!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: locale.jobRoles,
                            icon: Icons.engineering_outlined,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale.jobRoles,
                                    style: TextStyle(
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(
                                        minHeight: 56,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: selectedJobRoles.isEmpty
                                                ? Text(
                                                    locale.selectJobRoles,
                                                    style: TextStyle(
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
                                                            getJobCategoryKey(
                                                              role,
                                                            ),
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        deleteIcon: const Icon(
                                                          Icons.close,
                                                          size: 16,
                                                        ),
                                                        onDeleted: () {
                                                          setState(() {
                                                            selectedJobRoles
                                                                .remove(role);
                                                          });
                                                        },
                                                        backgroundColor:
                                                            AppColors.secondary
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                        labelStyle: TextStyle(
                                                          color: AppColors
                                                              .secondary,
                                                          fontSize: 12,
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
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          side: BorderSide.none,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
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
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: locale.documents,
                            icon: Icons.file_present_outlined,
                            children: [
                              _buildDocumentUpload(
                                title: '${locale.idDocument} *',
                                isUploaded:
                                    selectedImage != null ||
                                    widget.workerData?.docUrl != null,
                                onUpload: _pickIdImage,
                                buttonLabel:
                                    selectedImage == null &&
                                        widget.workerData?.docUrl == null
                                    ? locale.uploadIdDocument
                                    : locale.changeIdDocument,
                              ),
                              if (selectedImage != null)
                                _buildFileItem(
                                  label: locale.idDocument,
                                  onTap: () => _showFullScreenImage(
                                    selectedImage!,
                                    context,
                                  ),
                                  onRemove: _removeIdImage,
                                )
                              else if (widget.workerData?.residenceIdUrl !=
                                  null)
                                _buildFileItem(
                                  label: locale.idDocument,
                                  onTap: () async {
                                    final url = Uri.parse(
                                      widget.workerData!.residenceIdUrl!,
                                    );
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                ),
                              const SizedBox(height: 20),
                              _buildDocumentUpload(
                                title: '${locale.sponsorWorkPermit} *',
                                isUploaded:
                                    selectedSponsorWorkPermitFile != null ||
                                    widget.workerData?.sponsorWorkPermitUrl !=
                                        null,
                                onUpload: _pickSponsorWorkPermit,
                                buttonLabel:
                                    selectedSponsorWorkPermitFile == null &&
                                        widget
                                                .workerData
                                                ?.sponsorWorkPermitUrl ==
                                            null
                                    ? "Upload Sponsor Permit"
                                    : "Change Sponsor Permit",
                              ),
                              if (selectedSponsorWorkPermitFile != null)
                                _buildFileItem(
                                  label: selectedSponsorWorkPermitFile!.name,
                                  onTap: () => _viewPlatformFile(
                                    selectedSponsorWorkPermitFile!,
                                  ),
                                  onRemove: () => setState(
                                    () => selectedSponsorWorkPermitFile = null,
                                  ),
                                )
                              else if (widget
                                      .workerData
                                      ?.sponsorWorkPermitUrl !=
                                  null)
                                _buildFileItem(
                                  label: locale.sponsorWorkPermit,
                                  onTap: () async {
                                    final url = Uri.parse(
                                      widget.workerData!.sponsorWorkPermitUrl!,
                                    );
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                ),
                              const SizedBox(height: 20),
                              _buildDocumentUpload(
                                title: '${locale.chamberOfCommerceApproval} *',
                                isUploaded:
                                    selectedChamberOfCommerceFile != null ||
                                    widget
                                            .workerData
                                            ?.chamberOfCommerceApprovalUrl !=
                                        null,
                                onUpload: _pickChamberOfCommerce,
                                buttonLabel:
                                    selectedChamberOfCommerceFile == null &&
                                        widget
                                                .workerData
                                                ?.chamberOfCommerceApprovalUrl ==
                                            null
                                    ? "Upload Chamber Approval"
                                    : "Change Chamber Approval",
                              ),
                              if (selectedChamberOfCommerceFile != null)
                                _buildFileItem(
                                  label: selectedChamberOfCommerceFile!.name,
                                  onTap: () => _viewPlatformFile(
                                    selectedChamberOfCommerceFile!,
                                  ),
                                  onRemove: () => setState(
                                    () => selectedChamberOfCommerceFile = null,
                                  ),
                                )
                              else if (widget
                                      .workerData
                                      ?.chamberOfCommerceApprovalUrl !=
                                  null)
                                _buildFileItem(
                                  label: locale.chamberOfCommerceApproval,
                                  onTap: () async {
                                    final url = Uri.parse(
                                      widget
                                          .workerData!
                                          .chamberOfCommerceApprovalUrl!,
                                    );
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                ),
                              const SizedBox(height: 20),
                              _buildDocumentUpload(
                                title:
                                    '${locale.certifications} (${locale.optional})',
                                isUploaded:
                                    certifications.isNotEmpty ||
                                    (widget.workerData?.certifications !=
                                            null &&
                                        widget
                                            .workerData!
                                            .certifications!
                                            .isNotEmpty),
                                onUpload: _pickCertifications,
                                buttonLabel: locale.uploadCertifications,
                                icon: Icons.attach_file,
                              ),
                              if (certifications.isNotEmpty)
                                ...certifications.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  PlatformFile file = entry.value;
                                  return _buildFileItem(
                                    label: file.name,
                                    onTap: () => _viewCertification(file),
                                    onRemove: () => _removeCertification(index),
                                  );
                                }),
                              if (widget.workerData!.certifications != null &&
                                  widget.workerData!.certifications!.isNotEmpty)
                                ...widget.workerData!.certifications!
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      int index = entry.key;
                                      String certUrl = entry.value;
                                      return _buildFileItem(
                                        label: 'Certificate ${index + 1}',
                                        onTap: () => _viewCertificate(
                                          certUrl,
                                          'Certificate ${index + 1}',
                                        ),
                                        onRemove: () async {
                                          final confirm =
                                              await _showDeleteConfirmation();
                                          if (confirm) {
                                            setState(() {
                                              widget.workerData!.certifications!
                                                  .removeAt(index);
                                            });
                                          }
                                        },
                                      );
                                    }),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(state, locale),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: selectedProfileImage != null
                  ? Image.file(
                      File(selectedProfileImage!.path),
                      fit: BoxFit.cover,
                    )
                  : profileImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: profileImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: Loader(size: 20, color: AppColors.primary),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey,
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.person,
                        size: 65,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => pickImage(true),
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required bool isUploaded,
    required VoidCallback onUpload,
    required String buttonLabel,
    IconData icon = Icons.upload_file,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onUpload,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUploaded ? Colors.green.shade300 : AppColors.primary,
                style: BorderStyle.solid,
              ),
              color: isUploaded
                  ? Colors.green.withOpacity(0.05)
                  : AppColors.primary.withOpacity(0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUploaded ? Icons.check_circle_outline : icon,
                  color: isUploaded ? Colors.green : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  buttonLabel,
                  style: TextStyle(
                    color: isUploaded ? Colors.green : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem({
    required String label,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
              if (onRemove != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(AccountState state, AppLocalizations locale) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (selectedJobRoles.isEmpty) {
                _showSnackBar(
                  locale.pleaseSelectAtLeastOneJobRole,
                  backgroundColor: AppColors.red,
                );
                return;
              }

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
                    lastKnownLocation: _currentPosition != null
                        ? GeoPoint(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : widget.workerData?.lastKnownLocation,
                    geohash: _currentPosition != null
                        ? GeohashHelper.encode(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : widget.workerData?.geohash,
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
                    liveLocation: _currentPosition != null
                        ? LiveLocation(
                            latitude: _currentPosition!.latitude,
                            longitude: _currentPosition!.longitude,
                          )
                        : widget.workerData?.liveLocation,
                    certifications: widget.workerData!.certifications,
                    residenceIdUrl: widget.workerData?.residenceIdUrl,
                    sponsorWorkPermitUrl:
                        widget.workerData?.sponsorWorkPermitUrl,
                    chamberOfCommerceApprovalUrl:
                        widget.workerData?.chamberOfCommerceApprovalUrl,
                  ),
                  selectedIqamaImage: selectedImage,
                  selectedProfileImage: selectedProfileImage,
                  newCertifications: certifications,
                  selectedSponsorWorkPermitFile: selectedSponsorWorkPermitFile,
                  selectedChamberOfCommerceFile: selectedChamberOfCommerceFile,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: state is UpdateProfileLoading
              ? Loader(color: Colors.white, size: 24)
              : Text(
                  locale.update,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
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
