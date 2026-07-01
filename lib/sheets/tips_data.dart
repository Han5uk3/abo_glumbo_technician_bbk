import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/tipping.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void showTipDetailsBottomSheet(
  TippingModel tip,
  BuildContext context, {
  required Function(TippingModel tip, XFile? image, String transactionId)
  onClearWallet,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TipsDataSheet(tip: tip, onClearWallet: onClearWallet),
  );
}

class TipsDataSheet extends StatelessWidget {
  final TippingModel tip;
  final Function(TippingModel tip, XFile? image, String transactionId)
  onClearWallet;
  const TipsDataSheet({
    super.key,
    required this.tip,
    required this.onClearWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.agentName ?? "Unknown Agent",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)?.agentInfo ??
                            'Agent Information',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection(
                    title:
                        AppLocalizations.of(context)?.tipInfo ??
                        'Tip Information',
                    children: [
                      _buildDetailRow(
                        AppLocalizations.of(context)!.tips,
                        "${tip.cardtip?.toStringAsFixed(2) ?? '0.00'} ${AppLocalizations.of(context)!.sar}",
                        valueColor: Colors.green.shade700,
                        isHighlighted: true,
                      ),
                      _buildDetailRow(
                        AppLocalizations.of(context)?.lastUpdated ??
                            'Last Updated',
                        tip.lastUpdated != null
                            ? tip.lastUpdated!.toDate().format('d/m/Y - H:m A')
                            // ? "${tip.lastUpdated!.day}/${tip.lastUpdated!.month}/${tip.lastUpdated!.year} at ${tip.lastUpdated!.hour}:${tip.lastUpdated!.minute.toString().padLeft(2, '0')} ${tip.lastUpdated!.hour > 12 ? AppLocalizations.of(context)!.pm : AppLocalizations.of(context)!.am}"
                            : "Never",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailSection(
                    title:
                        AppLocalizations.of(context)?.agentInfo ??
                        'Agent Information',
                    children: [
                      _buildDetailRow(
                        AppLocalizations.of(context)?.agentId ?? 'Agent ID',
                        tip.agentId ?? "N/A",
                      ),
                      _buildDetailRow(
                        AppLocalizations.of(context)?.phoneNumber ??
                            'Phone Number',
                        tip.agentPhone ?? "N/A",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      tip.payoutRequested == true &&
                          tip.cashtip != null &&
                          tip.cardtip! > 0
                      ? () {
                          _showClearWalletConfirmation(tip, context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: Directionality.of(context),
                    children: [
                      if (Directionality.of(context) == TextDirection.ltr) ...[
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)?.sendAndClearWallet ??
                              'Clear Wallet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        Text(
                          AppLocalizations.of(context)?.sendAndClearWallet ??
                              'Clear Wallet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.send_rounded, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 14 : 12,
                color: valueColor ?? Colors.grey.shade800,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearWalletConfirmation(TippingModel tip, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          _ClearWalletDialog(tip: tip, onClearWallet: onClearWallet),
    );
  }
}

class _ClearWalletDialog extends StatefulWidget {
  final TippingModel tip;
  final Function(TippingModel tip, XFile? image, String transactionId)
  onClearWallet;

  const _ClearWalletDialog({required this.tip, required this.onClearWallet});

  @override
  State<_ClearWalletDialog> createState() => _ClearWalletDialogState();
}

class _ClearWalletDialogState extends State<_ClearWalletDialog> {
  late final TextEditingController transactionIdController;
  final formKey = GlobalKey<FormState>();
  XFile? selectedFile;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    transactionIdController = TextEditingController();
  }

  @override
  void dispose() {
    transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isLoading,
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.start,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)?.clearWallet ?? 'Clear Wallet',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${AppLocalizations.of(context)!.areYouSureYouWantToSend} ${AppLocalizations.of(context)!.sar}${widget.tip.cardtip?.toStringAsFixed(2)} ${AppLocalizations.of(context)!.to} ${widget.tip.agentName} ${AppLocalizations.of(context)!.andClearTheirWallet}?",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)?.clearWalletWarning ??
                              'This action cannot be undone. The agent will receive the total amount in their wallet, and it will be reset to zero.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Transaction ID Field
                TextFormField(
                  controller: transactionIdController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.transactionNumber ??
                        'Transaction ID *',
                    hintText:
                        AppLocalizations.of(context)?.enterTransactionNumber ??
                        'Enter transaction ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(
                            context,
                          )?.transactionNumberRequired ??
                          'Transaction ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // File Upload Section
                Text(
                  AppLocalizations.of(context)?.uploadProof ??
                      'Upload Payment Proof *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();

                    // Show options to pick from gallery or camera
                    final source = await showDialog<ImageSource>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text(
                          AppLocalizations.of(context)?.selectSource ??
                              'Select Source',
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: Text(
                                AppLocalizations.of(context)?.gallery ??
                                    'Gallery',
                              ),
                              onTap: () =>
                                  Navigator.pop(context, ImageSource.gallery),
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: Text(
                                AppLocalizations.of(context)?.camera ??
                                    'Camera',
                              ),
                              onTap: () =>
                                  Navigator.pop(context, ImageSource.camera),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (source != null) {
                      final XFile? pickedFile = await picker.pickImage(
                        source: source,
                        imageQuality: 80,
                      );

                      if (pickedFile != null) {
                        setState(() {
                          selectedFile = pickedFile;
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedFile == null
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedFile == null
                              ? Icons.upload_file
                              : Icons.check_circle,
                          color: selectedFile == null
                              ? Colors.grey.shade600
                              : Colors.green.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFile == null
                                ? (AppLocalizations.of(context)?.tapToUpload ??
                                      'Tap to upload image/file')
                                : selectedFile!.name,
                            style: TextStyle(
                              color: selectedFile == null
                                  ? Colors.grey.shade600
                                  : Colors.green.shade700,
                              fontWeight: selectedFile == null
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (selectedFile != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                selectedFile = null;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
                if (selectedFile == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      AppLocalizations.of(context)?.fileRequired ??
                          'File is required',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          eButton(
            onPressed: isLoading
                ? null
                : () {
                    Navigator.pop(context);
                  },
            backgroundColor: Colors.white,
            context: context,
            text: AppLocalizations.of(context)?.cancel ?? 'Cancel',
            textColor: Colors.black,
          ),
          eButton(
            onPressed: isLoading || widget.tip.payoutRequested != true
                ? null
                : () async {
                    if (formKey.currentState!.validate() &&
                        selectedFile != null) {
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        Navigator.pop(context);
                        widget.onClearWallet(
                          widget.tip,
                          selectedFile,
                          transactionIdController.text.trim(),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    } else if (selectedFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                                  context,
                                )?.pleaseuploadpaymentproof ??
                                'Please upload payment proof',
                          ),
                          backgroundColor: Colors.red.shade600,
                        ),
                      );
                    }
                  },
            context: context,
            backgroundColor: Colors.blue.shade600,
            text: isLoading
                ? AppLocalizations.of(context)?.processing ?? 'Processing...'
                : AppLocalizations.of(context)?.confirm ?? 'Confirm',
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
