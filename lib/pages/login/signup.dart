import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/geohash_helper.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/firestorage.dart';
import 'package:aboglumbo_bbk_panel/services/notification_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class Signup extends StatefulWidget {
  final String uid;

  const Signup({super.key, required this.uid});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  XFile? profileImage;
  XFile? residenceIdImage;
  PlatformFile? sponsorWorkPermitFile;
  PlatformFile? chamberOfCommerceFile;
  List<PlatformFile> certifications = [];

  Position? _currentPosition;
  Placemark? _placeMark;
  bool _isFetchingLocation = false;

  List<Map<String, dynamic>> jobCategories = [];
  List<String> selectedJobRoles = [];
  bool isLoadingCategories = true;

  String? existingProfileUrl;
  String? existingResidenceIdUrl;
  String? existingSponsorWorkPermitUrl;
  String? existingChamberOfCommerceUrl;
  List<String> existingCertifications = [];
  Timestamp? existingCreatedAt;
  bool _isLoadingExistingData = false;

  @override
  void initState() {
    super.initState();
    phoneController.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    _loadJobCategories();
    _initRegistrationFlow();
  }

  Future<void> _initRegistrationFlow() async {
    await _loadExistingUserData();
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }
  }

  Future<void> _loadExistingUserData() async {
    setState(() {
      _isLoadingExistingData = true;
    });
    try {
      final doc = await AppFirestore.usersCollectionRef.doc(widget.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final user = UserModel.fromJson(data);
          
          nameController.text = user.name ?? '';
          if (user.phone != null && user.phone!.isNotEmpty) {
            phoneController.text = user.phone!;
          }
          emailController.text = user.email ?? '';
          
          if (user.jobRoles != null) {
            selectedJobRoles = List<String>.from(user.jobRoles!);
          }
          
          existingProfileUrl = user.profileUrl;
          existingResidenceIdUrl = user.residenceIdUrl;
          existingSponsorWorkPermitUrl = user.sponsorWorkPermitUrl;
          existingChamberOfCommerceUrl = user.chamberOfCommerceApprovalUrl;
          if (user.certifications != null) {
            existingCertifications = List<String>.from(user.certifications!);
          }
          existingCreatedAt = user.createdAt;
          
          if (user.location != null && user.location!.lat != null && user.location!.lon != null) {
            _currentPosition = Position(
              latitude: user.location!.lat!,
              longitude: user.location!.lon!,
              timestamp: DateTime.now(),
              accuracy: 0.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: 0.0,
              headingAccuracy: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
            );
            if (user.location!.fullAddress != null) {
              _placeMark = Placemark(
                name: user.location!.fullAddress,
                street: user.location!.street ?? user.location!.fullAddress,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading existing user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExistingData = false;
        });
      }
    }
  }

  Future<void> _loadJobCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final categoriesMap = await AppServices.fetchJobCategories();
      jobCategories = categoriesMap.entries.map((entry) {
        return <String, dynamic>{
          'id': entry.key,
          'name': entry.value['en'] ?? '',
          'nameAr': entry.value['ar'] ?? '',
          'nameUr':
              entry.value['ur'] ?? entry.value['ar'] ?? entry.value['en'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading job categories: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingCategories = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw AppLocalizations.of(context)?.locationServicesDisabled ?? 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw AppLocalizations.of(context)?.locationPermissionDenied ?? 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw AppLocalizations.of(context)?.locationPermissionDeniedForever ?? 'Location permissions are permanently denied.';
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
        });
        String errorMessage = e.toString();
        SnackBarAction? snackBarAction;

        if (e is LocationServiceDisabledException || errorMessage.contains('Location services are disabled')) {
          errorMessage = AppLocalizations.of(context)?.locationServicesDisabled ?? 'Location services are disabled.';
          snackBarAction = SnackBarAction(
            label: AppLocalizations.of(context)?.openSettings ?? 'Settings',
            onPressed: () => Geolocator.openLocationSettings(),
          );
        } else if (e is PermissionDeniedException || errorMessage.contains('User denied permissions') || errorMessage.contains('Permission denied')) {
          errorMessage = AppLocalizations.of(context)?.locationPermissionDenied ?? 'Location permissions are denied';
          snackBarAction = SnackBarAction(
            label: AppLocalizations.of(context)?.openSettings ?? 'Settings',
            onPressed: () => Geolocator.openAppSettings(),
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.errorFetchingLocation(errorMessage) ?? 'Error fetching location: $errorMessage',
            ),
            action: snackBarAction,
          ),
        );
      }
    }
  }

  Future<XFile?> _pickImage({bool crop = true, bool square = true}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && crop) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: square
              ? const CropAspectRatio(ratioX: 1, ratioY: 1)
              : null,
          compressQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: square
                  ? CropAspectRatioPreset.square
                  : CropAspectRatioPreset.original,
              lockAspectRatio: square,
            ),
            IOSUiSettings(title: 'Crop Image', aspectRatioLockEnabled: square),
          ],
        );

        if (croppedFile != null) {
          return XFile(croppedFile.path);
        }
      }
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<PlatformFile?> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  Future<void> _pickCertifications() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          certifications.addAll(result.files);
        });
      }
    } catch (e) {
      debugPrint('Error picking certifications: $e');
    }
  }

  Widget _buildSectionTitle(String title, {bool mandatory = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: RichText(
        text: TextSpan(
          text: title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          children: [
            if (mandatory)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileOrImagePickerTile({
    required String title,
    required dynamic fileOrImage, // Can be XFile or PlatformFile
    String? existingUrl,
    required VoidCallback onTap,
    required VoidCallback onClear,
    bool mandatory = false,
  }) {
    bool hasFile = fileOrImage != null;
    bool hasRemote = existingUrl != null && existingUrl.isNotEmpty;
    bool isImage = false;
    String? path;
    if (hasFile) {
      if (fileOrImage is XFile) {
        path = fileOrImage.path;
        isImage = [
          'jpg',
          'jpeg',
          'png',
        ].contains(path.split('.').last.toLowerCase());
      } else if (fileOrImage is PlatformFile) {
        path = fileOrImage.path;
        isImage = [
          'jpg',
          'jpeg',
          'png',
        ].contains(fileOrImage.extension?.toLowerCase() ?? '');
      }
    } else if (hasRemote) {
      isImage = [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
      ].contains(existingUrl.split('?').first.split('.').last.toLowerCase());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, mandatory: mandatory),
        GestureDetector(
          onTap: hasFile
              ? () => _previewFile(path, isImage)
              : (hasRemote ? () => _previewFile(existingUrl, isImage, isRemote: true) : onTap),
          child: Container(
            width: double.infinity,
            height: (hasFile || hasRemote) ? 70 : 140,
            decoration: BoxDecoration(
              color: (hasFile || hasRemote) ? Colors.white : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (hasFile || hasRemote)
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: !(hasFile || hasRemote)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload File or Image',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isImage
                                ? Icons.image_outlined
                                : Icons.description_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            hasFile
                                ? (fileOrImage is XFile ? fileOrImage.name : fileOrImage.name)
                                : title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onClear,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _previewFile(String? pathOrUrl, bool isImage, {bool isRemote = false}) {
    if (pathOrUrl == null) return;

    if (isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                child: isRemote
                    ? Image.network(pathOrUrl, fit: BoxFit.contain)
                    : Image.file(File(pathOrUrl), fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      );
    } else {
      if (isRemote) {
        launchUrl(Uri.parse(pathOrUrl), mode: LaunchMode.externalApplication);
      } else {
        OpenFilex.open(pathOrUrl);
      }
    }
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      debugPrint('Signup Error: Current position is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseFetchLocation ??
                'Please fetch your current location',
          ),
        ),
      );
      return;
    }

    if (selectedJobRoles.isEmpty) {
      debugPrint('Signup Error: No job roles selected');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectRole ??
                'Please select at least one job role',
          ),
        ),
      );
      return;
    }

    final hasResidenceId = residenceIdImage != null || (existingResidenceIdUrl != null && existingResidenceIdUrl!.isNotEmpty);
    final hasSponsorWorkPermit = sponsorWorkPermitFile != null || (existingSponsorWorkPermitUrl != null && existingSponsorWorkPermitUrl!.isNotEmpty);
    final hasChamberOfCommerce = chamberOfCommerceFile != null || (existingChamberOfCommerceUrl != null && existingChamberOfCommerceUrl!.isNotEmpty);

    if (!hasResidenceId || !hasSponsorWorkPermit || !hasChamberOfCommerce) {
      debugPrint('Signup Error: Missing mandatory documents');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseUploadDocuments ??
                'Please upload all mandatory documents',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: Loader()),
    );

    try {
      String? profileUrl = existingProfileUrl;
      String? residenceIdUrl = existingResidenceIdUrl;
      String? sponsorWorkPermitUrl = existingSponsorWorkPermitUrl;
      String? chamberOfCommerceUrl = existingChamberOfCommerceUrl;
      List<String> certUrls = List.from(existingCertifications);

      if (profileImage != null) {
        profileUrl = await UploadToFireStorage().uploadFile(
          profileImage!,
          'agents/profiles',
        );
      }
      if (residenceIdImage != null) {
        residenceIdUrl = await UploadToFireStorage().uploadFile(
          residenceIdImage!,
          'agents/documents',
        );
      }

      // Upload Sponsor Work Permit
      if (sponsorWorkPermitFile?.path != null) {
        sponsorWorkPermitUrl = await UploadToFireStorage().uploadFile(
          XFile(sponsorWorkPermitFile!.path!),
          'agents/documents',
        );
      }

      // Upload Chamber of Commerce Approval
      if (chamberOfCommerceFile?.path != null) {
        chamberOfCommerceUrl = await UploadToFireStorage().uploadFile(
          XFile(chamberOfCommerceFile!.path!),
          'agents/documents',
        );
      }

      for (var cert in certifications) {
        if (cert.path != null) {
          final url = await UploadToFireStorage().uploadFile(
            XFile(cert.path!),
            'agents/certifications',
          );
          if (url != null) certUrls.add(url);
        }
      }

      final location = LocationModel.fromGPS(
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        placemark: _placeMark,
      );

      final user = UserModel(
        role: "technician",
        uid: widget.uid,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        country: "SA",
        location: location,
        lastKnownLocation: GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        geohash: GeohashHelper.encode(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        jobRoles: selectedJobRoles,
        profileUrl: profileUrl,
        residenceIdUrl: residenceIdUrl,
        sponsorWorkPermitUrl: sponsorWorkPermitUrl,
        chamberOfCommerceApprovalUrl: chamberOfCommerceUrl,
        certifications: certUrls,
        createdAt: existingCreatedAt ?? Timestamp.now(),
        updatedAt: Timestamp.now(),
        isVerified: false,
        isAdmin: false,
        isOnline: false,
        isRegistrationComplete: true,
        isDocsPendingReview: true,
      );

      await AppFirestore.usersCollectionRef.doc(widget.uid).set(user.toJson());
      await LocalStore.putUID(widget.uid);
      await LocalStore.storeUserData(user);

      try {
        final fcmToken = await NotificationServices.getCurrentFCMToken();
        if (fcmToken != null) {
          await AppServices.updateFCMToken(fcmToken);
        }
      } catch (e) {
        debugPrint('FCM Token error: $e');
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Signup Exception: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.registrationFailed} ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExistingData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Loader()),
      );
    }
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          localization.createAccount,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: profileImage != null
                        ? FileImage(File(profileImage!.path))
                        : (existingProfileUrl != null && existingProfileUrl!.isNotEmpty
                            ? NetworkImage(existingProfileUrl!) as ImageProvider
                            : null),
                    child: (profileImage == null && (existingProfileUrl == null || existingProfileUrl!.isEmpty))
                        ? Icon(
                            Icons.person_outline,
                            size: 50,
                            color: Colors.grey[400],
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        final img = await _pickImage();
                        if (img != null) setState(() => profileImage = img);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
            ),

            const SizedBox(height: 32),

            _buildSectionTitle(localization.fullName, mandatory: true),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: localization.enterYourFullName,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(fontSize: 16),
              validator: (v) =>
                  v!.isEmpty ? localization.pleaseEnterYourFullName : null,
            ),

            _buildSectionTitle(localization.phoneNumber, mandatory: true),
            TextFormField(
              controller: phoneController,
              enabled: false,
              readOnly: true,
              decoration: InputDecoration(
                hintText: localization.phoneNumber,
                prefixIcon: const Icon(Icons.phone_android, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                fillColor: Colors.grey[50],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            _buildSectionTitle(localization.email),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: localization.enterYourEmail,
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(fontSize: 16),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Divider(),
            ),

            _buildFileOrImagePickerTile(
              title: localization.residenceIDImage,
              fileOrImage: residenceIdImage,
              existingUrl: existingResidenceIdUrl,
              mandatory: true,
              onTap: () async {
                final img = await _pickImage(square: false);
                if (img != null) setState(() => residenceIdImage = img);
              },
              onClear: () => setState(() {
                residenceIdImage = null;
                existingResidenceIdUrl = null;
              }),
            ),

            const SizedBox(height: 16),

            _buildFileOrImagePickerTile(
              title: localization.sponsorWorkPermit,
              fileOrImage: sponsorWorkPermitFile,
              existingUrl: existingSponsorWorkPermitUrl,
              mandatory: true,
              onTap: () async {
                final file = await _pickFile();
                if (file != null) setState(() => sponsorWorkPermitFile = file);
              },
              onClear: () => setState(() {
                sponsorWorkPermitFile = null;
                existingSponsorWorkPermitUrl = null;
              }),
            ),

            const SizedBox(height: 16),

            _buildFileOrImagePickerTile(
              title: localization.chamberOfCommerceApproval,
              fileOrImage: chamberOfCommerceFile,
              existingUrl: existingChamberOfCommerceUrl,
              mandatory: true,
              onTap: () async {
                final file = await _pickFile();
                if (file != null) setState(() => chamberOfCommerceFile = file);
              },
              onClear: () => setState(() {
                chamberOfCommerceFile = null;
                existingChamberOfCommerceUrl = null;
              }),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(
              localization.certificatesOrTrainingCoursesOptional,
            ),
            GestureDetector(
              onTap: _pickCertifications,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.file_present_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        certifications.isEmpty && existingCertifications.isEmpty
                            ? localization.uploadCertificates
                            : '${certifications.length + existingCertifications.length} ${localization.filesSelected}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (certifications.isNotEmpty || existingCertifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ...existingCertifications.asMap().entries.map((entry) {
                      return Chip(
                        label: Text(
                          '${localization.certificate} ${entry.key + 1}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onDeleted: () =>
                            setState(() => existingCertifications.removeAt(entry.key)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        backgroundColor: Colors.grey[100],
                      );
                    }),
                    ...certifications.asMap().entries.map((entry) {
                      return Chip(
                        label: Text(
                          entry.value.name,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onDeleted: () =>
                            setState(() => certifications.removeAt(entry.key)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        backgroundColor: Colors.grey[100],
                      );
                    }),
                  ],
                ),
              ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Divider(),
            ),

            _buildSectionTitle(localization.location, mandatory: true),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _placeMark != null
                              ? '${_placeMark!.street}, ${_placeMark!.locality}'
                              : (_currentPosition != null
                                    ? '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                    : localization.fetching),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (_placeMark != null)
                          Text(
                            '${_placeMark!.subAdministrativeArea}, ${_placeMark!.country}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          )
                        else if (_currentPosition != null)
                          Text(
                            localization.locationSaved,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isFetchingLocation)
                    const Loader(size: 16)
                  else
                    IconButton(
                      onPressed: _getCurrentLocation,
                      icon: Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      tooltip: localization.refreshLocation,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle(localization.jobRoles, mandatory: true),
            GestureDetector(
              onTap: _showJobRoleSelector,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        selectedJobRoles.isEmpty
                            ? localization.selectJobRoles
                            : _getJobRoleNames(),
                        style: TextStyle(
                          color: selectedJobRoles.isEmpty
                              ? Colors.grey[400]
                              : Colors.black87,
                          fontWeight: selectedJobRoles.isEmpty
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            eButton(
              context: context,
              onPressed: _submitSignup,
              text: localization.createAccount,
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _showJobRoleSelector() {
    final localization = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localization.selectJobRoles,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localization.selectJobRolesDescription,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: isLoadingCategories
                        ? const Center(child: Loader())
                        : ListView.separated(
                            itemCount: jobCategories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final cat = jobCategories[index];
                              final isSelected = selectedJobRoles.contains(
                                cat['id'],
                              );
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedJobRoles.remove(cat['id']);
                                    } else {
                                      selectedJobRoles.add(cat['id']);
                                    }
                                  });
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.05)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey[200]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          LocalStore.getUserlanguage() == 'ur'
                                              ? (cat['nameUr'] ??
                                                    cat['nameAr'] ??
                                                    cat['name'] ??
                                                    '')
                                              : (LocalStore.getUserlanguage() ==
                                                        'ar'
                                                    ? cat['nameAr']
                                                    : cat['name']),
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                        )
                                      else
                                        Icon(
                                          Icons.circle_outlined,
                                          color: Colors.grey[300],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  eButton(
                    context: context,
                    onPressed: () => Navigator.pop(context),
                    text: localization.done,
                    backgroundColor: AppColors.primary,
                    textColor: Colors.white,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getJobRoleNames() {
    return selectedJobRoles
        .map((id) {
          final cat = jobCategories.firstWhere(
            (element) => element['id'] == id,
            orElse: () => {},
          );
          final lang = LocalStore.getUserlanguage();
          if (lang == 'ur') {
            return cat['nameUr'] ?? cat['nameAr'] ?? cat['name'] ?? id;
          } else if (lang == 'ar') {
            return cat['nameAr'] ?? id;
          }
          return cat['name'] ?? id;
        })
        .join(', ');
  }
}
