import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/unified_payout.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/unified_payout_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UnifiedWalletPage extends StatefulWidget {
  final String workerId;

  const UnifiedWalletPage({super.key, required this.workerId});

  @override
  State<UnifiedWalletPage> createState() => _UnifiedWalletPageState();
}

class _UnifiedWalletPageState extends State<UnifiedWalletPage> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlueTint,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.wallet,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.black45),
              onPressed: () async {
                setState(() => _isSyncing = true);
                try {
                  await UnifiedPayoutServices.syncExistingDataToUnifiedWallet(
                    widget.workerId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.walletSynced,
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${AppLocalizations.of(context)!.error}: $e',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isSyncing = false);
                  }
                }
              },
              tooltip: AppLocalizations.of(context)!.syncWallet,
            ),
        ],
      ),
      body: StreamBuilder<UnifiedWalletModel>(
        stream: UnifiedPayoutServices.getUnifiedWalletStream(widget.workerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Loader(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    '${AppLocalizations.of(context)!.error}: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final wallet = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              await UnifiedPayoutServices.syncExistingDataToUnifiedWallet(
                widget.workerId,
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalBalanceCard(wallet),
                  const SizedBox(height: 24),
                  _buildBreakdownSection(wallet),
                  const SizedBox(height: 24),
                  _buildPayoutRequestSection(wallet),
                  const SizedBox(height: 24),
                  _buildRecentPayoutsSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalBalanceCard(UnifiedWalletModel wallet) {
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.availableBalance,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('MMM dd', locale).format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                AppLocalizations.of(context)!.sar,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                (wallet.totalAvailableBalance ?? 0.0).toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.lifetimeEarnings,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(wallet.lifetimeTotal ?? 0.0).toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.trending_up, color: Colors.white.withOpacity(0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(UnifiedWalletModel wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.balanceBreakdown,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildBreakdownCard(
          title: AppLocalizations.of(context)!.tips,
          available: wallet.cardTips ?? 0.0,
          total: wallet.totalTips ?? 0.0,
          paid: wallet.paidTips ?? 0.0,
          icon: Icons.star_rounded,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildBreakdownCard(
          title: AppLocalizations.of(context)!.bonus,
          available: wallet.availableBonus ?? 0.0,
          total: wallet.totalBonus ?? 0.0,
          paid: wallet.paidBonus ?? 0.0,
          icon: Icons.card_giftcard_rounded,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        // Earnings info card (display only, not payoutable)
        _buildEarningsInfoCard(wallet),
      ],
    );
  }

  /// Builds an informational card showing earnings breakdown (in-app vs outside-app)
  /// These are NOT included in the payout-requestable balance
  Widget _buildEarningsInfoCard(UnifiedWalletModel wallet) {
    final inApp = wallet.inAppEarnings ?? 0.0;
    final outsideApp = wallet.outsideAppEarnings ?? 0.0;
    final totalEarnings = wallet.totalCompletionAmount ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.totalEarnings,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.earningsInfoOnly,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn(
                label: AppLocalizations.of(context)!.throughApp,
                amount: inApp,
                color: Colors.blue,
              ),
              _buildAmountColumn(
                label: AppLocalizations.of(context)!.outsideApp,
                amount: outsideApp,
                color: Colors.teal,
              ),
              _buildAmountColumn(
                label: AppLocalizations.of(context)!.total,
                amount: totalEarnings,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard({
    required String title,
    required double available,
    required double total,
    required double paid,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn(
                label: AppLocalizations.of(context)!.available,
                amount: available,
                color: Colors.green,
              ),
              _buildAmountColumn(
                label: AppLocalizations.of(context)!.total,
                amount: total,
                color: AppColors.primary,
              ),
              _buildAmountColumn(
                label: AppLocalizations.of(context)!.paid,
                amount: paid,
                color: Colors.black38,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          "${amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutRequestSection(UnifiedWalletModel wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.requestPayout,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (wallet.payoutRequested == true) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.payoutPending,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(wallet.requestedAmount ?? 0.0).toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (wallet.totalAvailableBalance ?? 0.0) > 0
                    ? () async {
                        // Check minimum balance
                        if ((wallet.totalAvailableBalance ?? 0.0) < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.minimumPayoutAmount,
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        // Check if worker has payout account
                        final worker = await AppServices.getWorkerById(
                          widget.workerId,
                        );
                        if (worker.payoutAccounts == null ||
                            worker.payoutAccounts!.isEmpty) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.noPayoutAccountsAdded,
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        // All checks passed, show dialog
                        _showPayoutRequestDialog(wallet);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.black12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.requestPayout,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppLocalizations.of(context)!.payoutNote,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black26,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentPayoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.payoutHistory,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<UnifiedPayoutRequestModel>>(
          stream: UnifiedPayoutServices.getWorkerPayoutRequests(
            widget.workerId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Loader(color: AppColors.primary));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: Colors.black.withOpacity(0.05),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noPayoutRequests,
                        style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            }

            final requests = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length > 10 ? 10 : requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildPayoutRequestCard(request);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPayoutRequestCard(UnifiedPayoutRequestModel request) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case 'P':
        statusColor = Colors.orange;
        statusText = AppLocalizations.of(context)!.pending;
        statusIcon = Icons.schedule_rounded;
        break;
      case 'A':
        statusColor = Colors.green;
        statusText = AppLocalizations.of(context)!.approved;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'R':
        statusColor = Colors.red;
        statusText = AppLocalizations.of(context)!.rejected;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(request.totalAmount ?? 0.0).toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRequestAmountChip(
                  label: AppLocalizations.of(context)!.tips,
                  amount: request.tipsAmount ?? 0.0,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRequestAmountChip(
                  label: AppLocalizations.of(context)!.bonus,
                  amount: request.bonusAmount ?? 0.0,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRequestAmountChip(
                  label: AppLocalizations.of(context)!.inAppEarnings,
                  amount: request.earningsAmount ?? 0.0,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatPayoutDate(
                  request.createdAt?.toDate() ?? DateTime.now(),
                  context,
                ),
                style: TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500),
              ),
              if (request.status == 'P')
                InkWell(
                  onTap: () => _cancelPayoutRequest(request.id!, context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (request.status == 'R' && request.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context)!.reason}: ${request.rejectionReason}',
                      style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestAmountChip({
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPayoutDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    // Format: dd - MM - yyyy, hh:mm a (e.g., "25 - 12 - 2025, 10:34 pm")
    final formatter = DateFormat('dd-MM-yyy, hh:mm a', locale);
    return formatter.format(date);
  }

  void _showPayoutRequestDialog(UnifiedWalletModel wallet) {
    final tipsAmount = wallet.cardTips ?? 0.0;
    final bonusAmount = wallet.availableBonus ?? 0.0;
    final earningsAmount = wallet.inAppEarnings ?? 0.0;
    final totalAmount = tipsAmount + bonusAmount + earningsAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.confirmPayoutRequest,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.reviewPayoutDetails,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildDialogAmountCard(
                            label: AppLocalizations.of(context)!.tips,
                            amount: tipsAmount,
                            icon: Icons.star_rounded,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogAmountCard(
                            label: AppLocalizations.of(context)!.bonus,
                            amount: bonusAmount,
                            icon: Icons.card_giftcard_rounded,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogAmountCard(
                            label: AppLocalizations.of(context)!.inAppEarnings,
                            amount: earningsAmount,
                            icon: Icons.account_balance_rounded,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.bgBlueTint,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.totalPayoutAmount,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black45,
                                  ),
                                ),
                                Text(
                                  '${totalAmount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.payoutNote,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => Navigator.pop(dialogContext),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          setDialogState(() => isLoading = true);

                                          String? errorMessage;
                                          bool success = false;

                                          try {
                                            await UnifiedPayoutServices.requestUnifiedPayout(
                                              workerId: widget.workerId,
                                              tipsAmount: tipsAmount,
                                              bonusAmount: bonusAmount,
                                              earningsAmount: earningsAmount,
                                            );
                                            success = true;
                                          } catch (e) {
                                            errorMessage = e.toString();
                                          } finally {
                                            if (dialogContext.mounted) {
                                              setDialogState(() => isLoading = false);
                                            }
                                          }

                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                          }

                                          if (mounted) {
                                            if (success) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(context)!.payoutRequestSuccessful,
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else if (errorMessage != null) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '${AppLocalizations.of(context)!.error}: $errorMessage',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(context)!.confirm,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogAmountCard({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgBlueTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelPayoutRequest(
    String requestId,
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgWhite,
        actionsAlignment: MainAxisAlignment.start,
        title: Text(AppLocalizations.of(context)!.confirmCancellation),
        content: Text(AppLocalizations.of(context)!.cancelPayoutConfirmation),
        actions: [
          eButton(
            onPressed: () => Navigator.pop(context, false),
            backgroundColor: AppColors.bgWhite,
            textColor: Colors.black,
            text: AppLocalizations.of(context)!.no,
            context: context,
          ),
          const SizedBox(width: 8),
          eButton(
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: Colors.red,
            textColor: Colors.white,
            text: AppLocalizations.of(context)!.yes,
            context: context,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UnifiedPayoutServices.cancelPayoutRequest(requestId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.payoutCancelled),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
