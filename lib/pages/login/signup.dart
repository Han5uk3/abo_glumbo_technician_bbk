import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/common_widget/text_form.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/login/login.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/firestorage.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Signup extends StatefulWidget {
  final String uid;

  const Signup({super.key, required this.uid});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  bool isCreatingAccount = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController =
      TextEditingController(); // ✅ Add email field

  XFile? profileImage;
  XFile? idImage;
  List<PlatformFile> certifications = [];

  Position? _currentPosition;
  Placemark? _placeMark;
  bool _isFetchingLocation = false;
  String? _locationError;

  List<Map<String, dynamic>> jobCategories = [];
  List<String> selectedJobRoles = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    phoneController.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    _loadJobCategories();
    // _loadLocations removed
  }

  // ✅ FIXED: Proper conversion from AppServices return type
  Future<void> _loadJobCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final categoriesMap = await AppServices.fetchJobCategories();

      // Convert Map<String, Map<String, String>> to List<Map<String, dynamic>>
      jobCategories = categoriesMap.entries.map((entry) {
        return <String, dynamic>{
          'id': entry.key,
          'name': entry.value['en'] ?? '',
          'nameAr': entry.value['ar'] ?? '',
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading job categories: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToLoadCategories ??
                  'Failed to load job categories',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingCategories = false);
      }
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

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle:
                  AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: AppLocalizations.of(context)?.cropImage ?? 'Crop Image',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          final fileSize = await File(croppedFile.path).length();
          if (fileSize > 10 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)?.fileTooLarge ??
                        'File is too large (max 20MB)',
                  ),
                ),
              );
            }
            return;
          }

          setState(() {
            profileImage = XFile(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking profile image: $e');
      }
    }
  }

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

  Future<void> _removeIdImage() async {
    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      setState(() {
        idImage = null;
      });
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
              idImage = XFile(croppedFile.path);
            });
          }
        } else {
          setState(() {
            idImage = image;
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

  Future<void> _removeCertification(int index) async {
    final confirm = await _showDeleteConfirmation();
    if (confirm) {
      setState(() {
        certifications.removeAt(index);
      });
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
                backgroundColor: Colors.red,
                context: context,
                onPressed: () => Navigator.pop(context, true),
                text: AppLocalizations.of(context)?.yes ?? 'Yes',
                textColor: Colors.white,
              ),
              const SizedBox(width: 8),
              eButton(
                backgroundColor: Colors.grey,
                context: context,
                onPressed: () => Navigator.pop(context, false),
                text: AppLocalizations.of(context)?.no ?? 'No',
                textColor: Colors.black,
              ),
            ],
          ),
        ) ??
        false;
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
                iconSize: 18,
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                AppLocalizations.of(context)!.idDocument,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
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
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(file.name),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              InteractiveViewer(child: Image.file(File(file.path!))),
            ],
          ),
        ),
      );
    } else {
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

  Future<void> _selectJobRoles() async {
    if (jobCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.noJobCategoriesAvailable ??
                'No job categories available',
          ),
        ),
      );
      return;
    }

    final selectedRoles = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.selectJobRoles ??
                            'Select Job Roles',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, selectedJobRoles),
                        child: Text(
                          AppLocalizations.of(context)?.done ?? 'Done',
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: jobCategories.length,
                      itemBuilder: (context, index) {
                        final category = jobCategories[index];
                        final categoryName =
                            LocalStore.getUserlanguage() == 'ar'
                            ? (category['nameAr'] ?? category['name'])
                            : category['name'];
                        final categoryId = category['id'];

                        final isSelected = selectedJobRoles.contains(
                          categoryId,
                        );

                        return CheckboxListTile(
                          title: Text(categoryName),
                          value: isSelected,
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                selectedJobRoles.add(categoryId);
                              } else {
                                selectedJobRoles.remove(categoryId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedRoles != null) {
      setState(() {
        selectedJobRoles = selectedRoles;
      });
    }
  }

  String _getJobRoleNames() {
    if (selectedJobRoles.isEmpty) return '';

    return selectedJobRoles
        .map((roleId) {
          final category = jobCategories.firstWhere(
            (cat) => cat['id'] == roleId,
            orElse: () => {'name': roleId, 'nameAr': roleId},
          );
          return LocalStore.getUserlanguage() == 'ar'
              ? (category['nameAr'] ?? category['name'])
              : category['name'];
        })
        .join(', ');
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Validate all location fields are selected
    // ✅ Validate location
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fetch your current location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedJobRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectAtLeastOneJobRole ??
                'Please select at least one job role',
          ),
        ),
      );
      return;
    }

    if (idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseUploadIdDocument ??
                'Please upload ID document',
          ),
        ),
      );
      return;
    }

    // ✅ Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.bgWhite,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 24, child: Loader(color: AppColors.primary)),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(dialogContext)?.creatingAccount ??
                      'Creating your account...',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(dialogContext)?.pleaseWait ??
                      'Please wait, this may take a moment',
                  style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      String? profileImageUrl;
      String? idImageUrl;
      List<String>? certificationUrls;

      // Upload profile image
      if (profileImage != null) {
        try {
          profileImageUrl = await UploadToFireStorage().uploadFile(
            profileImage!,
            'agents/profiles',
          );
        } catch (e) {
          if (kDebugMode) print('Profile upload failed: $e');
        }
      }

      // Upload ID image
      if (idImage != null) {
        try {
          final ext = idImage!.path.split('.').last.toLowerCase();
          if (['jpg', 'jpeg', 'png'].contains(ext)) {
            idImageUrl = await UploadToFireStorage().uploadFile(
              idImage!,
              'agents/documents',
            );
          } else {
            final fileRef = AppFireStorage.agentDocStorageRef.child(
              'agents/documents/${DateTime.now().millisecondsSinceEpoch}_${idImage!.name}',
            );
            final uploadTask = fileRef.putFile(File(idImage!.path));
            final snapshot = await uploadTask;
            idImageUrl = await snapshot.ref.getDownloadURL();
          }
        } catch (e) {
          if (kDebugMode) print('ID upload failed: $e');
        }
      }

      // Upload certifications
      if (certifications.isNotEmpty) {
        certificationUrls = [];
        for (var cert in certifications) {
          try {
            if (cert.path != null) {
              final fileRef = AppFireStorage.agentDocStorageRef.child(
                'agents/certifications/${DateTime.now().millisecondsSinceEpoch}_${cert.name}',
              );
              final uploadTask = fileRef.putFile(File(cert.path!));
              final snapshot = await uploadTask;
              final downloadUrl = await snapshot.ref.getDownloadURL();
              certificationUrls.add(downloadUrl);
            }
          } catch (e) {
            if (kDebugMode) print('Cert upload failed: $e');
          }
        }
      }

      final location = LocationModel.fromGPS(
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        placemark: _placeMark,
      );

      // Create user document
      final userModel = UserModel(
        role: "technician",
        uid: widget.uid,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        country: "SA",
        location: location,
        jobRoles: selectedJobRoles,
        profileUrl: profileImageUrl,
        docUrl: idImageUrl,
        certifications: certificationUrls,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
        isVerified: false,
        isAdmin: false,
        isOnline: false,
      );

      await AppFirestore.usersCollectionRef
          .doc(widget.uid)
          .set(userModel.toJson());

      // Save UID to local storage
      await LocalStore.putUID(widget.uid);

      // Refresh FCM token after account creation
      await NotificationServices.refreshFCMToken();

      // ✅ Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.accountCreatedSuccessfully ??
                  'Account created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const Home(isNewRegistration: true),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Signup error: $e');
      }

      // ✅ Close loading dialog on error
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToCreateAccount ??
                  'Failed to create account',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: DMSansFont.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem({
    required String label,
    required VoidCallback onTap,
    VoidCallback? onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: DMSansFont.textStyle(
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
    );
  }

  Widget _buildProfilePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: profileImage != null
                  ? FileImage(File(profileImage!.path))
                  : null,
              child: profileImage == null
                  ? Icon(Icons.person_outline, size: 48, color: Colors.grey.shade400)
                  : null,
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
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

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final safePadding = MediaQuery.of(context).padding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleCancelRegistration();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgWhite,
        appBar: AppBar(
          backgroundColor: AppColors.bgWhite,
          elevation: 0,
          surfaceTintColor: AppColors.bgWhite,
          centerTitle: true,
          title: Text(
            locale.completeRegistration,
            style: DMSansFont.textStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            iconSize: 18,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: _handleCancelRegistration,
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, safePadding.bottom + 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLoadingCategories) 
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(),
                  ),

                _buildProfilePicker(),
                const SizedBox(height: 32),

                _buildSection(
                  title: locale.personalInformation,
                  icon: Icons.person_outline,
                  children: [
                    TextFormWidget(
                      controller: nameController,
                      label: locale.fullName,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return locale.pleaseEnterYourName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormWidget(
                      controller: phoneController,
                      label: locale.phoneNumber,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormWidget(
                      controller: emailController,
                      label: '${locale.email} (${locale.optional})',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!emailRegex.hasMatch(value)) {
                            return locale.pleaseEnterValidEmail;
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                _buildSection(
                  title: locale.location,
                  icon: Icons.location_on_outlined,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isFetchingLocation ? null : _getCurrentLocation,
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
                          _isFetchingLocation ? '...' : locale.useCurrentLocation,
                          style: DMSansFont.textStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_currentPosition != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_placeMark != null)
                                    Text(
                                      "${_placeMark!.locality ?? ''}, ${_placeMark!.administrativeArea ?? ''}",
                                      style: DMSansFont.textStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  Text(
                                    "Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}",
                                    style: DMSansFont.textStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
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
                        style: DMSansFont.textStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),

                _buildSection(
                  title: locale.jobRoles,
                  icon: Icons.engineering_outlined,
                  children: [
                    InkWell(
                      onTap: isLoadingCategories ? null : _selectJobRoles,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedJobRoles.isEmpty
                                    ? locale.selectJobRoles
                                    : _getJobRoleNames(),
                                style: DMSansFont.textStyle(
                                  color: selectedJobRoles.isEmpty
                                      ? Colors.grey
                                      : Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                _buildSection(
                  title: locale.documents,
                  icon: Icons.file_present_outlined,
                  children: [
                    Text(
                      locale.idDocument,
                      style: DMSansFont.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (idImage != null)
                      _buildFileItem(
                        label: locale.idDocument,
                        onTap: () => _showFullScreenImage(idImage!, context),
                        onRemove: _removeIdImage,
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickIdImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                          label: Text(locale.uploadIdDocument),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      '${locale.certifications} (${locale.optional})',
                      style: DMSansFont.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...certifications.asMap().entries.map((entry) {
                      return _buildFileItem(
                        label: entry.value.name,
                        onTap: () => _viewCertification(entry.value),
                        onRemove: () => _removeCertification(entry.key),
                      );
                    }),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickCertifications,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: Text(locale.uploadCertifications),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + safePadding.bottom),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: isCreatingAccount ? null : _submitSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isCreatingAccount
                  ? Loader(color: Colors.white, size: 24)
                  : Text(
                      locale.createAccount,
                      style: DMSansFont.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<bool> _handleCancelRegistration() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgWhite,
        actionsAlignment: MainAxisAlignment.start,
        title: Text(AppLocalizations.of(context)!.cancelRegistration),
        content: Text(
          AppLocalizations.of(context)!.cancelRegistrationConfirmation,
        ),
        actions: [
          eButton(
            backgroundColor: AppColors.bgWhite,
            context: context,
            onPressed: () => Navigator.pop(context, false),
            text: AppLocalizations.of(context)!.no,
            textColor: Colors.black,
          ),
          eButton(
            backgroundColor: Colors.red,
            context: context,
            onPressed: () => Navigator.pop(context, true),
            text: AppLocalizations.of(context)!.yes,
            textColor: Colors.white,
          ),
        ],
      ),
    );

    if (confirm != true) return false;
    if (!mounted) return false;

    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }

    await LocalStore.clearUID();
    await LocalStore.putlogoutStatus(true);

    if (!mounted) return false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );

    return false; // ✅ allow pop after handling
  }
}
