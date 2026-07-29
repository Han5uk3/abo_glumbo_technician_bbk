import 'dart:io';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:flutter/material.dart';

Future<bool?> showVerifyPaymentSheet(
  BuildContext context, {
  required BookingModel booking,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) => VerifyPaymentSheet(booking: booking),
  );
}

class VerifyPaymentSheet extends StatefulWidget {
  final BookingModel booking;

  const VerifyPaymentSheet({super.key, required this.booking});

  @override
  State<VerifyPaymentSheet> createState() => _VerifyPaymentSheetState();
}

class _VerifyPaymentSheetState extends State<VerifyPaymentSheet> {
  final List<File> _selectedFiles = [];
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(
            result.paths.map((path) => File(path!)).toList(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppLocalizations.of(context)!.errorUploading}: $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitVerification() async {
    // Payment proof files are now optional
    // if (_selectedFiles.isEmpty) { ... }

    setState(() {
      _isUploading = true;
    });

    try {
      List<String> uploadedUrls = [];

      for (var file in _selectedFiles) {
        final extension = file.path.split('.').last.toLowerCase();
        final fileName =
            'technician_payment_proof_${widget.booking.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('technician_payment_proofs')
            .child(fileName);

        String contentType = 'application/octet-stream';
        if (['jpg', 'jpeg', 'png'].contains(extension)) {
          contentType = 'image/$extension';
        } else if (extension == 'pdf') {
          contentType = 'application/pdf';
        }

        final uploadTask = storageRef.putFile(
          file,
          SettableMetadata(contentType: contentType),
        );

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      // Update booking document to COMPLETED
      await AppFirestore.bookingsCollectionRef.doc(widget.booking.id).update({
        'technicianPaymentProof': uploadedUrls,
        'bookingStatusCode': 'C',
        'paymentCompleted': true,
        'paymentVerifiedAt': FieldValue.serverTimestamp(),
        if (widget.booking.paymentCompletedAt == null)
          'paymentCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Save a transaction record to firestore transactions collection
      final inspectionFee = widget.booking.completionData?.inspectionFee ?? 0.0;
      final serviceCost = widget.booking.completionData?.totalCost ?? 0.0;
      final totalAmount = widget.booking.completionData != null
          ? (serviceCost + inspectionFee)
          : (widget.booking.service.price ?? 0.0);

      final orderId = widget.booking.orderId?.isNotEmpty == true
          ? widget.booking.orderId!
          : "ORDER_CASH_${widget.booking.id}";

      final invoiceId =
          '${widget.booking.newBookingId ?? widget.booking.id}_${widget.booking.customer.uid}';

      final transaction = TransactionModel(
        Timestamp.now(),
        amount: totalAmount,
        paymentStatus: "completed",
        paymentMethod:
            widget.booking.completionData?.paymentMethod.isNotEmpty == true
            ? widget.booking.completionData!.paymentMethod
            : "Outside App - Cash",
        createdAt: Timestamp.now(),
        orderId: orderId,
        customerId: widget.booking.customer.uid,
        workerId: widget.booking.agent?.uid ?? "",
        bookingId: widget.booking.id,
        invoiceId: invoiceId,
      );

      await AppFirestore.transactionsCollectionRef
          .doc(orderId)
          .set(transaction.toMap());

      // Update local booking object before generating invoice
      widget.booking.bookingStatusCode = 'C';
      widget.booking.transactionId = transaction.orderId;
      widget.booking.paymentCompletedAt = Timestamp.now();
      widget.booking.paymentCompleted = true;


      // The unified wallet is credited server-side by the
      // `creditTechnicianWalletOnPaymentCompletion` Cloud Function, which reads
      // the booking as it actually stands in Firestore. It used to be done here
      // from `widget.booking`, which is whatever was loaded when this screen was
      // built — if `completionData` wasn't on that copy the credit was skipped
      // without a trace, and the earnings never appeared in the wallet.

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Home(newIndex: 1)),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.paymentVerifiedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppLocalizations.of(context)!.errorUploading}: $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 50),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.confirmPaymentReceipt,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isUploading
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Info
          Text(
            l10n.uploadTechnicianPaymentProof,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // File List
          if (_selectedFiles.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = _selectedFiles[index];
                  final isImage = [
                    'jpg',
                    'jpeg',
                    'png',
                  ].contains(file.path.split('.').last.toLowerCase());

                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isImage
                              ? Image.file(file, fit: BoxFit.cover)
                              : const Center(
                                  child: Icon(Icons.description, size: 40),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Pick Files Button
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickFiles,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(l10n.selectFiles),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      l10n.confirm,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
