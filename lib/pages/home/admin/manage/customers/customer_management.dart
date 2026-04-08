import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

class CustomerInfo extends StatelessWidget {
  final CustomerModel customer;
  const CustomerInfo({super.key, required this.customer});

  static Color primary = AppColors.primary;
  static Color secondary = AppColors.secondary;
  static Color cardBackground = AppColors.bgWhite;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching phone call: $e');
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActionsCard(context),
                  const SizedBox(height: 16),
                  _buildPersonalInfoCard(context),

                  const SizedBox(height: 16),
                  _buildSystemInfoCard(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(AppLocalizations.of(context)!.customerInfo),
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Hero(
                  tag: 'customer_${customer.uid}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.bgWhite,

                      child: Text(
                        customer.name?.isNotEmpty == true
                            ? customer.name![0].toUpperCase()
                            : 'A',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  customer.name ?? 'Unknown customer',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (customer.isBlocked == true)
                      _buildBadge(
                        AppLocalizations.of(context)!.blocked,
                        Icons.block,
                        Colors.red,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.quickActions,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (customer.phone != null && customer.phone!.isNotEmpty)
                  _buildQuickActionButton(
                    context,
                    Icons.phone,
                    AppLocalizations.of(context)!.call,
                    Colors.green,
                    () => _makePhoneCall(customer.phone!),
                  ),
                if (customer.email != null && customer.email!.isNotEmpty)
                  _buildQuickActionButton(
                    context,
                    Icons.email,
                    AppLocalizations.of(context)!.email,
                    Colors.blue,
                    () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: customer.email,
                      );
                      try {
                        await launchUrl(
                          emailUri,
                          mode: LaunchMode.platformDefault,
                        );
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error launching email: $e');
                        }
                      }
                    },
                  ),
                _buildQuickActionButton(
                  context,
                  Icons.copy,
                  AppLocalizations.of(context)!.copyId,
                  Colors.purple,
                  () => _copyToClipboard(context, customer.uid, 'User ID'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person, color: primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.personalInformation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoRow(
              context,
              Icons.badge_outlined,
              AppLocalizations.of(context)!.name,
              customer.name,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.email_outlined,
              AppLocalizations.of(context)!.email,
              customer.email,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              isPhone: true,
              context,
              Icons.phone_outlined,
              AppLocalizations.of(context)!.phone,
              customer.phone,
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.location_city_outlined,
              AppLocalizations.of(context)!.location,
              customer.location?.fullAddress ?? "-",
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.language,
              AppLocalizations.of(context)!.languageCode,
              customer.lanCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.systemInformation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernInfoRow(
              context,
              Icons.fingerprint,
              AppLocalizations.of(context)!.userId,
              customer.uid,
              trailing: IconButton(
                icon: Icon(Icons.copy, color: secondary, size: 18),
                onPressed: () =>
                    _copyToClipboard(context, customer.uid, 'User ID'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.calendar_today,
              AppLocalizations.of(context)!.createdAt,
              _formatTimestamp(customer.createdAt, context),
            ),
            _buildDivider(),
            _buildModernInfoRow(
              context,
              Icons.update,
              AppLocalizations.of(context)!.updatedAt,
              _formatTimestamp(customer.updatedAt, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value, {
    bool isPhone = false,
    Widget? trailing,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                isPhone
                    ? Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[300], height: 1, thickness: 1);
  }

  String? _formatTimestamp(Timestamp? timestamp, BuildContext context) {
    if (timestamp == null) return null;
    final date = timestamp.toDate();
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd/MM/yyyy hh:mm a', locale).format(date);
  }
}
