import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AgentInfo extends StatefulWidget {
  final UserModel agent;
  final bool isMainAdmin;
  const AgentInfo({super.key, required this.agent, required this.isMainAdmin});

  @override
  State<AgentInfo> createState() => _AgentInfoState();
}

class _AgentInfoState extends State<AgentInfo> {
  UserModel get agent => widget.agent;

  Map<String, Map<String, String>> jobCategories = {};
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchJobCategories();
  }

  Future<void> _fetchJobCategories() async {
    try {
      final categories = await AppServices.fetchJobCategories();
      if (mounted) {
        setState(() {
          jobCategories = categories;
          isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching job categories: $e');
      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 16),
            _buildContactInfo(context),
            const Divider(height: 48, thickness: 1, indent: 24, endIndent: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfessionSection(context),
                  const SizedBox(height: 16),
                  _buildDocumentsSection(context),
                  const SizedBox(height: 16),
                  _buildEarningsSection(context),
                  const SizedBox(height: 16),
                  _buildBonusTierSection(context),
                  const SizedBox(height: 16),
                  _buildSystemInfoSection(context),
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
          tag: 'agent_${agent.uid}',
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              image: agent.profileUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(agent.profileUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: agent.profileUrl == null
                ? Center(
                    child: Text(
                      agent.name?.isNotEmpty == true
                          ? agent.name![0].toUpperCase()
                          : 'A',
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
            Text(
              agent.name ?? 'Technician',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (agent.isVerified == true) ...[
              const SizedBox(width: 8),
              _buildVerifiedBadge(context),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _buildStatsRow(context),
        const SizedBox(height: 4),
        _buildStatItem(
          Icons.attach_money,
          Colors.blue,
          'Earned SAR ${agent.paidAmounts ?? "0.00"}',
        ),
        const SizedBox(height: 8),
        Divider(
          color: Colors.grey.shade300,
          thickness: 1,
          indent: 24,
          endIndent: 24,
        ),
      ],
    );
  }

  Widget _buildVerifiedBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 14),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.of(context)!.verified,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem(
          Icons.star,
          Colors.orange,
          '${agent.rating ?? 0} (4 Reviews)',
        ),
        _buildStatSeparator(),
        _buildStatItem(
          Icons.check_circle_outline,
          Colors.green,
          '${agent.currentMonthJobs ?? 0} Completed Orders',
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildStatSeparator() {
    return Container(
      height: 12,
      width: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildContactRow(Icons.phone, agent.phone ?? 'N/A', Colors.green),
          const SizedBox(height: 12),
          _buildContactRow(Icons.email, agent.email ?? 'N/A', Colors.blue),
          const SizedBox(height: 12),
          _buildContactRow(
            Icons.location_on,
            agent.location?.fullAddress ?? 'N/A',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionSection(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    return _buildCard(
      context,
      title: 'Profession',
      icon: Icons.settings_outlined,
      iconColor: Colors.blue.shade700,
      children: [
        const Text(
          'Job Roles',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (agent.jobRoles ?? []).map((role) {
            return _buildPill(_getLocalizedJobCategory(role, currentLocale));
          }).toList(),
        ),
        if (agent.certifications != null &&
            agent.certifications!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Certifications',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...agent.certifications!.asMap().entries.map((entry) {
            int index = entry.key;
            String certUrl = entry.value;
            return _buildDocumentItem(
              label: '${AppLocalizations.of(context)!.document} ${index + 1}',
              onTap: () => _showFullScreenImage(certUrl, context),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    return _buildCard(
      context,
      title: 'ID & Documents',
      icon: Icons.check_outlined,
      iconColor: Colors.blue.shade700,
      children: [
        if (agent.docUrl != null)
          _buildDocumentItem(
            label: '${AppLocalizations.of(context)!.document} 1',
            onTap: () => _showFullScreenImage(agent.docUrl!, context),
          )
        else
          const Text(
            'No documents uploaded',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildEarningsSection(BuildContext context) {
    return _buildCard(
      context,
      title: 'Earnings Breakdown',
      icon: Icons.attach_money,
      iconColor: Colors.blue.shade700,
      children: [
        _buildDetailRow(
          'Service Earnings',
          'SAR ${agent.paidAmounts ?? "0.00"}',
        ),
        _buildDetailRow(
          'Bonuses',
          'SAR ${agent.bonusAmount ?? agent.totalMonthlyBonus ?? "0.00"}',
        ),
      ],
    );
  }

  Widget _buildBonusTierSection(BuildContext context) {
    return _buildCard(
      context,
      title: 'Bonus Tier',
      icon: Icons.card_giftcard,
      iconColor: Colors.blue.shade700,
      children: [
        Row(
          children: [
            const Icon(Icons.shield, color: Colors.brown, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                agent.tier ?? 'Bronze',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.brown,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${agent.totalMonthlyBonus != null && agent.totalMonthlyBonus! > 0 ? "5%" : "0%"} Bonus',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemInfoSection(BuildContext context) {
    return _buildCard(
      context,
      title: 'System info',
      icon: Icons.info_outline,
      iconColor: Colors.blue.shade700,
      children: [
        _buildDetailRow('User ID', agent.uid ?? 'N/A'),
        _buildDetailRow(
          'Created at',
          _formatTimestamp(agent.createdAt) ?? 'N/A',
        ),
        _buildDetailRow(
          'Updated at',
          _formatTimestamp(agent.updatedAt) ?? 'N/A',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.visible,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.visible,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem({
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: DMSansFont.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () {
          // Disapprove action
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Disapprove',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _showFullScreenImage(
    String imageUrl,
    BuildContext context,
  ) async {
    final ext = imageUrl.split('.').last.split('?').first.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

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
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Loader(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      await _openDocument(imageUrl, context);
    }
  }

  Future<void> _openDocument(String url, BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: Loader(color: Colors.white)),
      );

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final fileName = url.split('/').last.split('?').first;
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) Navigator.of(context).pop();
        await OpenFilex.open(file.path);
      } else {
        if (context.mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        String fileName = Uri.decodeComponent(segments.last);
        if (fileName.length > 40)
          fileName = fileName.substring(fileName.length - 40);
        return fileName;
      }
    } catch (_) {}
    return 'Document';
  }

  String _getLocalizedJobCategory(String jobKey, String locale) {
    if (jobCategories.containsKey(jobKey)) {
      return jobCategories[jobKey]![locale] ?? jobKey;
    }
    for (var entry in jobCategories.entries) {
      if (entry.value['en'] == jobKey || entry.value['ar'] == jobKey) {
        return entry.value[locale] ?? jobKey;
      }
    }
    return jobKey;
  }

  String? _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return null;
    final date = timestamp.toDate();
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd/MM/yyyy hh:mm a', locale).format(date);
  }
}
