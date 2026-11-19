import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/unified_payout_services.dart';

/// Migration Script for Unified Payout System
///
/// This script helps migrate from the old payout system to the new unified system.
/// Run this once to migrate all existing worker data.
class UnifiedPayoutMigration {
  /// Migrate all workers to unified wallet system
  static Future<Map<String, dynamic>> migrateAllWorkers() async {
    int successCount = 0;
    int failureCount = 0;
    List<String> failedWorkers = [];
    List<String> successfulWorkers = [];

    try {

      // Get all workers
      final workers = await AppServices.getAllAgentsStream().first;


      for (var worker in workers) {
        try {

          // Sync existing data to unified wallet
          await UnifiedPayoutServices.syncExistingDataToUnifiedWallet(
            worker.uid!,
          );

          successCount++;
          successfulWorkers.add(worker.name ?? worker.uid ?? 'Unknown');

        } catch (e) {
          failureCount++;
          failedWorkers.add(worker.name ?? worker.uid ?? 'Unknown');

        }
      }

      return {
        'success': true,
        'totalWorkers': workers.length,
        'successCount': successCount,
        'failureCount': failureCount,
        'successfulWorkers': successfulWorkers,
        'failedWorkers': failedWorkers,
      };
    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
        'successCount': successCount,
        'failureCount': failureCount,
        'successfulWorkers': successfulWorkers,
        'failedWorkers': failedWorkers,
      };
    }
  }

  /// Migrate a single worker
  static Future<bool> migrateSingleWorker(String workerId) async {
    try {

      await UnifiedPayoutServices.syncExistingDataToUnifiedWallet(workerId);


      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify migration for a worker
  /// NOTE: Only verifies tips and bonus - earnings no longer tracked
  static Future<Map<String, dynamic>> verifyWorkerMigration(
    String workerId,
  ) async {
    try {

      // Get old system data
      final tippingData = await AppServices.getWorkerTippingData(workerId);
      final bonusAmount = await AppServices.getWorkerBonusAmounts(workerId);

      // Calculate expected values (only tips and bonus)
      final expectedCardTips = tippingData.cardtip ?? 0.0;
      final expectedCashTips = tippingData.cashtip ?? 0.0;
      final expectedTotalTips = expectedCardTips + expectedCashTips;
      final expectedAvailableBonus = bonusAmount;

      // Get unified wallet data
      final wallet = await UnifiedPayoutServices.getUnifiedWallet(workerId);

      // Compare values (only tips and bonus)
      final cardTipsMatch = (wallet.cardTips ?? 0.0) == expectedCardTips;
      final cashTipsMatch = (wallet.cashTips ?? 0.0) == expectedCashTips;
      final totalTipsMatch = (wallet.totalTips ?? 0.0) == expectedTotalTips;
      final bonusMatch =
          (wallet.availableBonus ?? 0.0) == expectedAvailableBonus;

      final allMatch =
          cardTipsMatch && cashTipsMatch && totalTipsMatch && bonusMatch;


      return {
        'success': allMatch,
        'workerId': workerId,
        'checks': {
          'cardTips': cardTipsMatch,
          'cashTips': cashTipsMatch,
          'totalTips': totalTipsMatch,
          'bonus': bonusMatch,
        },
        'expected': {
          'cardTips': expectedCardTips,
          'cashTips': expectedCashTips,
          'totalTips': expectedTotalTips,
          'bonus': expectedAvailableBonus,
        },
        'actual': {
          'cardTips': wallet.cardTips,
          'cashTips': wallet.cashTips,
          'totalTips': wallet.totalTips,
          'bonus': wallet.availableBonus,
        },
      };
    } catch (e) {

      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify all workers
  static Future<Map<String, dynamic>> verifyAllWorkers() async {
    int passedCount = 0;
    int failedCount = 0;
    List<String> passedWorkers = [];
    List<String> failedWorkers = [];

    try {

      final workers = await AppServices.getAllAgentsStream().first;


      for (var worker in workers) {
        try {
          final result = await verifyWorkerMigration(worker.uid!);

          if (result['success'] == true) {
            passedCount++;
            passedWorkers.add(worker.name ?? worker.uid ?? 'Unknown');
          } else {
            failedCount++;
            failedWorkers.add(worker.name ?? worker.uid ?? 'Unknown');
          }
        } catch (e) {
          failedCount++;
          failedWorkers.add(worker.name ?? worker.uid ?? 'Unknown');

        }
      }

      return {
        'success': failedCount == 0,
        'totalWorkers': workers.length,
        'passedCount': passedCount,
        'failedCount': failedCount,
        'passedWorkers': passedWorkers,
        'failedWorkers': failedWorkers,
      };
    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
        'passedCount': passedCount,
        'failedCount': failedCount,
      };
    }
  }

  /// Generate migration report
  static Future<String> generateMigrationReport() async {
    final buffer = StringBuffer();

    buffer.writeln('=' * 60);
    buffer.writeln('UNIFIED PAYOUT SYSTEM MIGRATION REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    try {
      final workers = await AppServices.getAllAgentsStream().first;

      buffer.writeln('Total Workers: ${workers.length}');
      buffer.writeln();
      buffer.writeln('-' * 60);
      buffer.writeln();

      for (var worker in workers) {
        try {
          final verification = await verifyWorkerMigration(worker.uid!);

          buffer.writeln('Worker: ${worker.name ?? 'Unknown'} (${worker.uid})');
          buffer.writeln(
            'Status: ${verification['success'] ? '✅ PASSED' : '❌ FAILED'}',
          );

          if (verification['success'] == true) {
            final actual = verification['actual'];
            buffer.writeln(
              '  Total Available: ${actual['availableEarnings'] + actual['cardTips'] + actual['bonus']}',
            );
            buffer.writeln('  - Earnings: ${actual['availableEarnings']}');
            buffer.writeln('  - Tips: ${actual['cardTips']}');
            buffer.writeln('  - Bonus: ${actual['bonus']}');
          } else {
            buffer.writeln(
              '  Error: ${verification['error'] ?? 'Verification failed'}',
            );
          }

          buffer.writeln();
        } catch (e) {
          buffer.writeln('Worker: ${worker.name ?? 'Unknown'} (${worker.uid})');
          buffer.writeln('Status: ❌ ERROR');
          buffer.writeln('  Error: $e');
          buffer.writeln();
        }
      }

      buffer.writeln('-' * 60);
      buffer.writeln('END OF REPORT');
      buffer.writeln('=' * 60);

      return buffer.toString();
    } catch (e) {
      buffer.writeln('ERROR GENERATING REPORT: $e');
      return buffer.toString();
    }
  }
}
