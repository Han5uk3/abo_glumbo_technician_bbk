import 'dart:async';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/reviews.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/rewards_page.dart';
import 'package:aboglumbo_bbk_panel/pages/home/worker/unified_wallet_page.dart';
import 'package:aboglumbo_bbk_panel/pages/notifications/notifications_page.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/common_widget/dashboard_stat_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_info.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel workerData;
  final Function(int tabIndex, {String? bookingStatus})? onNavigate;

  const DashboardScreen({super.key, required this.workerData, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<DashboardDataStream> _dashboardStream;
  late AppServices _appServices;
  bool _isRefreshing = false;

  late ValueNotifier<bool> _isOnlineNotifier;

  late Stream<int> _unreadCountStream;

  @override
  void initState() {
    super.initState();
    _appServices = AppServices();
    _dashboardStream = AppServices.getCompleteDashboardStreamWithRefresh(
      widget.workerData.uid ?? "",
      _appServices.dashboardRefreshTrigger,
    );
    _unreadCountStream = AppServices.getUnreadNotificationsCountStream();
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

  @override
  void dispose() {
    _appServices.disposeDashboardRefresh();
    _isOnlineNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: StreamBuilder<DashboardDataStream>(
        stream: _dashboardStream,
        builder: (context, dashboardSnapshot) {
          if (dashboardSnapshot.connectionState == ConnectionState.waiting ||
              !dashboardSnapshot.hasData) {
            return _buildLoadingState();
          }

          if (dashboardSnapshot.hasError) {
            return _buildErrorState(dashboardSnapshot.error.toString());
          }

          final data = dashboardSnapshot.data!;
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            displacement: 100,
            child: CustomScrollView(
              physics: ClampingScrollPhysics(),
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(child: _buildVerificationBanner()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildOnlineToggle(),
                        const SizedBox(height: 16),
                        _buildBalanceCard(data.stats),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  sliver: _buildStatsGrid(data.stats),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverToBoxAdapter(
                    child: _buildFullWidthStatCards(data.stats),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 85,
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      elevation: 0,
      pinned: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Pattern
              Image.asset(
                'assets/images/appbarbg.png',
                fit: BoxFit.fitHeight,
                repeat: ImageRepeat.repeat,
                color: Colors.white.withOpacity(0.3),
                colorBlendMode: BlendMode.dstIn,
              ),
              // User Info
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [
                      // Profile Image
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.grey,
                          backgroundImage: widget.workerData.profileUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.workerData.profileUrl!,
                                )
                              : null,
                          child: widget.workerData.profileUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.workerData.name ?? "-",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    widget.workerData.location?.fullAddress ??
                                        "-",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 70),
                      // Notification Icon
                      _buildNotificationIcon(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isOnlineNotifier,
      builder: (context, isOnline, child) {
        return Row(
          children: [
            Expanded(
              child: Text(
                isOnline
                    ? AppLocalizations.of(context)!.availableToWork
                    : AppLocalizations.of(context)!.notAvailableToWork,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.9,
              child: Switch.adaptive(
                value: isOnline,
                onChanged: _updateOnlineStatus,
                activeColor: Colors.green,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<int>(
      stream: _unreadCountStream,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                iconSize: 22,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NewNotificationsPage(),
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4848),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVerificationBanner() {
    if (widget.workerData.isVerified == true) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(color: Color(0xFFFFB347)),
      child: Text(
        AppLocalizations.of(context)!.profileSentForVerification,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic> stats) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UnifiedWalletPage(workerId: widget.workerData.uid ?? ""),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, AppColors.primary, Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  "assets/images/walletbgpattern.png",
                  fit: BoxFit.fill,
                  color: AppColors.primary,
                  opacity: const AlwaysStoppedAnimation(0.1),
                  colorBlendMode: BlendMode.colorBurn,
                ),
              ),
            ),
            // Semi-transparent Currency Icon
            PositionedDirectional(
              end: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.walletBalance,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.sar} ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        stats['availableBalance']?.toString() ?? "0.00",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Dotted Divider
                  Row(
                    children: List.generate(
                      40,
                      (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 1,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.lifetimeEarnings,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "${stats['paidAmounts']?.toString() ?? "0.00"} ${l10n.sar}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.asOf,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      delegate: SliverChildListDelegate([
        _buildCompactStatCard(
          l10n.pending,
          data['latest']?.toString() ?? '0',
          const Color(0xFFFF5C8E),
          Icons.calendar_today_rounded,
          () {
            if (widget.onNavigate != null) {
              widget.onNavigate!(1, bookingStatus: 'P');
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => Home(newIndex: 1)),
                (_) => false,
              );
            }
          },
        ),
        _buildCompactStatCard(
          l10n.accepted,
          data['accepted']?.toString() ?? '0',
          const Color(0xFFFFA03D),
          Icons.settings_suggest_rounded,
          () {
            if (widget.onNavigate != null) {
              widget.onNavigate!(1, bookingStatus: 'A');
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => Home(newIndex: 1, selectedFilter: "A"),
                ),
                (_) => false,
              );
            }
          },
        ),
        _buildCompactStatCard(
          l10n.paymentPending,
          data['paymentPending']?.toString() ?? '0',
          const Color(0xFF4AC367),
          Icons.attach_money_rounded,
          () {
            if (widget.onNavigate != null) {
              widget.onNavigate!(1, bookingStatus: 'CP');
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => Home(newIndex: 1, selectedFilter: "CP"),
                ),
                (_) => false,
              );
            }
          },
        ),
        _buildCompactStatCard(
          l10n.warrantyClaims,
          data['warrantyClaims']?.toString() ?? '0',
          const Color(0xFF4DBFFF),
          Icons.lightbulb_outline_rounded,
          () {
            if (widget.onNavigate != null) {
              widget.onNavigate!(2);
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => Home(newIndex: 2)),
                (_) => false,
              );
            }
          },
        ),
      ]),
    );
  }

  Widget _buildCompactStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return DashboardStatCard(
      label: label,
      value: value,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }

  Widget _buildFullWidthStatCards(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildActiveBookingCard(),
        _buildWideActionCard(
          l10n.overallRating,
          data['rating']?.toString() ?? '0.0',
          Icons.star_outline,
          const Color.fromARGB(255, 15, 7, 176),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  WorkerReviewsPage(workerId: widget.workerData.uid ?? ""),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildWideActionCard(
          l10n.rewards,
          null,
          Icons.card_giftcard_rounded,
          const Color.fromARGB(255, 15, 7, 176),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RewardsPage(workerData: widget.workerData),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, color: Color(0xFF991B1B), size: 14),
                const SizedBox(width: 4),
                Text(
                  l10n.bronze,
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveBookingCard() {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: BookingTrackerService().isTracking,
      builder: (context, isTracking, _) {
        if (!isTracking) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () async {
              final bookingId = BookingTrackerService().currentBookingId;
              if (bookingId != null && bookingId.isNotEmpty) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final doc = await AppFirestore.bookingsCollectionRef
                      .doc(bookingId)
                      .get();
                  if (context.mounted) {
                    Navigator.pop(context); // hide loading
                    if (doc.exists) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      final booking = BookingModel.fromMap(data);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingInfo(booking: booking, isAdmin: false),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.activeBooking,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.trackingStarted,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideActionCard(
    String label,
    String? value,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4338CA), size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
            const Spacer(),
            if (value != null)
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    debugPrint('🔄 Pull-to-refresh triggered');
    setState(() => _isRefreshing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _appServices.triggerDashboardRefresh();
      await _dashboardStream.first;
      debugPrint('✅ Refresh completed');
    } catch (e) {
      debugPrint('❌ Refresh error: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleRefresh,
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _isOnlineNotifier.value = isOnline;
      await AppFirestore.usersCollectionRef.doc(widget.workerData.uid).update({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline ? l10n.onlineStatusOn : l10n.onlineStatusOff,
            ),
            backgroundColor: isOnline ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      _isOnlineNotifier.value = !isOnline;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorUpdatingStatus),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

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
