import 'dart:async';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';

import 'package:aboglumbo_bbk_panel/models/user.dart';

import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/contact_bottom_sheet.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/unified_wallet_page.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/reviews.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/rewards_page.dart';
import 'package:aboglumbo_bbk_panel/pages/notifications/notifications_page.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.workerData});

  final UserModel workerData;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<DashboardDataStream> _dashboardStream;
  late AppServices _appServices;
  bool _isRefreshing = false;

  late ValueNotifier<bool> _isOnlineNotifier;

  @override
  void initState() {
    super.initState();
    _appServices = AppServices();
    _dashboardStream = AppServices.getCompleteDashboardStreamWithRefresh(
      widget.workerData.uid ?? "",
      _appServices.dashboardRefreshTrigger,
    );
    _isOnlineNotifier = ValueNotifier<bool>(
      widget.workerData.isOnline ?? false,
    );
    _listenToOnlineStatus();
  }

  void _listenToOnlineStatus() {
    AppServices.getUserStream(widget.workerData.uid ?? "").listen((userData) {
      if (mounted) {
        _isOnlineNotifier.value = userData?.isOnline ?? false;
      }
    });
  }

  /// Get rating quality text
  String _getRatingSubtitle(double rating) {
    final l10n = AppLocalizations.of(context)!;
    if (rating >= 4.5) return l10n.excellent;
    if (rating >= 3.5) return l10n.good;
    if (rating >= 2.5) return l10n.average;
    return l10n.poor;
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    debugPrint('🔄 Pull-to-refresh triggered');

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Add a small delay to ensure UI updates smoothly
      await Future.delayed(const Duration(milliseconds: 500));

      // Trigger manual refresh through the controller
      _appServices.triggerDashboardRefresh();

      // Wait for stream to emit new data
      await _dashboardStream.first;

      debugPrint('✅ Refresh completed');
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up refresh controller
    _appServices.disposeDashboardRefresh();
    _isOnlineNotifier.dispose(); // Don't forget to dispose

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: StreamBuilder<DashboardDataStream>(
          stream: _dashboardStream,
          builder: (context, dashboardSnapshot) {
            // Show loading if dashboard stream is not ready
            if (dashboardSnapshot.connectionState == ConnectionState.waiting ||
                !dashboardSnapshot.hasData) {
              return _buildLoadingState();
            }

            // Error state
            if (dashboardSnapshot.hasError) {
              return _buildErrorState(dashboardSnapshot.error.toString());
            }

            // Success state - only dashboard data, toggle has its own stream
            return _buildSuccessState(dashboardSnapshot.data!);
          },
        ),
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      elevation: 0,
      title: Text(AppLocalizations.of(context)!.dashboard),
      actions: [
        StreamBuilder<int>(
          stream: AppServices.getUnreadNotificationsCountStream(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewNotificationsPage(),
                    ),
                  ),
                ),
                // Badge showing unread count
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Build loading state with shimmer placeholders
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOnlineStatusShimmer(),
            const SizedBox(height: 16),
            _buildStatsShimmerSection(),
            const SizedBox(height: 16),
            _buildQuickActionsShimmer(),
            const SizedBox(height: 16),
            _buildStatShimmerCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatusShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildShimmerBox(width: 48, height: 48, borderRadius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 150, height: 16),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 200, height: 14),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildShimmerBox(width: 51, height: 31, borderRadius: 16),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.error,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build success state with all loaded data
  Widget _buildSuccessState(DashboardDataStream data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOnlineStatusCard(), // Has its own StreamBuilder
            const SizedBox(height: 16),
            _buildStatsSection(data.stats),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              width: MediaQuery.of(context).size.width,
              child: _buildEarningsCard(),
            ),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineStatusCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isOnlineNotifier,
      builder: (context, isOnline, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isOnline ? Colors.green : Colors.grey),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SwitchListTile.adaptive(
            title: Text(
              AppLocalizations.of(context)!.availabilityStatus,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              isOnline
                  ? AppLocalizations.of(context)!.youAreAvailableForRequests
                  : AppLocalizations.of(context)!.youAreCurrentlyUnavailable,
              style: TextStyle(color: const Color(0xFF64748B), fontSize: 14),
            ),
            // secondary: Container(
            //   padding: const EdgeInsets.all(12),
            //   decoration: BoxDecoration(
            //     color: (isOnline ? Colors.green : Colors.grey).withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Icon(
            //     isOnline ? Icons.check_circle : Icons.cancel,
            //     color: isOnline ? Colors.green : Colors.grey,
            //     size: 28,
            //   ),
            // ),
            value: isOnline,
            onChanged: _updateOnlineStatus,
            activeColor: Colors.green,
          ),
        );
      },
    );
  }

  /// Build stats section
  Widget _buildStatsSection(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;

    final stats = [
      _StatData(
        title: l10n.pending,
        subtitle: l10n.requests,
        value: data['latest']?.toString() ?? '0',
        icon: Icons.assignment_outlined,
        color: Colors.red,
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Home(newIndex: 1)),
          (_) => false,
        ),
      ),
      _StatData(
        title: AppLocalizations.of(context)!.accepted,
        subtitle: AppLocalizations.of(context)!.requests,
        value: data['accepted']?.toString() ?? '0',
        icon: Icons.assignment_turned_in,
        color: AppColors.secondary,
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => Home(newIndex: 1, selectedFilter: "A"),
          ),
          (_) => false,
        ),
      ),
      _StatData(
        title: l10n.paymentPending,
        subtitle: l10n.requests,
        value: data['paymentPending']?.toString() ?? '0',
        icon: Icons.monetization_on,
        color: Colors.teal,
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => Home(newIndex: 1, selectedFilter: "CP"),
          ),
          (_) => false,
        ),
      ),
      _StatData(
        title: l10n.completed,
        subtitle: l10n.requests,
        value: data['completed']?.toString() ?? '0',
        icon: Icons.check_circle_outline,
        color: Colors.green,
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => Home(newIndex: 1, selectedFilter: "C"),
          ),
          (_) => false,
        ),
      ),
      _StatData(
        title: l10n.warrantyClaims,
        subtitle: l10n.requests,
        value: data['warrantyClaims']?.toString() ?? '0',
        icon: Icons.verified_user_rounded,
        color: Colors.indigo,
        onTap: () => Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => Home(newIndex: 2)),
          (_) => false,
        ),
      ),
      _StatData(
        title: l10n.rating,
        subtitle: _getRatingSubtitle(
          double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
        ),
        value: data['rating']?.toString() ?? '0.0',
        icon: Icons.star,
        color: Color(0xFFFFD700),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WorkerReviewsPage(workerId: widget.workerData.uid ?? ""),
          ),
        ),
      ),
    ];

    return _buildStatsGrid(stats);
  }

  /// Build responsive stats grid
  Widget _buildStatsGrid(List<_StatData> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reorganize: First 2 cards (Pending & Accepted) in a row,
        // Second row (Payment Pending & Completed),
        // Third row (Warranty Claims & Rating)
        return Column(
          children: [
            // First row: Pending and Accepted
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(stats[0]), // Pending
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(stats[1]), // Accepted
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Second row: Payment Pending and Completed
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(stats[2]), // Payment Pending
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(stats[3]), // Completed
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Third row: Warranty Claims and Rating
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(stats[4]), // Warranty Claims
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(stats[5]), // Rating
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(_StatData data) {
    return Material(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      elevation: 1,
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: data.color.withOpacity(1)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 110,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: data.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(data.icon, color: data.color, size: 28),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: TextStyle(
                                color: data.color,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              data.subtitle,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  _AnimatedCounter(
                    value: data.value,
                    style: TextStyle(
                      color: data.color,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build earnings card
  Widget _buildEarningsCard() {
    return _buildActionButton(
      AppLocalizations.of(context)!.wallet,
      AppLocalizations.of(context)!.viewAndManageEarnings,
      Icons.wallet,
      Colors.deepPurple,
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UnifiedWalletPage(workerId: widget.workerData.uid ?? ""),
        ),
      ),
    );
  }

  /// Build quick actions grid
  Widget _buildQuickActionsGrid() {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isWide ? 1.4 : 1.2,
          children: [
            _buildActionButton(
              l10n.support,
              l10n.getHelpAnytime,
              Icons.support_agent_outlined,
              Colors.brown,
              () => showModalBottomSheet(
                context: context,
                builder: (_) => const ContactBottomSheet(),
              ),
            ),
            _buildActionButton(
              l10n.rewards,
              l10n.viewYourRewards,
              Icons.card_giftcard_outlined,
              Colors.orangeAccent,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RewardsPage(workerData: widget.workerData),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build action button
  Widget _buildActionButton(
    String label,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const Spacer(),
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== SHIMMER LOADING STATES ==========

  /// Build shimmer section for stats
  Widget _buildStatsShimmerSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Column(
            children: [
              // First row: New and Completed
              Row(
                children: [
                  Expanded(child: _buildStatShimmerCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatShimmerCard()),
                ],
              ),
              const SizedBox(height: 12),
              // Second row: Payment Pending and Rating
              Row(
                children: [
                  Expanded(child: _buildStatShimmerCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatShimmerCard()),
                ],
              ),
            ],
          );
        }

        // Mobile layout
        return Column(
          children: [
            // First row: New and Completed side by side
            Row(
              children: [
                Expanded(child: _buildStatShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildStatShimmerCard()),
              ],
            ),
            const SizedBox(height: 12),
            // Payment Pending - full width
            _buildStatShimmerCard(),
            const SizedBox(height: 12),
            // Rating - full width
            _buildStatShimmerCard(),
          ],
        );
      },
    );
  }

  /// Build quick actions shimmer
  Widget _buildQuickActionsShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isWide ? 1.4 : 1.2,
          children: [_buildActionShimmerCard(), _buildActionShimmerCard()],
        );
      },
    );
  }

  /// Build shimmer card for stat
  Widget _buildStatShimmerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(width: 40, height: 40, borderRadius: 12),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 100, height: 16),
                  const SizedBox(height: 4),
                  _buildShimmerBox(width: 60, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildShimmerBox(width: 80, height: 36),
        ],
      ),
    );
  }

  /// Build shimmer card for action button
  Widget _buildActionShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerBox(width: 44, height: 44, borderRadius: 12),
            const Spacer(),
            _buildShimmerBox(width: 100, height: 16),
            const SizedBox(height: 4),
            _buildShimmerBox(width: 80, height: 12),
          ],
        ),
      ),
    );
  }

  /// Build individual shimmer box
  Widget _buildShimmerBox({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Update online/offline status in Firestore
  Future<void> _updateOnlineStatus(bool isOnline) async {
    try {
      debugPrint('🔄 Updating online status to: $isOnline');

      // Optimistically update the UI immediately
      _isOnlineNotifier.value = isOnline;

      await AppFirestore.usersCollectionRef.doc(widget.workerData.uid).update({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Online status updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline
                  ? AppLocalizations.of(context)!.youAreNowOnline
                  : AppLocalizations.of(context)!.youAreNowOffline,
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: isOnline ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating online status: $e');

      // Revert on error
      _isOnlineNotifier.value = !isOnline;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorUpdatingStatus),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ========== DATA MODELS ==========

/// Dashboard data container

/// Stat card data model
class _StatData {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Animated counter widget for smooth number transitions
class _AnimatedCounter extends StatefulWidget {
  final String value;
  final TextStyle style;

  const _AnimatedCounter({required this.value, required this.style});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;
  double _currentValue = 0;
  bool _isDecimal = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _parseValue(widget.value);
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = _currentValue;
      _parseValue(widget.value);
      _controller.forward(from: 0);
    }
  }

  void _parseValue(String value) {
    final parsed = double.tryParse(value) ?? 0;
    _currentValue = parsed;
    _isDecimal = value.contains('.');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedValue =
            _previousValue +
            (_currentValue - _previousValue) * _animation.value;
        final displayValue = _isDecimal
            ? animatedValue.toStringAsFixed(1)
            : animatedValue.round().toString();
        return Text(displayValue, style: widget.style);
      },
    );
  }
}
