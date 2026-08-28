import 'package:aboglumbo_bbk_panel/common_widget/cached_async_builder.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

class RewardsPage extends StatefulWidget {
  final UserModel workerData;
  const RewardsPage({super.key, required this.workerData});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  // Job counts each tier requires. These must match `TIER_*_JOBS` in
  // `functions/index.js`, which is what actually decides a worker's tier —
  // showing a worker a target the server does not use is worse than showing
  // none, so change both together.
  static const int _silverJobs = 10;
  static const int _goldJobs = 12;
  static const int _platinumJobs = 60;

  int totalJobsCount = 0;
  double currentRating = 0.0;
  String currentTier = 'Bronze';
  double bonusAmount = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRewardsData();
  }

  Future<void> _fetchRewardsData() async {
    try {
      String uid = LocalStore.getUID() ?? "";
      final userDoc = await AppFirestore.usersCollectionRef.doc(uid).get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data() as Map<String, dynamic>?;
        setState(() {
          totalJobsCount = _toInt(data?['currentMonthJobs']);
          final ratingSum = _toDouble(data?['rating']);
          final reviewCount = _toInt(data?['reviewCount']);
          currentRating = reviewCount > 0 ? ratingSum / reviewCount : 0.0;
          currentTier = data?['tier'] ?? 'Bronze';
          bonusAmount = _toDouble(data?['bonusAmount']);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching rewards data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)!.rewards,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
      ),
      body: isLoading
          ? Center(child: Loader())
          : RefreshIndicator(
              onRefresh: _fetchRewardsData,
              child: CustomScrollView(
                slivers: [
                  // Bonus Payout Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: _buildBonusPayoutCard(),
                    ),
                  ),

                  // Current Tier Info Card (Contains Tier System Expansion)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: _buildCurrentTierCard(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentTierCard() {
    final l10n = AppLocalizations.of(context)!;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getTierProgressColor(currentTier).withOpacity(0.03),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getTierIcon(currentTier),
                      color: _getTierProgressColor(currentTier),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTierName(currentTier),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTierProgressColor(currentTier),
                      ),
                    ),
                  ],
                ),
                Text(
                  _getTierBenefit(currentTier).split(' ').first,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 3 Stats Boxes
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactVerticalStat(
                        Icons.check_rounded,
                        totalJobsCount.toString(),
                        l10n.jobs,
                        const Color(0xFF0D47A1),
                        const Color(0xFFE3F2FD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactVerticalStat(
                        Icons.star_rounded,
                        currentRating.toStringAsFixed(1),
                        l10n.rating,
                        const Color(0xFFFBC02D),
                        const Color(0xFFFFF9C4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactVerticalStat(
                        Icons.card_giftcard_rounded,
                        bonusAmount.toStringAsFixed(2),
                        l10n.lastBonus,
                        const Color(0xFF00C853),
                        const Color(0xFFE8F5E9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sub-caption
                Text(
                  l10n.progressResetsMonthlyDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),

          // Expansion Tile for Tier System
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              iconColor: AppColors.primary,
              collapsedIconColor: AppColors.primary,
              title: Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.tierSystem,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              children: [
                _buildPremiumTierCard(
                  'Bronze',
                  l10n.greaterThan3dot5rating,
                  l10n.zeroPercentBonus,
                  const Color(0xFF831717),
                ),
                _buildPremiumTierCard(
                  'Silver',
                  '${l10n.tierJobsRequirement(_silverJobs)}, ${l10n.greaterThan4dot0rating}',
                  l10n.fivepercentBonusOnly,
                  const Color(0xFF64748B),
                ),
                _buildPremiumTierCard(
                  'Gold',
                  '${l10n.tierJobsRequirement(_goldJobs)}, ${l10n.greaterThan4dot5rating}',
                  l10n.tenpercentBonusOnly,
                  const Color(0xFFD97706),
                ),
                _buildPremiumTierCard(
                  'Platinum',
                  '${l10n.tierJobsRequirement(_platinumJobs)}, ${l10n.greaterThan4dot8rating}',
                  l10n.fifteenpercentBonusOnly,
                  const Color(0xFF6366F1),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.bonusCalculationNote,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVerticalStat(
    IconData icon,
    String value,
    String label,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor.withOpacity(0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTierCard(
    String tierName,
    String criteria,
    String reward,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getTierIconByName(tierName), size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTierName(tierName),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  criteria,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            reward.split(' ').first,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getTierBenefit(String tier) {
    final l10n = AppLocalizations.of(context)!;
    switch (tier) {
      case 'Platinum':
        return l10n.fifteenpercentBonusOnly;
      case 'Gold':
        return l10n.tenpercentBonusOnly;
      case 'Silver':
        return l10n.fivepercentBonusOnly;
      default:
        return l10n.zeroPercentBonus;
    }
  }

  Color _getTierProgressColor(String tier) {
    switch (tier) {
      case 'Platinum':
        return const Color(0xFF6366F1);
      case 'Gold':
        return const Color(0xFFD97706);
      case 'Silver':
        return const Color(0xFF64748B);
      case 'Bronze':
        return const Color(0xFF831717);
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'Platinum':
        return Icons.military_tech;
      case 'Gold':
        return Icons.workspace_premium;
      case 'Silver':
        return Icons.star;
      case 'Bronze':
        return Icons.shield;
      default:
        return Icons.shield;
    }
  }

  IconData _getTierIconByName(String tierName) {
    switch (tierName) {
      case 'Platinum':
        return Icons.military_tech;
      case 'Gold':
        return Icons.workspace_premium;
      case 'Silver':
        return Icons.star;
      case 'Bronze':
        return Icons.shield;
      default:
        return Icons.shield;
    }
  }

  String _getTierName(String tier) {
    final l10n = AppLocalizations.of(context)!;
    switch (tier) {
      case 'Platinum':
        return l10n.platinum;
      case 'Gold':
        return l10n.gold;
      case 'Silver':
        return l10n.silver;
      case 'Bronze':
        return l10n.bronze;
      default:
        return l10n.bronze;
    }
  }

  Widget _buildBonusPayoutCard() {
    return CachedFutureBuilder<double>(
      create: () => AppServices.getWorkerBonusAmounts(widget.workerData.uid!),
      keys: [widget.workerData.uid],
      builder: (context, snapshot) {
        final totalMonthlyBonus = snapshot.data ?? 0.0;
        final l10n = AppLocalizations.of(context)!;

        const Color darkGreen = Color(0xFF007A33);
        const Color midGreen = Color(0xFF10A453);

        return Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [darkGreen, midGreen, darkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/images/walletbgpattern.png",
                    fit: BoxFit.fill,
                    color: Colors.black,
                    opacity: const AlwaysStoppedAnimation(0.1),
                    colorBlendMode: BlendMode.dstIn,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bonusEarned,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            totalMonthlyBonus.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,

                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.sar,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        40,
                        (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 1,
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.bonusCardDesc,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
