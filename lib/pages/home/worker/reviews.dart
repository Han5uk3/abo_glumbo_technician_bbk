import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:flutter/material.dart';

class WorkerReviewsPage extends StatefulWidget {
  final String workerId;

  const WorkerReviewsPage({super.key, required this.workerId});

  @override
  State<WorkerReviewsPage> createState() => _WorkerReviewsPageState();
}

class _WorkerReviewsPageState extends State<WorkerReviewsPage> {
  List<BookingModel> reviewedBookings = [];
  bool isLoading = true;
  double averageRating = 0.0;
  Map<int, int> ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => isLoading = true);

    try {
      // Query bookings where review field exists and agent.uid matches workerId
      final querySnapshot = await AppFirestore.bookingsCollectionRef
          .where('agent.uid', isEqualTo: widget.workerId)
          .where('bookingStatusCode', isEqualTo: 'C') // Completed bookings only
          .orderBy('completedAt', descending: true)
          .get();

      // Filter bookings that have reviews (review field is not null)
      reviewedBookings = querySnapshot.docs
          .map((doc) => BookingModel.fromQueryDocumentSnapshot(doc))
          .where((booking) => booking.review != null)
          .toList();

      _calculateStatistics();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorLoadingReviews}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _calculateStatistics() {
    if (reviewedBookings.isEmpty) return;

    // Reset distribution
    ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    // Calculate average and distribution
    double totalRating = 0;
    int validReviewCount = 0;

    for (var booking in reviewedBookings) {
      if (booking.review != null) {
        int rating = booking.review!.rating ?? 0;
        if (rating > 0 && rating <= 5) {
          totalRating += rating;
          validReviewCount++;
          ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
        }
      }
    }

    // Calculate average out of 5 (not out of total possible points)
    averageRating = validReviewCount > 0 ? totalRating / validReviewCount : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.reviews,
          style: DMSansFont.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
      ),
      body: isLoading
          ? Center(child: Loader(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: 16),
                    _buildRatingDistribution(),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.allReviews,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (reviewedBookings.isEmpty) ...[
                      const SizedBox(height: 20),
                      _buildEmptyState(),
                    ] else ...[
                      ...reviewedBookings.map((booking) => _buildReviewCard(booking)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noReviewsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(
              context,
            )!.reviewsWillAppearHereAfterCustomersRateYourService,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD45D), Color(0xFFF9A825)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.overallRating,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              _buildLargeStars(averageRating),
            ],
          ),
          const SizedBox(height: 12),
          // Dashed Divider
          Row(
            children: List.generate(
              50,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 0.8,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${reviewedBookings.length} ${reviewedBookings.length == 1 ? l10n.review : l10n.reviews}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData iconData;
        if (index < rating.floor()) {
          iconData = Icons.star_rounded;
        } else if (index < rating && rating % 1 != 0) {
          iconData = Icons.star_half_rounded;
        } else {
          iconData = Icons.star_border_rounded;
        }
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Icon(
            iconData,
            size: 24,
            color: Colors.white.withOpacity(0.85),
          ),
        );
      }),
    );
  }

  Widget _buildRatingDistribution() {
    final totalReviews = reviewedBookings.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(5, (index) {
          int starCount = 5 - index;
          int count = ratingDistribution[starCount] ?? 0;
          double percentage = totalReviews > 0 ? count / totalReviews : 0;

          return Padding(
            padding: EdgeInsets.only(bottom: index == 4 ? 0 : 10),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  child: Text(
                    '$starCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star_rounded, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD45D), Color(0xFFF9A825)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 30,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReviewCard(BookingModel booking) {
  final review = booking.review!;
  final customer = booking.customer;
  final rating = review.rating;
  final l10n = AppLocalizations.of(context)!;

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: customer.profileUrl != null
                  ? NetworkImage(customer.profileUrl!)
                  : null,
              child: customer.profileUrl == null
                  ? Text(
                      customer.name?.isNotEmpty == true
                          ? customer.name![0].toUpperCase()
                          : 'C',
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name ?? "Customer",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _buildStarRating(rating?.toDouble() ?? 0.0, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        _formatReviewTime(review.createdAt?.toDate()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (review.review.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            review.review,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 8),
        Text(
          '${l10n.service}: ${Directionality.of(context) == TextDirection.ltr ? '${booking.service.name}' : booking.service.name_ar}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[800],
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

String _formatReviewTime(DateTime? date) {
  if (date == null) return 'Recent';
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays >= 7) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
  } else if (difference.inDays >= 1) {
    return '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
  } else if (difference.inHours >= 1) {
    return '${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
  } else {
    return 'Just now';
  }
}

Widget _buildStarRating(double rating, {double size = 20, Color? color}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      if (index < rating.floor()) {
        return Icon(
          Icons.star_rounded,
          size: size,
          color: color ?? Colors.amber[600],
        );
      } else if (index < rating && rating % 1 != 0) {
        return Icon(
          Icons.star_half_rounded,
          size: size,
          color: color ?? Colors.amber[600],
        );
      } else {
        return Icon(
          Icons.star_border_rounded,
          size: size,
          color: color ?? Colors.grey[300],
        );
      }
    }),
  );
}
}
