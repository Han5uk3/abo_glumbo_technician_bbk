import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:intl/intl.dart';

class ConflictCheckService {
  static const List<String> _activeBookingStatuses = ['P', 'A'];
  static final DateFormat _timeKeyFormat = DateFormat('HH:mm_yyyy-MM-dd');

  final Map<String, ConflictData> _cache = {};
  final Map<String, Set<String>> _recentAssignments = {};
  DateTime? _cacheTimestamp;

  static const _cacheDuration = Duration(minutes: 2);
  static const _assignmentCleanupDuration = Duration(hours: 1);

  bool get isCacheValid =>
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;

  void invalidateCache() {
    _cache.clear();
    _cacheTimestamp = null;
  }

  ConflictData? getConflictData(String userId) {
    return _cache[userId];
  }

  bool hasConflict(String userId) {
    return _cache[userId]?.hasConflict ?? false;
  }

  Future<Map<String, ConflictData>> batchCheckConflicts({
    required List<String> userIds,
    required BookingModel booking,
    required List<String> cancelledWorkerUids,
  }) async {
    if (isCacheValid && _cache.isNotEmpty) {
      return Map.from(_cache);
    }

    try {
      final results = <String, ConflictData>{};
      final bookingTime = booking.bookingDateTime.toDate();

      // Batch Firestore queries for all statuses
      final bookingsByUser = await _fetchBookingsInBatches(userIds);

      for (final userId in userIds) {
        results[userId] = await _checkUserConflict(
          userId: userId,
          bookingTime: bookingTime,
          currentBookingId: booking.id,
          cancelledWorkerUids: cancelledWorkerUids,
          userBookings: bookingsByUser[userId] ?? [],
        );
      }

      _cache.addAll(results);
      _cacheTimestamp = DateTime.now();
      return results;
    } catch (e) {
      log('Error in batchCheckConflicts: $e');
      return {};
    }
  }

  Future<Map<String, List<QueryDocumentSnapshot>>> _fetchBookingsInBatches(
    List<String> userIds,
  ) async {
    final Map<String, List<QueryDocumentSnapshot>> results = {};

    for (final status in _activeBookingStatuses) {
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.sublist(
          i,
          (i + 10 > userIds.length) ? userIds.length : i + 10,
        );

        final query = await AppFirestore.bookingsCollectionRef
            .where('agent.uid', whereIn: batch)
            .where('bookingStatusCode', isEqualTo: status)
            .get();

        for (final doc in query.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final assignedTo =
              (data['agent'] as Map<String, dynamic>?)?['uid'] as String?;
          if (assignedTo != null) {
            results[assignedTo] = [...(results[assignedTo] ?? []), doc];
          }
        }
      }
    }

    return results;
  }

  Future<ConflictData> _checkUserConflict({
    required String userId,
    required DateTime bookingTime,
    required String? currentBookingId,
    required List<String> cancelledWorkerUids,
    required List<QueryDocumentSnapshot> userBookings,
  }) async {
    // Check active bookings
    for (final doc in userBookings) {
      final data = doc.data() as Map<String, dynamic>;
      if (doc.id == currentBookingId) continue;

      final existingTime = data['bookingDateTime'] as Timestamp?;
      if (existingTime != null &&
          _isTimeConflict(existingTime.toDate(), bookingTime)) {
        return ConflictData(
          hasConflict: true,
          type: ConflictType.activeBooking,
          time: existingTime.toDate(),
          bookingId: doc.id,
        );
      }
    }

    // Check if worker cancelled this booking
    if (cancelledWorkerUids.contains(userId)) {
      return ConflictData(
        hasConflict: true,
        type: ConflictType.workerCancelledThisBooking,
        time: bookingTime,
        bookingId: currentBookingId,
      );
    }

    // Check local session conflicts
    final timeKey = _timeKeyFormat.format(bookingTime);
    if (_recentAssignments[userId]?.contains(timeKey) ?? false) {
      return ConflictData(
        hasConflict: true,
        type: ConflictType.localSession,
        time: bookingTime,
      );
    }

    return ConflictData(hasConflict: false);
  }

  bool _isTimeConflict(DateTime time1, DateTime time2) {
    return time1.year == time2.year &&
        time1.month == time2.month &&
        time1.day == time2.day &&
        time1.hour == time2.hour &&
        time1.minute == time2.minute;
  }

  void trackAssignment(String userId, DateTime bookingTime) {
    final timeKey = _timeKeyFormat.format(bookingTime);
    _recentAssignments.putIfAbsent(userId, () => {}).add(timeKey);
    cleanupOldAssignments();
  }

  void cleanupOldAssignments() {
    final cutoff = DateTime.now().subtract(_assignmentCleanupDuration);

    _recentAssignments.removeWhere((userId, timeSet) {
      timeSet.removeWhere((timeKey) => _isOldAssignment(timeKey, cutoff));
      return timeSet.isEmpty;
    });
  }

  bool _isOldAssignment(String timeKey, DateTime cutoff) {
    try {
      final parts = timeKey.split('_');
      if (parts.length != 2) return true;

      final timeParts = parts[0].split(':');
      final dateParts = parts[1].split('-');

      if (timeParts.length != 2 || dateParts.length != 3) return true;

      final bookingTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      return bookingTime.isBefore(cutoff);
    } catch (e) {
      return true;
    }
  }

  void dispose() {
    _cache.clear();
    _recentAssignments.clear();
    _cacheTimestamp = null;
  }
}

enum ConflictType {
  activeBooking,
  workerCancelledThisBooking,
  workerCancelled,
  localSession,
}

class ConflictData {
  final bool hasConflict;
  final ConflictType? type;
  final DateTime? time;
  final String? bookingId;
  final String? workerName;

  ConflictData({
    required this.hasConflict,
    this.type,
    this.time,
    this.bookingId,
    this.workerName,
  });

  String? get conflictTime =>
      time != null ? DateFormat('HH:mm').format(time!) : null;

  String? get conflictDate =>
      time != null ? DateFormat('MMM dd, yyyy').format(time!) : null;
}
