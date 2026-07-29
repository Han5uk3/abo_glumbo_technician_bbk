import 'package:aboglumbo_bbk_panel/services/time_service.dart';
import 'dart:developer';

import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class StatServices {
  static Stream<Map<String, dynamic>> getStats(
    String agentUid,
    String category,
  ) {
    final ratingStream = getAgentRating(agentUid);
    final jobsStream = getCompletedJobCountByCategory(category, agentUid);

    return Rx.combineLatest2<double, int, Map<String, dynamic>>(
      ratingStream,
      jobsStream,
      (rating, jobs) => {'rating': rating, 'jobs': jobs},
    );
  }

  static Stream<double> getAgentRating(String agentUid) {
    return AppFirestore.usersCollectionRef.doc(agentUid).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data() as Map<String, dynamic>?;
      return data?['rating'] ?? 0.0;
    });
  }

  static Stream<int> getCompletedJobCountByCategory(
    String category,
    String agentUid,
  ) {
    return AppFirestore.bookingsCollectionRef
        .where('bookingStatusCode', isEqualTo: 'C')
        .where('agent.uid', isEqualTo: agentUid)
        .where('service.category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<Map<String, dynamic>> getStatsOnce(
    String agentUid,
    String category,
  ) async {
    try {
      // Fetch agent rating once

      final bookings = await AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'C')
          .where('agent.uid', isEqualTo: agentUid)
          .where('service.category', isEqualTo: category)
          .where("review", isNull: false)
          .get();
      log(bookings.docs.length.toString());

      final reviews = bookings.docs.map((doc) => doc['review']).toList();

      final ratings = reviews.map((review) => review['rating']).toList();
      final rating = ratings.isNotEmpty
          ? ratings.reduce((a, b) => a + b) / ratings.length
          : 0;

      // Saudi month boundaries — the stats window is a business month.
      final now = KsaTime.now;
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final firstDayOfNextMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);

      final bookingsQuerySnapshot = await AppFirestore.bookingsCollectionRef
          .where('bookingStatusCode', isEqualTo: 'C')
          .where('agent.uid', isEqualTo: agentUid)
          .where('service.category', isEqualTo: category)
          .where(
            'completedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
          )
          .where(
            'completedAt',
            isLessThan: Timestamp.fromDate(firstDayOfNextMonth),
          )
          .get();

      final int jobs = bookingsQuerySnapshot.docs.length;

      return {'rating': rating, 'jobs': jobs};
    } catch (e) {
      // Handle or rethrow error as needed
      rethrow;
    }
  }
}
