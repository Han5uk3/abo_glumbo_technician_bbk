import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/models/unified_payout.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Unified Payout Services
/// Handles all payout-related operations for earnings, tips, and bonus
///
/// PAYOUT RULES:
/// - totalAvailableBalance = insideAppTips + availableBonus (ONLY these are payoutable)
/// - In-app service payments (mode 1) are tracked for lifetime totals, NOT payoutable
/// - Outside-app payments (mode 1, cash/manual) are tracked for lifetime totals, NOT payoutable
/// - Inspection fees (mode 0) are NEVER tracked in the wallet
class UnifiedPayoutServices {
  /// Get or create unified wallet for a worker
  static Future<UnifiedWalletModel> getUnifiedWallet(String workerId) async {
    try {
      final doc = await AppFirestore.unifiedWalletCollectionRef
          .doc(workerId)
          .get();

      if (doc.exists) {
        return UnifiedWalletModel.fromSnapshot(doc);
      } else {
        // Create new wallet if doesn't exist
        final wallet = UnifiedWalletModel(
          workerId: workerId,
          totalTips: 0.0,
          cardTips: 0.0,
          cashTips: 0.0,
          paidTips: 0.0,
          totalBonus: 0.0,
          paidBonus: 0.0,
          availableBonus: 0.0,
          inAppEarnings: 0.0,
          outsideAppEarnings: 0.0,
          totalCompletionAmount: 0.0,
          totalAvailableBalance: 0.0,
          lifetimeTotal: 0.0,
          payoutRequested: false,
          requestedAmount: 0.0,
          lastUpdated: Timestamp.now(),
        );

        await AppFirestore.unifiedWalletCollectionRef
            .doc(workerId)
            .set(wallet.toJson());
        return wallet;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting unified wallet: $e');
      }
      rethrow;
    }
  }

  /// Stream unified wallet for a worker
  static Stream<UnifiedWalletModel> getUnifiedWalletStream(String workerId) {
    return AppFirestore.unifiedWalletCollectionRef
        .doc(workerId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return UnifiedWalletModel(
              workerId: workerId,
              totalAvailableBalance: 0.0,
              lifetimeTotal: 0.0,
            );
          }
          return UnifiedWalletModel.fromSnapshot(snapshot);
        });
  }

  /// Update wallet amounts (called when tips/bonus/earnings are added)
  /// NOTE: Earnings (completionAmountIncrement / outsideAppEarningsIncrement)
  /// are tracked for lifetime totals ONLY — they are NOT added to totalAvailableBalance.
  /// Only Inside App tips (cardTips) and bonus are payoutable.
  static Future<void> updateWalletAmounts({
    required String workerId,
    double? tipsIncrement,
    double? bonusIncrement,
    double?
    completionAmountIncrement, // For bonus calculation (legacy, treated as outside-app)
    double? outsideAppEarningsIncrement, // Outside-app payment (cash/manual)
    double? inAppEarningsIncrement, // In-app payment (Telr)
    bool? isCashTip,
  }) async {
    try {
      final walletRef = AppFirestore.unifiedWalletCollectionRef.doc(workerId);
      final walletDoc = await walletRef.get();

      UnifiedWalletModel wallet;
      if (walletDoc.exists) {
        wallet = UnifiedWalletModel.fromSnapshot(walletDoc);
      } else {
        wallet = UnifiedWalletModel(workerId: workerId);
      }

      // Update tips
      if (tipsIncrement != null && tipsIncrement > 0) {
        wallet = wallet.copyWith(
          totalTips: (wallet.totalTips ?? 0.0) + tipsIncrement,
        );

        if (isCashTip == true) {
          wallet = wallet.copyWith(
            cashTips: (wallet.cashTips ?? 0.0) + tipsIncrement,
          );
        } else {
          wallet = wallet.copyWith(
            cardTips: (wallet.cardTips ?? 0.0) + tipsIncrement,
          );
        }
      }

      // Update bonus
      if (bonusIncrement != null && bonusIncrement > 0) {
        wallet = wallet.copyWith(
          totalBonus: (wallet.totalBonus ?? 0.0) + bonusIncrement,
          availableBonus: (wallet.availableBonus ?? 0.0) + bonusIncrement,
        );
      }

      // Update outside-app earnings (cash/manual payment verified by technician)
      // These are for informational/lifetime purposes only, NOT payoutable
      final earningsToAdd =
          (outsideAppEarningsIncrement ?? 0.0) +
          (completionAmountIncrement ?? 0.0);
      if (earningsToAdd > 0) {
        wallet = wallet.copyWith(
          outsideAppEarnings:
              (wallet.outsideAppEarnings ?? 0.0) + earningsToAdd,
          totalCompletionAmount:
              (wallet.totalCompletionAmount ?? 0.0) + earningsToAdd,
        );
      }

      // Update in-app earnings (paid via Telr/Apple Pay in customer app)
      if (inAppEarningsIncrement != null && inAppEarningsIncrement > 0) {
        wallet = wallet.copyWith(
          inAppEarnings: (wallet.inAppEarnings ?? 0.0) + inAppEarningsIncrement,
          totalCompletionAmount:
              (wallet.totalCompletionAmount ?? 0.0) + inAppEarningsIncrement,
        );
      }

      // Calculate totals
      // PAYOUT-REQUESTABLE: Inside App (card) tips + available bonus + in-app earnings
      final totalAvailable =
          (wallet.cardTips ?? 0.0) +
          (wallet.availableBonus ?? 0.0) +
          (wallet.inAppEarnings ?? 0.0);

      // LIFETIME TOTAL: All earnings + tips + bonus (display only)
      final lifetimeTotal =
          (wallet.totalTips ?? 0.0) +
          (wallet.totalBonus ?? 0.0) +
          (wallet.totalCompletionAmount ?? 0.0);

      wallet = wallet.copyWith(
        totalAvailableBalance: totalAvailable,
        lifetimeTotal: lifetimeTotal,
        lastUpdated: Timestamp.now(),
      );

      await walletRef.set(wallet.toJson(), SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Wallet updated for worker $workerId');
        print(
          '   Payout-Requestable Balance: ${wallet.totalAvailableBalance} (tips + bonus only)',
        );
        print('   Lifetime Total: ${wallet.lifetimeTotal}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating wallet amounts: $e');
      }
      rethrow;
    }
  }

  /// Request a unified payout (Inside App tips + bonus only)
  static Future<String> requestUnifiedPayout({
    required String workerId,
    required double tipsAmount,
    required double bonusAmount,
    required double earningsAmount,
  }) async {
    try {
      // Get worker details
      final worker = await AppServices.getWorkerById(workerId);

      // Get primary payout account
      final payoutAccount = await AppServices.getPrimaryPayoutAccount(workerId);
      if (payoutAccount == null) {
        throw Exception('No payout account found');
      }

      // Get current wallet
      final wallet = await getUnifiedWallet(workerId);

      // Validate amounts
      if (tipsAmount > (wallet.cardTips ?? 0.0)) {
        throw Exception('Insufficient tips balance');
      }
      if (bonusAmount > (wallet.availableBonus ?? 0.0)) {
        throw Exception('Insufficient bonus balance');
      }
      if (earningsAmount > (wallet.inAppEarnings ?? 0.0)) {
        throw Exception('Insufficient in-app earnings balance');
      }

      final totalAmount = tipsAmount + bonusAmount + earningsAmount;
      if (totalAmount <= 0) {
        throw Exception('Total amount must be greater than 0');
      }

      // Create payout request
      final requestId = AppFirestore.unifiedPayoutRequestsCollectionRef
          .doc()
          .id;
      final request = UnifiedPayoutRequestModel(
        id: requestId,
        workerId: workerId,
        workerName: worker.name,
        tipsAmount: tipsAmount,
        bonusAmount: bonusAmount,
        earningsAmount: earningsAmount,
        totalAmount: totalAmount,
        payoutAccount: payoutAccount.toJson(),
        status: 'P', // Pending
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      await AppFirestore.unifiedPayoutRequestsCollectionRef
          .doc(requestId)
          .set(request.toJson());

      // Sync wallet to accurately calculate pending amounts
      await syncExistingDataToUnifiedWallet(workerId);

      if (kDebugMode) {
        print('✅ Payout request created: $requestId');
        print('   Total Amount: $totalAmount');
      }

      return requestId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting payout: $e');
      }
      rethrow;
    }
  }

  /// Get payout requests for a worker
  static Stream<List<UnifiedPayoutRequestModel>> getWorkerPayoutRequests(
    String workerId,
  ) {
    return AppFirestore.unifiedPayoutRequestsCollectionRef
        .where('workerId', isEqualTo: workerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UnifiedPayoutRequestModel.fromSnapshot(doc))
              .toList();
        });
  }

  /// Get all payout requests (for admin)
  static Stream<List<UnifiedPayoutRequestModel>> getAllPayoutRequests({
    String? status,
  }) {
    Query query = AppFirestore.unifiedPayoutRequestsCollectionRef;

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => UnifiedPayoutRequestModel.fromSnapshot(doc))
          .toList();
    });
  }

  /// Approve and complete payout (admin only)
  static Future<void> approvePayout({
    required String requestId,
    required String transactionId,
    XFile? paymentProof,
  }) async {
    try {
      // Get the request
      final requestDoc = await AppFirestore.unifiedPayoutRequestsCollectionRef
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Payout request not found');
      }

      final request = UnifiedPayoutRequestModel.fromSnapshot(requestDoc);

      if (request.workerId == null) {
        throw Exception('Worker ID not found in request');
      }

      // Upload payment proof if provided
      String? proofUrl;
      if (paymentProof != null) {
        proofUrl = await _uploadPaymentProof(request.workerId!, paymentProof);
      }

      // We no longer manually update the wallet here. 
      // Instead, we mark the request as Approved ('A') and then call sync.

      // Update request status
      await AppFirestore.unifiedPayoutRequestsCollectionRef
          .doc(requestId)
          .update({
            'status': 'A', // Approved
            'approvedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
            'transactionId': transactionId,
            'paymentProofUrl': proofUrl,
          });

      // Create history record
      final historyId = AppFirestore.payoutHistoryCollectionRef.doc().id;
      final history = PayoutHistoryModel(
        id: historyId,
        workerId: request.workerId,
        workerName: request.workerName,
        tipsAmount: request.tipsAmount,
        bonusAmount: request.bonusAmount,
        earningsAmount: request.earningsAmount,
        totalAmount: request.totalAmount,
        completedAt: Timestamp.now(),
        transactionId: transactionId,
        paymentProofUrl: proofUrl,
        payoutAccount: request.payoutAccount,
      );

      await AppFirestore.payoutHistoryCollectionRef
          .doc(historyId)
          .set(history.toJson());

      // Sync wallet to recalculate based on newly approved status
      if (request.workerId != null) {
        await syncExistingDataToUnifiedWallet(request.workerId!);
      }

      if (kDebugMode) {
        print('✅ Payout approved: $requestId');
        print('   Transaction ID: $transactionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error approving payout: $e');
      }
      rethrow;
    }
  }

  /// Reject payout request (admin only)
  static Future<void> rejectPayout({
    required String requestId,
    required String reason,
  }) async {
    try {
      // Get the request
      final requestDoc = await AppFirestore.unifiedPayoutRequestsCollectionRef
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Payout request not found');
      }

      final request = UnifiedPayoutRequestModel.fromSnapshot(requestDoc);

      // Update request status
      await AppFirestore.unifiedPayoutRequestsCollectionRef
          .doc(requestId)
          .update({
            'status': 'R', // Rejected
            'rejectedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
            'rejectionReason': reason,
          });

      // Update wallet status
      if (request.workerId != null) {
        await syncExistingDataToUnifiedWallet(request.workerId!);
      }

      if (kDebugMode) {
        print('✅ Payout rejected: $requestId');
        print('   Reason: $reason');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rejecting payout: $e');
      }
      rethrow;
    }
  }

  /// Get payout history for a worker
  static Stream<List<PayoutHistoryModel>> getWorkerPayoutHistory(
    String workerId,
  ) {
    return AppFirestore.payoutHistoryCollectionRef
        .where('workerId', isEqualTo: workerId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PayoutHistoryModel.fromSnapshot(doc))
              .toList();
        });
  }

  /// Get all payout history (for admin)
  static Stream<List<PayoutHistoryModel>> getAllPayoutHistory() {
    return AppFirestore.payoutHistoryCollectionRef
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PayoutHistoryModel.fromSnapshot(doc))
              .toList();
        });
  }

  /// Cancel payout request (worker can cancel pending requests)
  static Future<void> cancelPayoutRequest(String requestId) async {
    try {
      final requestDoc = await AppFirestore.unifiedPayoutRequestsCollectionRef
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Payout request not found');
      }

      final request = UnifiedPayoutRequestModel.fromSnapshot(requestDoc);

      if (request.status != 'P') {
        throw Exception('Can only cancel pending requests');
      }

      // Delete the request
      await AppFirestore.unifiedPayoutRequestsCollectionRef
          .doc(requestId)
          .delete();

      // Update wallet status
      if (request.workerId != null) {
        await syncExistingDataToUnifiedWallet(request.workerId!);
      }

      if (kDebugMode) {
        print('✅ Payout request cancelled: $requestId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling payout request: $e');
      }
      rethrow;
    }
  }

  /// Upload payment proof
  static Future<String?> _uploadPaymentProof(
    String workerId,
    XFile image,
  ) async {
    try {
      final bytes = await image.readAsBytes();
      final fileName =
          'payout_proof_${workerId}_${DateTime.now().millisecondsSinceEpoch}.${image.name.split('.').last}';

      final storageRef = AppFireStorage.payoutProofsStorageRef
          .child('unified_payouts')
          .child(workerId)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: _getContentType(image.name),
        customMetadata: {
          'uploadedBy': 'admin',
          'workerId': workerId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('✅ Payment proof uploaded: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading payment proof: $e');
      }
      return null;
    }
  }

  /// Get content type from file extension
  static String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Sync existing data to unified wallet (migration helper)
  /// NOTE: Also migrates booking earnings for lifetime totals
  /// In-app earnings are tracked by customer app; outside-app are from technician verification
  static Future<void> syncExistingDataToUnifiedWallet(String workerId) async {
    try {
      // Get existing data
      final tippingData = await AppServices.getWorkerTippingData(workerId);
      final bonusAmount = await AppServices.getWorkerBonusAmounts(workerId);

      // Get booking earnings (mode == 1 only, excluding inspection fees)
      final bookingsQuery = await AppFirestore.bookingsCollectionRef
          .where('agent.uid', isEqualTo: workerId)
          .where('bookingStatusCode', isEqualTo: 'C')
          .get();

      double lifetimeInAppEarnings = 0.0;
      double lifetimeOutsideAppEarnings = 0.0;
      for (var doc in bookingsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final completionData = data['completionData'];
        if (completionData != null && completionData['mode'] == 1) {
          final amount =
              (completionData['totalCost'] as num?)?.toDouble() ?? 0.0;
          // Check if payment was through app (has orderId/transactionId)
          // or outside app (technician payment proof)
          final hasOrderId =
              data['orderId'] != null && (data['orderId'] as String).isNotEmpty;
          final hasTechProof =
              data['technicianPaymentProof'] != null &&
              (data['technicianPaymentProof'] as List).isNotEmpty;

          if (hasOrderId && !hasTechProof) {
            lifetimeInAppEarnings += amount;
          } else {
            lifetimeOutsideAppEarnings += amount;
          }
        }
      }

      final totalEarnings = lifetimeInAppEarnings + lifetimeOutsideAppEarnings;

      // Query all approved/pending payouts to calculate exactly what has been withdrawn
      final payoutsQuery = await AppFirestore.unifiedPayoutRequestsCollectionRef
          .where('workerId', isEqualTo: workerId)
          .where(
            'status',
            whereIn: ['A', 'P'],
          ) // Include pending to avoid re-adding
          .get();

      double totalPaidTips = 0.0;
      double totalPaidBonus = 0.0;
      double totalPaidEarnings = 0.0;
      bool hasPendingPayout = false;
      double pendingAmount = 0.0;

      for (var doc in payoutsQuery.docs) {
        final reqData = doc.data() as Map<String, dynamic>;
        
        if (reqData['status'] == 'A') {
          // Only deduct approved payouts from available balance
          totalPaidTips += (reqData['tipsAmount'] as num?)?.toDouble() ?? 0.0;
          totalPaidBonus += (reqData['bonusAmount'] as num?)?.toDouble() ?? 0.0;
          totalPaidEarnings += (reqData['earningsAmount'] as num?)?.toDouble() ?? 0.0;
        } else if (reqData['status'] == 'P') {
          hasPendingPayout = true;
          pendingAmount += (reqData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      final lifetimeCardTips = tippingData.cardtip ?? 0.0;
      final lifetimeCashTips = tippingData.cashtip ?? 0.0;

      // Calculate safe available balances (clamp to 0 to avoid negatives)
      double availableCardTips = lifetimeCardTips - totalPaidTips;
      if (availableCardTips < 0) availableCardTips = 0;

      double availableBonus = bonusAmount - totalPaidBonus;
      if (availableBonus < 0) availableBonus = 0;

      double availableInAppEarnings = lifetimeInAppEarnings - totalPaidEarnings;
      if (availableInAppEarnings < 0) availableInAppEarnings = 0;

      // Ensure payoutRequested is correctly reflected based on actual pending requests
      // Fallback to legacy tippingData if true and we didn't find one
      final isPayoutRequested =
          hasPendingPayout || (tippingData.payoutRequested ?? false);

      // Create/update unified wallet
      final wallet = UnifiedWalletModel(
        workerId: workerId,
        totalTips: lifetimeCardTips + lifetimeCashTips,
        cardTips: availableCardTips, // Store available for payout
        cashTips: lifetimeCashTips,
        paidTips: totalPaidTips, // Accurate from historical requests
        totalBonus: bonusAmount,
        paidBonus: totalPaidBonus,
        availableBonus: availableBonus,
        inAppEarnings: availableInAppEarnings, // Store available
        outsideAppEarnings: lifetimeOutsideAppEarnings, // Lifetime info
        totalCompletionAmount: totalEarnings, // Lifetime sum
        payoutRequested: isPayoutRequested,
        requestedAmount: isPayoutRequested ? pendingAmount : 0.0,
        lastUpdated: Timestamp.now(),
      );

      // Calculate totals
      // PAYOUT-REQUESTABLE: Inside App (card) tips + bonus + in-app earnings
      final totalAvailable =
          availableCardTips + availableBonus + availableInAppEarnings;
      // LIFETIME: Everything combined
      final lifetimeTotal =
          (wallet.totalTips ?? 0.0) +
          (wallet.totalBonus ?? 0.0) +
          (wallet.totalCompletionAmount ?? 0.0);

      final updatedWallet = wallet.copyWith(
        totalAvailableBalance: totalAvailable,
        lifetimeTotal: lifetimeTotal,
      );

      await AppFirestore.unifiedWalletCollectionRef
          .doc(workerId)
          .set(updatedWallet.toJson(), SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Synced existing data to unified wallet for worker $workerId');
        print(
          '   Payout-Requestable: $totalAvailable (card tips + bonus + in-app earnings)',
        );
        print('   In-App Earnings (Available): $availableInAppEarnings');
        print(
          '   Outside-App Earnings (Lifetime): $lifetimeOutsideAppEarnings',
        );
        print('   Lifetime Total: $lifetimeTotal');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing data to unified wallet: $e');
      }
      rethrow;
    }
  }

  /// Clear a worker's wallet balances completely (Admin only)
  static Future<void> clearWallet(String workerId) async {
    try {
      final walletRef = AppFirestore.unifiedWalletCollectionRef.doc(workerId);
      final walletDoc = await walletRef.get();

      if (!walletDoc.exists) {
        // If it doesn't exist, just create an empty one
        final clearedWallet = UnifiedWalletModel(
          workerId: workerId,
          totalTips: 0.0,
          cardTips: 0.0,
          cashTips: 0.0,
          paidTips: 0.0,
          totalBonus: 0.0,
          paidBonus: 0.0,
          availableBonus: 0.0,
          inAppEarnings: 0.0,
          outsideAppEarnings: 0.0,
          totalCompletionAmount: 0.0,
          totalAvailableBalance: 0.0,
          lifetimeTotal: 0.0,
          payoutRequested: false,
          requestedAmount: 0.0,
          lastUpdated: Timestamp.now(),
        );
        await walletRef.set(clearedWallet.toJson());
      } else {
        // Preserve lifetime data, clear only available balances
        final wallet = UnifiedWalletModel.fromSnapshot(walletDoc);

        final newPaidTips = (wallet.paidTips ?? 0.0) + (wallet.cardTips ?? 0.0);
        final newPaidBonus =
            (wallet.paidBonus ?? 0.0) + (wallet.availableBonus ?? 0.0);

        await walletRef.update({
          'cardTips': 0.0,
          'availableBonus': 0.0,
          'inAppEarnings': 0.0,
          'paidTips': newPaidTips,
          'paidBonus': newPaidBonus,
          'totalAvailableBalance': 0.0,
          'payoutRequested': false,
          'requestedAmount': 0.0,
          'lastUpdated': Timestamp.now(),
        });
      }

      if (kDebugMode) {
        print('✅ Wallet balances cleared successfully for worker: $workerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing wallet balances: $e');
      }
      rethrow;
    }
  }

  /// Get statistics for admin dashboard
  static Future<Map<String, dynamic>> getPayoutStatistics() async {
    try {
      final pendingRequests = await AppFirestore
          .unifiedPayoutRequestsCollectionRef
          .where('status', isEqualTo: 'P')
          .get();

      final approvedRequests = await AppFirestore
          .unifiedPayoutRequestsCollectionRef
          .where('status', isEqualTo: 'A')
          .get();

      double totalPendingAmount = 0.0;
      double totalApprovedAmount = 0.0;

      for (var doc in pendingRequests.docs) {
        final request = UnifiedPayoutRequestModel.fromSnapshot(doc);
        totalPendingAmount += request.totalAmount ?? 0.0;
      }

      for (var doc in approvedRequests.docs) {
        final request = UnifiedPayoutRequestModel.fromSnapshot(doc);
        totalApprovedAmount += request.totalAmount ?? 0.0;
      }

      return {
        'pendingCount': pendingRequests.docs.length,
        'approvedCount': approvedRequests.docs.length,
        'totalPendingAmount': totalPendingAmount,
        'totalApprovedAmount': totalApprovedAmount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting payout statistics: $e');
      }
      return {
        'pendingCount': 0,
        'approvedCount': 0,
        'totalPendingAmount': 0.0,
        'totalApprovedAmount': 0.0,
      };
    }
  }
}
