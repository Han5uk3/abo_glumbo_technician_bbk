import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/firestorage.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class ReuploadDocsPage extends StatefulWidget {
  final UserModel workerData;
  const ReuploadDocsPage({super.key, required this.workerData});

  @override
  State<ReuploadDocsPage> createState() => _ReuploadDocsPageState();
}

class _ReuploadDocsPageState extends State<ReuploadDocsPage> {
  XFile? residenceIdImage;
  PlatformFile? sponsorWorkPermitFile;
  PlatformFile? chamberOfCommerceFile;
  List<PlatformFile> certifications = [];
  bool isUploading = false;
  bool isOpeningPreview = false;

  String? existingResidenceIdUrl;
  String? existingSponsorWorkPermitUrl;
  String? existingChamberOfCommerceUrl;
  List<String> existingCertifications = [];

  @override
  void initState() {
    super.initState();
    existingResidenceIdUrl = widget.workerData.residenceIdUrl;
    existingSponsorWorkPermitUrl = widget.workerData.sponsorWorkPermitUrl;
    existingChamberOfCommerceUrl =
        widget.workerData.chamberOfCommerceApprovalUrl;
    existingCertifications = List.from(widget.workerData.certifications ?? []);
  }

  Future<XFile?> _pickImage({bool crop = true, bool square = true}) async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.3,
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      backgroundColor: Colors.white,
      showDragHandle: true,
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: ListTile(
                  tileColor: Colors.white,
                  leading: const Icon(Icons.camera_alt),
                  title: Text(AppLocalizations.of(context)?.camera ?? 'Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: ListTile(
                  tileColor: Colors.white,
                  leading: const Icon(Icons.photo_library),
                  title: Text(
                    AppLocalizations.of(context)?.gallery ?? 'Gallery',
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
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
              toolbarTitle: l10n.cropImage,
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: square
                  ? CropAspectRatioPreset.square
                  : CropAspectRatioPreset.original,
              lockAspectRatio: square,
            ),
            IOSUiSettings(
              title: l10n.cropImage,
              aspectRatioLockEnabled: square,
            ),
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

  bool _isImage(String? pathOrUrl) {
    if (pathOrUrl == null) return false;
    final String path = pathOrUrl.split('?').first.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  Future<void> _previewFile({
    String? path,
    String? url,
    required bool isImage,
  }) async {
    if (path == null && url == null) return;
    if (isOpeningPreview) return;

    setState(() => isOpeningPreview = true);

    try {
      if (isImage) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: InteractiveViewer(
                  child: path != null
                      ? Image.file(File(path), fit: BoxFit.contain)
                      : Image.network(url!, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        );
      } else {
        if (path != null) {
          await OpenFilex.open(path);
        } else if (url != null) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        // Small delay for external apps to open
        await Future.delayed(const Duration(seconds: 1));
      }
    } finally {
      if (mounted) setState(() => isOpeningPreview = false);
    }
  }

  Future<void> _submitReupload() async {
    final l10n = AppLocalizations.of(context)!;

    // Check if anything has changed
    final bool hasNewFiles =
        residenceIdImage != null ||
        sponsorWorkPermitFile != null ||
        chamberOfCommerceFile != null ||
        certifications.isNotEmpty;

    final bool hasRemovals =
        existingResidenceIdUrl != widget.workerData.residenceIdUrl ||
        existingSponsorWorkPermitUrl !=
            widget.workerData.sponsorWorkPermitUrl ||
        existingChamberOfCommerceUrl !=
            widget.workerData.chamberOfCommerceApprovalUrl ||
        existingCertifications.length !=
            (widget.workerData.certifications?.length ?? 0);

    if (!hasNewFiles && !hasRemovals) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectAtLeastOneDocumentToUpdate)),
      );
      return;
    }

    setState(() => isUploading = true);
    try {
      String? residenceIdUrl = existingResidenceIdUrl;
      String? sponsorWorkPermitUrl = existingSponsorWorkPermitUrl;
      String? chamberOfCommerceUrl = existingChamberOfCommerceUrl;
      List<String> certUrls = List.from(existingCertifications);

      if (residenceIdImage != null) {
        residenceIdUrl = await UploadToFireStorage().uploadFile(
          residenceIdImage!,
          'agents/documents',
        );
      }

      if (sponsorWorkPermitFile?.path != null) {
        sponsorWorkPermitUrl = await UploadToFireStorage().uploadFile(
          XFile(sponsorWorkPermitFile!.path!),
          'agents/documents',
        );
      }

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

      Map<String, dynamic> updateData = {
        'isDocsPendingReview': true,
        'updatedAt': DateTime.now(),
      };

      if (residenceIdUrl != widget.workerData.residenceIdUrl) {
        updateData['residenceIdUrl'] = residenceIdUrl;
      }
      if (sponsorWorkPermitUrl != widget.workerData.sponsorWorkPermitUrl) {
        updateData['sponsorWorkPermitUrl'] = sponsorWorkPermitUrl;
      }
      if (chamberOfCommerceUrl !=
          widget.workerData.chamberOfCommerceApprovalUrl) {
        updateData['chamberOfCommerceApprovalUrl'] = chamberOfCommerceUrl;
      }

      // Check if certifications list has changed (removals or additions)
      final bool certsChanged =
          certUrls.length != (widget.workerData.certifications?.length ?? 0) ||
          certUrls.any(
            (url) =>
                !(widget.workerData.certifications?.contains(url) ?? false),
          );

      if (certsChanged) {
        updateData['certifications'] = certUrls;
      }

      await AppFirestore.usersCollectionRef
          .doc(widget.workerData.uid)
          .update(updateData);

      // Update local cache
      final updatedUser = widget.workerData.copyWith(
        residenceIdUrl: residenceIdUrl,
        sponsorWorkPermitUrl: sponsorWorkPermitUrl,
        chamberOfCommerceApprovalUrl: chamberOfCommerceUrl,
        certifications: certUrls,
        isDocsPendingReview: true,
      );
      await LocalStore.storeUserData(updatedUser);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Reupload Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.reuploadFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !isUploading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            onPressed: isUploading ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            l10n.updateDocuments,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: isUploading
            ? const Center(child: Loader())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildPickerTile(
                    title: l10n.residenceIDImage,
                    file: residenceIdImage,
                    remoteUrl: existingResidenceIdUrl,
                    isImage: true,
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
                  _buildPickerTile(
                    title: l10n.sponsorWorkPermit,
                    file: sponsorWorkPermitFile,
                    remoteUrl: existingSponsorWorkPermitUrl,
                    isImage: _isImage(
                      sponsorWorkPermitFile?.path ??
                          existingSponsorWorkPermitUrl,
                    ),
                    onTap: () async {
                      final f = await _pickFile();
                      if (f != null) setState(() => sponsorWorkPermitFile = f);
                    },
                    onClear: () => setState(() {
                      sponsorWorkPermitFile = null;
                      existingSponsorWorkPermitUrl = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildPickerTile(
                    title: l10n.chamberOfCommerceApproval,
                    file: chamberOfCommerceFile,
                    remoteUrl: existingChamberOfCommerceUrl,
                    isImage: _isImage(
                      chamberOfCommerceFile?.path ??
                          existingChamberOfCommerceUrl,
                    ),
                    onTap: () async {
                      final f = await _pickFile();
                      if (f != null) setState(() => chamberOfCommerceFile = f);
                    },
                    onClear: () => setState(() {
                      chamberOfCommerceFile = null;
                      existingChamberOfCommerceUrl = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.certifications,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickCertifications,
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                            Icons.add_circle_outline,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.add,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (certifications.isNotEmpty ||
                      existingCertifications.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: [
                        ...existingCertifications.asMap().entries.map((entry) {
                          return InputChip(
                            label: Text(
                              '${l10n.certificate} ${entry.key + 1}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () => _previewFile(
                              url: entry.value,
                              isImage: _isImage(entry.value),
                            ),
                            onDeleted: () => setState(
                              () => existingCertifications.remove(entry.value),
                            ),
                          );
                        }),
                        ...certifications.asMap().entries.map((entry) {
                          return InputChip(
                            label: Text(
                              entry.value.name,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () => _previewFile(
                              path: entry.value.path,
                              isImage: _isImage(entry.value.path),
                            ),
                            onDeleted: () => setState(
                              () => certifications.removeAt(entry.key),
                            ),
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 40),
                  eButton(
                    text: AppLocalizations.of(context)!.submit,
                    onPressed: _submitReupload,
                    context: context,
                    backgroundColor: AppColors.primary,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String title,
    required dynamic file,
    String? remoteUrl,
    required bool isImage,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final l10n = AppLocalizations.of(context)!;
    bool hasFile = file != null;
    bool hasRemote = remoteUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (hasFile || hasRemote) ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (hasFile || hasRemote)
                  ? AppColors.primary
                  : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onTap,
                child: Icon(
                  (hasFile || hasRemote)
                      ? Icons.check_circle
                      : Icons.upload_file,
                  color: (hasFile || hasRemote) ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (hasFile) {
                      _previewFile(
                        path: file is XFile ? file.path : file.path,
                        isImage: isImage,
                      );
                    } else if (hasRemote) {
                      _previewFile(url: remoteUrl, isImage: isImage);
                    } else {
                      onTap();
                    }
                  },
                  child: Text(
                    hasFile
                        ? (file is XFile ? file.name : file.name)
                        : hasRemote
                        ? title
                        : l10n.selectFile,
                    style: TextStyle(
                      color: (hasFile || hasRemote)
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              if (hasFile || hasRemote)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: onClear,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
