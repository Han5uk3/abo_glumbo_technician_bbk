import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

class CustomerInfo extends StatelessWidget {
  final CustomerModel customer;
  const CustomerInfo({super.key, required this.customer});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final number = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri.parse('https://wa.me/$number');
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: Text(
          AppLocalizations.of(context)!.customerInfo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildPersonalInfo(context),
            const SizedBox(height: 20),
            _buildSystemInfo(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'customer_${customer.uid}',
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image:
                  customer.profileUrl != null && customer.profileUrl!.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(customer.profileUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: customer.profileUrl == null || customer.profileUrl!.isEmpty
                ? Center(
                    child: Text(
                      customer.name?.isNotEmpty == true
                          ? customer.name![0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                customer.name ?? 'Unknown Customer',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (customer.isBlocked == true) ...[
          const SizedBox(height: 8),
          _buildStatusBadge(
            context,
            AppLocalizations.of(context)!.blocked,
            Colors.red,
          ),
        ],
        const SizedBox(height: 16),
        Divider(
          color: Colors.grey.shade300,
          thickness: 1,
          indent: 24,
          endIndent: 24,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return _buildCard(
      context,
      title: AppLocalizations.of(context)!.quickActions,
      icon: Icons.flash_on_outlined,
      iconColor: Colors.orange.shade700,
      children: [
        Row(
          children: [
            if (customer.phone?.isNotEmpty == true)
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.phone_outlined,
                  label: AppLocalizations.of(context)!.call,
                  color: Colors.green,
                  onTap: () => _makePhoneCall(customer.phone!),
                ),
              ),
            if (customer.phone?.isNotEmpty == true) const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.copy_outlined,
                label: AppLocalizations.of(context)!.copyId,
                color: Colors.blue,
                onTap: () => _copyToClipboard(
                  context,
                  customer.uid,
                  AppLocalizations.of(context)!.userId,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                imageAsset: 'assets/images/whatsapp.png',
                label: AppLocalizations.of(context)!.whatsapp,
                color: const Color(0xFF25D366),
                onTap: () {
                  if (customer.phone?.isNotEmpty == true) {
                    _launchWhatsApp(customer.phone!);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    IconData? icon,
    String? imageAsset,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              if (imageAsset != null)
                Image.asset(imageAsset, width: 24, height: 24)
              else if (icon != null)
                Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(BuildContext context) {
    return _buildCard(
      context,
      title: AppLocalizations.of(context)!.personalInformation,
      icon: Icons.person_outline,
      iconColor: Colors.blue.shade700,
      children: [
        _buildDetailRow(
          AppLocalizations.of(context)!.name,
          customer.name ?? 'N/A',
          false,
        ),
        _buildDetailRow(
          AppLocalizations.of(context)!.email,
          customer.email ?? 'N/A',
          false,
        ),
        _buildDetailRow(
          AppLocalizations.of(context)!.phone,
          customer.phone ?? 'N/A',
          true,
        ),
        _buildDetailRow(
          AppLocalizations.of(context)!.location,
          customer.addresses
                  .firstWhere((element) => element.isSelected == true)
                  .streetName ??
              "",
          false,
        ),
      ],
    );
  }

  Widget _buildSystemInfo(BuildContext context) {
    return _buildCard(
      context,
      title: AppLocalizations.of(context)!.systemInformation,
      icon: Icons.info_outline,
      iconColor: Colors.grey.shade700,
      children: [
        _buildDetailRow(
          AppLocalizations.of(context)!.userId,
          customer.uid,
          false,
        ),
        _buildDetailRow(
          AppLocalizations.of(context)!.createdAt,
          _formatTimestamp(customer.createdAt, context) ?? 'N/A',
          false,
        ),
        _buildDetailRow(
          AppLocalizations.of(context)!.updatedAt,
          _formatTimestamp(customer.updatedAt, context) ?? 'N/A',
          false,
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
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
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isPhone, {
    Widget? trailing,
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
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child:
                trailing ??
                Text(
                  value,
                  textAlign: TextAlign.right,
                  textDirection: isPhone ? TextDirection.ltr : null,
                  style: DMSansFont.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  String? _formatTimestamp(Timestamp? timestamp, BuildContext context) {
    if (timestamp == null) return null;
    final date = timestamp.toDate();
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd/MM/yyyy hh:mm a', locale).format(date);
  }
}
