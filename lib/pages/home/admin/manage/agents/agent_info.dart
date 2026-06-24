import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
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
import 'package:aboglumbo_bbk_panel/services/unified_payout_services.dart';

class AgentInfo extends StatefulWidget {
  final UserModel agent;
  final bool isMainAdmin;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? initialInAppEarnings;
  final double? initialOutsideAppEarnings;

  const AgentInfo({
    super.key,
    required this.agent,
    required this.isMainAdmin,
    this.startDate,
    this.endDate,
    this.initialInAppEarnings,
    this.initialOutsideAppEarnings,
  });

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
          child: GestureDetector(
            onTap: () {
              if (agent.profileUrl != null) {
                _showFullScreenImage(agent.profileUrl!, context);
              }
            },
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
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              agent.name ??
                  AppLocalizations.of(context)?.technician ??
                  'Technician',
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
          Icons.money_outlined,
          Colors.blue,
          '${AppLocalizations.of(context)?.earnings ?? "Earned"} ${agent.paidAmounts ?? "0.00"} ${AppLocalizations.of(context)!.sar}',
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
          '${agent.rating ?? 0.0} (${agent.reviewCount ?? 0} ${AppLocalizations.of(context)?.reviews ?? "Reviews"})',
        ),
        _buildStatSeparator(),
        _buildStatItem(
          Icons.check_circle_outline,
          Colors.green,
          '${agent.currentMonthJobs ?? 0} ${AppLocalizations.of(context)?.completedOrders ?? "Completed Orders"}',
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
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      context,
      title: l10n.profession ?? 'Profession',
      icon: Icons.settings_outlined,
      iconColor: Colors.blue.shade700,
      children: [
        Text(
          l10n.jobRoles ?? 'Job Roles',
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
          Text(
            l10n.certifications,
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
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      context,
      title: l10n.idAndDocuments,
      icon: Icons.check_outlined,
      iconColor: Colors.blue.shade700,
      children: [
        if (agent.docUrl != null)
          _buildDocumentItem(
            label: '${l10n.document} 1',
            onTap: () => _showFullScreenImage(agent.docUrl!, context),
          ),
        if (agent.residenceIdUrl != null)
          _buildDocumentItem(
            label: l10n.residenceIDImage,
            onTap: () => _showFullScreenImage(agent.residenceIdUrl!, context),
          ),
        if (agent.sponsorWorkPermitUrl != null)
          _buildDocumentItem(
            label: l10n.sponsorWorkPermit,
            onTap: () =>
                _showFullScreenImage(agent.sponsorWorkPermitUrl!, context),
          ),
        if (agent.chamberOfCommerceApprovalUrl != null)
          _buildDocumentItem(
            label: l10n.chamberOfCommerceApproval,
            onTap: () => _showFullScreenImage(
              agent.chamberOfCommerceApprovalUrl!,
              context,
            ),
          ),
        if (agent.docUrl == null &&
            agent.residenceIdUrl == null &&
            agent.sponsorWorkPermitUrl == null &&
            agent.chamberOfCommerceApprovalUrl == null)
          Text(
            l10n.noDocumentsUploaded,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildEarningsSection(BuildContext context) {
    final hasFilter = widget.startDate != null || widget.endDate != null;
    final hasFullAccess =
        LocalStore.getCachedAdminData()?.hasFullAccess ?? true;
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      context,
      title: l10n.earningsBreakdown ?? 'Earnings Breakdown',
      icon: Icons.attach_money,
      iconColor: Colors.blue.shade700,
      children: [
        if (hasFilter) ...[
          if (widget.startDate != null && widget.endDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "${AppLocalizations.of(context)?.filteredBy ?? 'Filtered:'} ${DateFormat('dd/MM/yyyy').format(widget.startDate!)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate!)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _buildDetailRow(
            l10n.inAppEarnings ?? 'In-App Earnings',
            'SAR ${(widget.initialInAppEarnings ?? 0.0).toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            l10n.outsideAppEarnings ?? 'Outside-App Earnings',
            'SAR ${(widget.initialOutsideAppEarnings ?? 0.0).toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
        ],
        _buildDetailRow(
          l10n.totalEarnings ?? 'Service Earnings (Total)',
          'SAR ${agent.paidAmounts ?? "0.00"}',
        ),
        _buildDetailRow(
          l10n.bonuses ?? 'Bonuses',
          'SAR ${agent.bonusAmount ?? agent.totalMonthlyBonus ?? "0.00"}',
        ),
        if (hasFullAccess) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _confirmClearWallet(context),
              icon: const Icon(Icons.delete_sweep, size: 20),
              label: Text(
                AppLocalizations.of(context)!.clearWalletBalances,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBonusTierSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      context,
      title: l10n.bonusTier ?? 'Bonus Tier',
      icon: Icons.card_giftcard,
      iconColor: Colors.blue.shade700,
      children: [
        Row(
          children: [
            const Icon(Icons.shield, color: Colors.brown, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getLocalizedTier(agent.tier, l10n),
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
              '${agent.totalMonthlyBonus != null && agent.totalMonthlyBonus! > 0 ? "5%" : "0%"} ${AppLocalizations.of(context)?.bonus ?? "Bonus"}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemInfoSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildCard(
      context,
      title: l10n.systemInfo,
      icon: Icons.info_outline,
      iconColor: Colors.blue.shade700,
      children: [
        _buildDetailRow(l10n.userId, agent.uid ?? 'N/A'),
        _buildDetailRow(
          l10n.createdAt,
          _formatTimestamp(agent.createdAt) ?? 'N/A',
        ),
        _buildDetailRow(
          l10n.updatedAt,
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
    final hasFullAccess =
        LocalStore.getCachedAdminData()?.hasFullAccess ?? true;
    if (!hasFullAccess) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (agent.isVerified != true) ...[
          if (agent.isDocsPendingReview == true) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => _handleApproveReject(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.approveAgent,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () => _handleApproveReject(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.reject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      agent.rejectionReason != null
                          ? AppLocalizations.of(
                                  context,
                                )?.waitingForTechnicianVerification ??
                                "Waiting for technician to re-upload documents"
                          : AppLocalizations.of(
                                  context,
                                )?.pleaseWaitAccountVerification ??
                                "Waiting for technician to complete registration",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _handleBlockUnblock(!(agent.isBlocked ?? false)),
              style: ElevatedButton.styleFrom(
                backgroundColor: agent.isBlocked == true
                    ? Colors.green
                    : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                agent.isBlocked == true ? l10n.unblock : l10n.block,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleBlockUnblock(bool isBlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isBlocked
              ? AppLocalizations.of(context)?.suspendAccount ??
                    "Block Technician"
              : AppLocalizations.of(context)?.unblockAccount ??
                    "Unblock Technician",
        ),
        content: Text(
          isBlocked
              ? AppLocalizations.of(
                      context,
                    )?.areYouSureYouWantToSuspendThisAccount ??
                    "Are you sure you want to block this technician?"
              : AppLocalizations.of(
                      context,
                    )?.areYouSureYouWantToUnblockThisAccount ??
                    "Are you sure you want to unblock this technician?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)?.cancelLower ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isBlocked
                  ? AppLocalizations.of(context)?.block ?? "Block"
                  : AppLocalizations.of(context)?.unblock ?? "Unblock",
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: Loader()),
      );

      try {
        final success = await AppServices.blockOrUnblockAgent(
          agent.uid!,
          isBlocked,
        );
        if (mounted) Navigator.pop(context); // Close loader

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isBlocked
                      ? AppLocalizations.of(context)?.accountSuspended ??
                            "Technician Blocked"
                      : AppLocalizations.of(context)?.accountUnblocked ??
                            "Technician Unblocked",
                ),
                backgroundColor: isBlocked ? Colors.red : Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.errorOccurred(e.toString()) ??
                    'Error: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleApproveReject(bool isVerified) async {
    final l10n = AppLocalizations.of(context)!;
    String? rejectionReason;

    if (!isVerified) {
      rejectionReason = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          String? errorText;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(l10n.rejectionReason),
                content: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: l10n.enterReasonForReject,
                    errorText: errorText,
                  ),
                  maxLines: 3,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        setState(() {
                          errorText = l10n.pleaseProvideARejectionReason;
                        });
                      } else {
                        Navigator.pop(context, text);
                      }
                    },
                    child: Text(l10n.reject),
                  ),
                ],
              );
            },
          );
        },
      );

      if (rejectionReason == null) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.approveAgent,
            style: DMSansFont.textStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            l10n.areYouSureYouWantToApproveThisAgent,
            style: DMSansFont.textStyle(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n.approve,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: Loader()),
    );

    try {
      final success = await AppServices.approveOrRejectAgent(
        agent.uid!,
        isVerified,
        rejectionReason: rejectionReason,
      );

      if (mounted) Navigator.pop(context); // Close loader

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isVerified ? l10n.agentApproved : l10n.agentDisapproved,
              ),
              backgroundColor: isVerified ? Colors.green : Colors.red,
            ),
          );
          Navigator.pop(context, true); // Go back with success flag
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedUpdateTechStatus),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.errorOccurred(e.toString()) ??
                  'Error: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showFullScreenImage(
    String imageUrl,
    BuildContext context,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: Loader(color: Colors.white)),
    );

    final ext = imageUrl.split('.').last.split('?').first.toLowerCase();
    final isImageExtension = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
    ].contains(ext);

    if (!isImageExtension) {
      if (context.mounted) Navigator.of(context).pop();
      await _openDocument(imageUrl, context);
      return;
    }

    // Even if it has an image extension, it might be a document (e.g. PDF)
    // due to previous upload issues where metadata was set incorrectly.
    // We check the actual file content by peeking at the first few bytes.
    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'Range': 'bytes=0-10'},
      );
      if (response.statusCode == 200 || response.statusCode == 206) {
        final bytes = response.bodyBytes;
        // Check for PDF magic number: %PDF (0x25 0x50 0x44 0x46)
        if (bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46) {
          if (context.mounted) Navigator.of(context).pop();
          await _openDocument(imageUrl, context);
          return;
        }
        // Check for ZIP/DOCX magic number: PK.. (0x50 0x4B 0x03 0x04)
        if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
          if (context.mounted) Navigator.of(context).pop();
          await _openDocument(imageUrl, context);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error peeking file content: $e');
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

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
                errorWidget: (context, url, error) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)?.failedToLoadImage ??
                            "Failed to load image",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
        final bytes = response.bodyBytes;

        // Determine extension by peeking at the actual downloaded bytes
        String ext = url.split('.').last.split('?').first.toLowerCase();

        if (bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46) {
          ext = 'pdf';
        } else if (bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
          ext = 'docx';
        } else {
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.contains('pdf')) {
            ext = 'pdf';
          } else if (contentType.contains('msword')) {
            ext = 'doc';
          } else if (contentType.contains('officedocument')) {
            ext = 'docx';
          }
        }

        final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) Navigator.of(context).pop();
        await OpenFilex.open(file.path);
      } else {
        if (context.mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      debugPrint('Error opening document: $e');
    }
  }

  String _getLocalizedJobCategory(String jobKey, String locale) {
    if (jobCategories.containsKey(jobKey)) {
      return jobCategories[jobKey]![locale] ??
          jobCategories[jobKey]!['en'] ??
          jobKey;
    }
    for (var entry in jobCategories.entries) {
      if (entry.value['en'] == jobKey ||
          entry.value['ar'] == jobKey ||
          entry.value['ur'] == jobKey) {
        return entry.value[locale] ?? entry.value['en'] ?? jobKey;
      }
    }
    return jobKey;
  }

  String _getLocalizedTier(String? tier, AppLocalizations l10n) {
    if (tier == null) return l10n.bronze ?? 'Bronze';
    final lowerTier = tier.toLowerCase();
    if (lowerTier == 'bronze') return l10n.bronze ?? 'Bronze';
    if (lowerTier == 'silver') return l10n.silver ?? 'Silver';
    if (lowerTier == 'gold') return l10n.gold ?? 'Gold';
    return tier;
  }

  String? _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return null;
    final date = timestamp.toDate();
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd/MM/yyyy hh:mm a', locale).format(date);
  }

  Future<void> _confirmClearWallet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearWalletBalances),
        content: Text(
          l10n.clearWalletConfirmation(agent.name ?? 'this technician'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.clearWallet),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: Loader()),
      );

      try {
        await UnifiedPayoutServices.clearWallet(agent.uid!);
        if (mounted) Navigator.pop(context); // Close loader

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.walletClearedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // Close loader
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorClearingWallet(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
