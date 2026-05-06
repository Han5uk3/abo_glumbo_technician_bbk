import 'dart:io';

import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

class CompleteWorkBottomSheet extends StatefulWidget {
  final BookingModel booking;

  const CompleteWorkBottomSheet({super.key, required this.booking});

  @override
  State<CompleteWorkBottomSheet> createState() =>
      _CompleteWorkBottomSheetState();
}

class _CompleteWorkBottomSheetState extends State<CompleteWorkBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceCostController = TextEditingController();
  final List<ServiceItem> _serviceItems = [];
  List<File> selectedFiles = [];
  String? _fileError;
  bool _serviceCompleted = false;

  double get _totalCost {
    if (!_serviceCompleted) {
      return 0;
    }

    if (_serviceItems.isNotEmpty) {
      double itemsTotal = _serviceItems.fold(
        0,
        (sum, item) => sum + (item.quantity * item.price),
      );
      return itemsTotal;
    } else {
      double serviceCost = double.tryParse(_serviceCostController.text) ?? 0;
      return serviceCost;
    }
  }

  @override
  void dispose() {
    _serviceCostController.dispose();
    for (var item in _serviceItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<int?> _showSourceSelector() async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppLocalizations.of(context)?.selectSource ?? 'Select Source',
              style: DMSansFont.textStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    context,
                    icon: Icons.camera_alt_outlined,
                    label: AppLocalizations.of(context)?.camera ?? 'Camera',
                    onTap: () => Navigator.pop(context, 0),
                    color: AppColors.blue1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    context,
                    icon: Icons.folder_open_outlined,
                    label: AppLocalizations.of(context)?.files ?? 'Files',
                    onTap: () => Navigator.pop(context, 1),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: DMSansFont.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final source = await _showSourceSelector();
    if (source == null) return;

    try {
      if (source == 0) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (image != null) {
          final file = File(image.path);
          final size = await file.length();

          if (size > 5 * 1024 * 1024) {
            if (mounted) {
              _showSnackBar(
                '${image.name} ${AppLocalizations.of(context)?.fileTooLarge ?? 'is too large (max 5MB)'}',
                Colors.red,
              );
            }
            return;
          }

          setState(() {
            selectedFiles.add(file);
            _fileError = null;
          });
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc'],
        );

        if (result != null) {
          for (var file in result.files) {
            if (file.size > 5 * 1024 * 1024) {
              if (mounted) {
                _showSnackBar(
                  '${file.name} ${AppLocalizations.of(context)?.fileTooLarge ?? 'is too large (max 5MB)'}',
                  Colors.red,
                );
              }
              return;
            }
          }

          setState(() {
            selectedFiles.addAll(result.files.map((file) => File(file.path!)));
            _fileError = null;
          });
        }
      }
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context)!.error}: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: DMSansFont.textStyle(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _removeFile(int index) {
    _showAppDialog(
      title: AppLocalizations.of(context)!.removeFile,
      message: AppLocalizations.of(context)!.removeFileConfirmation,
      icon: Icons.delete_outline,
      iconColor: Colors.red,
      primaryLabel: AppLocalizations.of(context)!.remove,
      primaryAction: () {
        setState(() => selectedFiles.removeAt(index));
      },
    );
  }

  void _showAppDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String primaryLabel,
    required VoidCallback primaryAction,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: DMSansFont.textStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: DMSansFont.textStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: DMSansFont.textStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                primaryAction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                primaryLabel,
                style: DMSansFont.textStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getFileIcon(String path) {
    String ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) {
      return Icons.image_outlined;
    } else if (ext == 'pdf') {
      return Icons.picture_as_pdf_outlined;
    } else {
      return Icons.insert_drive_file_outlined;
    }
  }

  void _viewFile(File file) {
    String ext = file.path.split('.').last.toLowerCase();
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
                file.path.split('/').last,
                style: DMSansFont.textStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            body: Center(child: InteractiveViewer(child: Image.file(file))),
          ),
        ),
      );
    } else {
      OpenFilex.open(file.path).then((result) {
        if (result.type != ResultType.done) {
          _showSnackBar(
            '${AppLocalizations.of(context)!.couldNotOpenFile}: ${file.path.split('/').last}',
            Colors.red,
          );
        }
      });
    }
  }

  void _addServiceItem() {
    setState(() {
      _serviceItems.add(ServiceItem());
    });
  }

  void _removeServiceItem(int index) {
    _showAppDialog(
      title: AppLocalizations.of(context)!.removeItem,
      message: AppLocalizations.of(context)!.removeItemConfirmation,
      icon: Icons.delete_outline,
      iconColor: Colors.red,
      primaryLabel: AppLocalizations.of(context)!.remove,
      primaryAction: () {
        setState(() {
          _serviceItems[index].dispose();
          _serviceItems.removeAt(index);
        });
      },
    );
  }

  bool _validateForm() {
    bool isValid = true;

    if (_serviceCompleted && selectedFiles.isEmpty) {
      setState(() {
        _fileError = AppLocalizations.of(context)!.pleaseUploadFiles;
      });
      isValid = false;
    }

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
    } else {
      isValid = false;
    }

    if (_serviceCompleted && _serviceItems.isNotEmpty) {
      for (var item in _serviceItems) {
        if (!item.isValid()) {
          _showSnackBar(
            AppLocalizations.of(context)!.pleaseFillAllServiceItemFields,
            Colors.red,
          );
          isValid = false;
          break;
        }
      }
    }

    return isValid;
  }

  void _handleCompleteWithConfirmation() {
    if (_validateForm()) {
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final total = _totalCost;

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.confirmCompletion,
                  style: DMSansFont.textStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.confirmCompletionMessage,
                  style: DMSansFont.textStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _serviceCompleted
                        ? Colors.green.withOpacity(0.05)
                        : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _serviceCompleted
                          ? Colors.green.withOpacity(0.12)
                          : Colors.blue.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _serviceCompleted ? Icons.check_circle : Icons.search,
                        color: _serviceCompleted ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _serviceCompleted
                            ? AppLocalizations.of(context)!.serviceCompleted
                            : AppLocalizations.of(context)!.inspectionOnly,
                        style: DMSansFont.textStyle(
                          fontWeight: FontWeight.bold,
                          color: _serviceCompleted ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_serviceCompleted && total > 0) ...[
                  const SizedBox(height: 20),
                  _buildCostRow(
                    label: AppLocalizations.of(context)!.totalCost,
                    amount: total,
                    isTotal: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: DMSansFont.textStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleComplete();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.confirm,
                      style: DMSansFont.textStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCostRow({
    required String label,
    required double amount,
    bool isTotal = false,
  }) {
    return Container(
      padding: isTotal ? const EdgeInsets.all(12) : EdgeInsets.zero,
      decoration: isTotal
          ? BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: DMSansFont.textStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.primary : Colors.grey[700],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
            style: DMSansFont.textStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _handleComplete() {
    List<BookingServiceItem> items = _serviceCompleted
        ? _serviceItems.map((item) => item.toBookingServiceItem()).toList()
        : [];

    Navigator.of(context).pop();
    context.read<BookingBloc>().add(
      CompleteBooking(
        inspectionFee: widget.booking.service.price ?? 0.0,
        customerId: widget.booking.customer.uid,
        technicianId: widget.booking.agent?.uid ?? "",
        mode: _serviceCompleted ? 1 : 0,
        bookingId: widget.booking.id,
        selectedFiles: selectedFiles,
        serviceCost: _serviceCompleted && _serviceItems.isEmpty
            ? double.parse(_serviceCostController.text)
            : 0,
        serviceItems: items,
        totalCost: _totalCost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.completeWork,
                style: DMSansFont.textStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Service Mode Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _serviceCompleted
                      ? Colors.green.withOpacity(0.04)
                      : Colors.blue.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (_serviceCompleted ? Colors.green : Colors.blue)
                        .withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_serviceCompleted ? Colors.green : Colors.blue)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _serviceCompleted
                            ? Icons.check_circle_outlined
                            : Icons.search,
                        color: _serviceCompleted ? Colors.green : Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _serviceCompleted
                                ? AppLocalizations.of(context)!.serviceCompleted
                                : AppLocalizations.of(context)!.inspectionOnly,
                            style: DMSansFont.textStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _serviceCompleted
                                ? AppLocalizations.of(
                                    context,
                                  )!.serviceCompletedDescription
                                : AppLocalizations.of(
                                    context,
                                  )!.inspectionOnlyDescription,
                            style: DMSansFont.textStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _serviceCompleted,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          _serviceCompleted = value;
                          if (!value) {
                            _serviceCostController.clear();
                            for (var item in _serviceItems) {
                              item.dispose();
                            }
                            _serviceItems.clear();
                            selectedFiles.clear();
                            _fileError = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method Toggle
             
              const SizedBox(height: 24),

              if (_serviceCompleted) ...[
                // Attachments Title
                Row(
                  children: [
                    const Icon(
                      Icons.attachment_outlined,
                      size: 20,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        maxLines: 2,
                        '${AppLocalizations.of(context)!.uploadFilesTitle}*',
                        style: DMSansFont.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Selected Files Horizontal List
                if (selectedFiles.isNotEmpty) ...[
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final file = selectedFiles[index];
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => _viewFile(file),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _getFileIcon(file.path),
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        file.path.split('/').last,
                                        style: DMSansFont.textStyle(
                                          fontSize: 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () => _removeFile(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Upload Trigger
                InkWell(
                  onTap: _pickFiles,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _fileError != null
                            ? Colors.red
                            : AppColors.primary.withOpacity(0.12),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          selectedFiles.isEmpty
                              ? AppLocalizations.of(context)!.tapToUploadFiles
                              : AppLocalizations.of(context)!.addMoreFiles,
                          style: DMSansFont.textStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_fileError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _fileError!,
                      style: DMSansFont.textStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Cost Input Section
                if (_serviceItems.isEmpty) ...[
                  Text(
                    '${AppLocalizations.of(context)!.serviceCost} *',
                    style: DMSansFont.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _serviceCostController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (!_serviceCompleted || _serviceItems.isNotEmpty) {
                        return null;
                      }
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.pleaseEnterServiceCost;
                      }
                      if (double.tryParse(value) == null) {
                        return AppLocalizations.of(
                          context,
                        )!.pleaseEnterValidNumber;
                      }
                      if (double.parse(value) <= 0) {
                        return AppLocalizations.of(
                          context,
                        )!.serviceCostMustBeGreaterThanZero;
                      }
                      return null;
                    },
                    decoration: _premiumInputDecoration(
                      hint: AppLocalizations.of(context)!.enterServiceCost,
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Service Items Section
                if (_serviceCostController.text.isEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.serviceItems,
                        style: DMSansFont.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addServiceItem,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: Text(AppLocalizations.of(context)!.addItem),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_serviceItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.pleaseAddAtleastOneServiceItem,
                            style: DMSansFont.textStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _serviceItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller:
                                          _serviceItems[index].nameController,
                                      decoration: _premiumInputDecoration(
                                        hint: AppLocalizations.of(
                                          context,
                                        )!.item,
                                        label:
                                            "${AppLocalizations.of(context)!.item} ${index + 1}",
                                      ),
                                      validator: (v) =>
                                          (!_serviceCompleted ||
                                              _serviceItems.isEmpty)
                                          ? null
                                          : (v == null || v.isEmpty
                                                ? AppLocalizations.of(
                                                    context,
                                                  )!.required
                                                : null),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _removeServiceItem(index),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.withOpacity(
                                        0.05,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _serviceItems[index]
                                          .quantityController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: _premiumInputDecoration(
                                        hint: AppLocalizations.of(context)!.qty,
                                        label: AppLocalizations.of(
                                          context,
                                        )!.qty,
                                      ),
                                      validator: (v) => _validateNumberField(v),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller:
                                          _serviceItems[index].priceController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: _premiumInputDecoration(
                                        hint: AppLocalizations.of(
                                          context,
                                        )!.price,
                                        label: AppLocalizations.of(
                                          context,
                                        )!.price,
                                      ),
                                      validator: (v) => _validateNumberField(v),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ],

              // Final Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: DMSansFont.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleCompleteWithConfirmation,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.complete,
                        style: DMSansFont.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateNumberField(String? value) {
    if (!_serviceCompleted || _serviceItems.isEmpty) return null;
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.required;
    }
    final numValue = double.tryParse(value);
    if (numValue == null) return AppLocalizations.of(context)!.invalid;
    if (numValue <= 0) {
      return AppLocalizations.of(context)!.serviceCostMustBeGreaterThanZero;
    }
    return null;
  }

  InputDecoration _premiumInputDecoration({
    required String hint,
    String? label,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      labelStyle: DMSansFont.textStyle(color: Colors.grey[500], fontSize: 13),
      hintStyle: DMSansFont.textStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.primary, size: 20)
          : null,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[100]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class ServiceItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  double get quantity => double.tryParse(quantityController.text) ?? 0;
  double get price => double.tryParse(priceController.text) ?? 0;

  bool isValid() {
    return nameController.text.isNotEmpty &&
        quantityController.text.isNotEmpty &&
        priceController.text.isNotEmpty &&
        quantity > 0 &&
        price > 0;
  }

  BookingServiceItem toBookingServiceItem() {
    return BookingServiceItem(
      name: nameController.text,
      quantity: quantity,
      price: price,
    );
  }

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}
