import 'package:aboglumbo_bbk_panel/services/wallet_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rebuilds one technician's balances the way
/// `UnifiedPayoutServices.syncExistingDataToUnifiedWallet` does, with the
/// Firestore reads replaced by plain numbers.
WalletBalances rebuild({
  double cardTips = 0,
  double cashTips = 0,
  double bonus = 0,
  double inApp = 0,
  double outsideApp = 0,
  double paidTips = 0,
  double paidBonus = 0,
  double paidEarnings = 0,
  double clearedTips = 0,
  double clearedBonus = 0,
  double clearedEarnings = 0,
}) => WalletMath.balances(
  lifetimeCardTips: cardTips,
  lifetimeCashTips: cashTips,
  lifetimeBonus: bonus,
  lifetimeInAppEarnings: inApp,
  lifetimeOutsideAppEarnings: outsideApp,
  paidTips: paidTips,
  paidBonus: paidBonus,
  paidEarnings: paidEarnings,
  clearedTips: clearedTips,
  clearedBonus: clearedBonus,
  clearedEarnings: clearedEarnings,
);

void main() {
  group('rounding', () {
    test('every derived amount lands on a whole halala', () {
      // 10.10 + 15.20 is 25.299999999999997 in binary floating point.
      final b = rebuild(bonus: 10.10 + 15.20);
      expect(b.availableBonus, 25.30);
      expect(b.totalBonus, 25.30);
      expect(b.lifetimeTotal, 25.30);
    });

    test('a technician can request the exact balance they were shown', () {
      final b = rebuild(bonus: 10.10 + 15.20);
      expect(
        WalletMath.refuseRequest(
          tips: 0,
          bonus: 25.30,
          earnings: 0,
          balances: b,
          hasPendingRequest: false,
        ),
        isNull,
        reason: 'before rounding this was refused as "Insufficient bonus"',
      );
    });

    test('long tails do not leak into the total', () {
      final b = rebuild(cardTips: 0.1, bonus: 0.2, inApp: 10.0);
      expect(b.totalAvailable, 10.30);
    });

    test('NaN and infinity collapse to zero rather than poisoning a wallet', () {
      expect(WalletMath.money(double.nan), 0.0);
      expect(WalletMath.money(double.infinity), 0.0);
      expect(WalletMath.asDouble(double.nan), 0.0);
    });

    test('reads coerce int, double and String alike', () {
      expect(WalletMath.asDouble(7), 7.0);
      expect(WalletMath.asDouble(7.25), 7.25);
      expect(WalletMath.asDouble('7.25'), 7.25);
      expect(WalletMath.asDouble('not money'), 0.0);
      expect(WalletMath.asDouble(null), 0.0);
    });
  });

  group('unpaid bonus accumulates across months', () {
    test('August 10 + September 15 stays claimable in October', () {
      // The regression this change is about: the lifetime figure now comes from
      // the permanent monthly_records, so a rebuild in October sees both months
      // instead of only the most recent one.
      final b = rebuild(bonus: 10.0 + 15.0);
      expect(b.availableBonus, 25.0);
      expect(b.totalAvailable, 25.0);
    });

    test('a rebuild is idempotent — refreshing never erodes the balance', () {
      for (var i = 0; i < 5; i++) {
        expect(rebuild(bonus: 25.0).availableBonus, 25.0);
      }
    });

    test('only approved payouts reduce the balance', () {
      expect(rebuild(bonus: 25.0, paidBonus: 25.0).availableBonus, 0.0);
      expect(rebuild(bonus: 25.0, paidBonus: 10.0).availableBonus, 15.0);
    });

    test('a pending request does not spend the balance', () {
      // Pending amounts are never passed as paid*, so a rejected or cancelled
      // request leaves the technician exactly where they were.
      expect(rebuild(bonus: 25.0).availableBonus, 25.0);
    });
  });

  group('ledger integrity', () {
    test('available + gone always equals what was earned', () {
      final b = rebuild(
        cardTips: 40.0,
        bonus: 25.0,
        inApp: 100.0,
        paidTips: 15.0,
        paidBonus: 10.0,
        paidEarnings: 60.0,
      );
      expect(b.availableCardTips + b.paidTips, 40.0);
      expect(b.availableBonus + b.paidBonus, 25.0);
      expect(b.availableInAppEarnings + 60.0, 100.0);
    });

    test('an over-payment clamps to zero instead of going negative', () {
      final b = rebuild(bonus: 10.0, paidBonus: 25.0);
      expect(b.availableBonus, 0.0);
      expect(b.totalAvailable, greaterThanOrEqualTo(0.0));
    });

    test('an admin clear is honoured by the next rebuild', () {
      // Without the cleared* terms the rebuild recomputes from source data,
      // knows nothing of the clear, and hands the money straight back.
      final b = rebuild(bonus: 25.0, clearedBonus: 25.0);
      expect(b.availableBonus, 0.0);
      expect(b.paidBonus, 25.0, reason: 'cleared money still shows as gone');
    });

    test('a clear does not swallow bonus earned after it', () {
      final b = rebuild(bonus: 25.0 + 12.0, clearedBonus: 25.0);
      expect(b.availableBonus, 12.0);
    });

    test('clears and payouts subtract together, not twice over', () {
      final b = rebuild(bonus: 100.0, paidBonus: 30.0, clearedBonus: 20.0);
      expect(b.availableBonus, 50.0);
      expect(b.paidBonus, 50.0);
    });

    test('cash tips are never payoutable but do count as lifetime', () {
      final b = rebuild(cardTips: 20.0, cashTips: 30.0);
      expect(b.availableCardTips, 20.0);
      expect(b.totalTips, 50.0);
      expect(b.totalAvailable, 20.0, reason: 'cash stays out of the payout');
    });

    test('outside-app earnings are lifetime only, never payoutable', () {
      final b = rebuild(inApp: 100.0, outsideApp: 250.0);
      expect(b.availableInAppEarnings, 100.0);
      expect(b.totalAvailable, 100.0);
      expect(b.totalCompletionAmount, 350.0);
      expect(b.lifetimeTotal, 350.0);
    });

    test('lifetime total is tips + bonus + all earnings', () {
      final b = rebuild(
        cardTips: 10.0,
        cashTips: 5.0,
        bonus: 25.0,
        inApp: 100.0,
        outsideApp: 60.0,
      );
      expect(b.lifetimeTotal, 200.0);
    });
  });

  group('successive payouts over five months', () {
    // Monthly bonus credited on the 1st for the month that just closed.
    const jan = 10.0, feb = 15.0, mar = 20.0, apr = 12.0, may = 18.0;
    const firstThree = jan + feb + mar; // 45, claimed in payout #1
    const nextTwo = apr + may; // 30, earned after payout #1
    const lifetime = firstThree + nextTwo; // 75

    test('payout #1 offers everything credited so far', () {
      expect(rebuild(bonus: firstThree).availableBonus, 45.0);
    });

    test('payout #2 offers only what was earned since payout #1', () {
      // Payout #1 approved for 45; two more months credited since.
      final b = rebuild(bonus: lifetime, paidBonus: firstThree);
      expect(b.availableBonus, 30.0);
      expect(b.totalBonus, 75.0, reason: 'lifetime still shows everything');
      expect(b.paidBonus, 45.0);
    });

    test('nothing is paid twice across five months of payouts', () {
      final first = rebuild(bonus: firstThree).availableBonus;
      final second = rebuild(bonus: lifetime, paidBonus: first).availableBonus;
      expect(first + second, lifetime);
    });

    test('a third payout with nothing new earned offers nothing', () {
      expect(rebuild(bonus: lifetime, paidBonus: lifetime).availableBonus, 0.0);
    });

    test('while payout #1 is only pending, payout #2 is refused', () {
      // Pending requests do not reduce the balance, so the guard is what stops
      // the same 45 being claimed twice.
      final b = rebuild(bonus: lifetime);
      expect(b.availableBonus, 75.0);
      expect(
        WalletMath.refuseRequest(
          tips: 0,
          bonus: 75.0,
          earnings: 0,
          balances: b,
          hasPendingRequest: true,
        ),
        PayoutRefusal.pendingRequestExists,
      );
    });

    test('a rejected payout #1 returns the whole balance', () {
      // Rejected and cancelled requests never count as paid.
      expect(rebuild(bonus: lifetime, paidBonus: 0.0).availableBonus, 75.0);
    });

    test('an unclaimed remainder carries into the next payout', () {
      // Payout #1 approved for only 40 of the 45 available.
      final b = rebuild(bonus: lifetime, paidBonus: 40.0);
      expect(b.availableBonus, 35.0, reason: '30 new + 5 left behind');
    });
  });

  group('payout request rules', () {
    final wallet = rebuild(cardTips: 20.0, bonus: 25.0, inApp: 100.0);

    PayoutRefusal? refuse({
      double tips = 0,
      double bonus = 0,
      double earnings = 0,
      bool pending = false,
      WalletBalances? balances,
    }) => WalletMath.refuseRequest(
      tips: tips,
      bonus: bonus,
      earnings: earnings,
      balances: balances ?? wallet,
      hasPendingRequest: pending,
    );

    test('the full balance is allowed', () {
      expect(refuse(tips: 20.0, bonus: 25.0, earnings: 100.0), isNull);
    });

    test('one halala over any bucket is refused', () {
      expect(refuse(tips: 20.01), PayoutRefusal.insufficientTips);
      expect(refuse(bonus: 25.01), PayoutRefusal.insufficientBonus);
      expect(refuse(earnings: 100.01), PayoutRefusal.insufficientEarnings);
    });

    test('a second pending request is refused before anything else', () {
      expect(
        refuse(bonus: 25.0, pending: true),
        PayoutRefusal.pendingRequestExists,
      );
    });

    test('negative amounts are refused', () {
      expect(refuse(bonus: -5.0), PayoutRefusal.negativeAmount);
    });

    test('an empty request is refused', () {
      expect(refuse(), PayoutRefusal.nothingToPayOut);
    });

    test('below the 10 SAR minimum is refused', () {
      expect(refuse(bonus: 9.99), PayoutRefusal.belowMinimum);
      expect(refuse(bonus: 10.0), isNull);
    });

    test('an empty wallet cannot be drawn against', () {
      expect(
        refuse(bonus: 1.0, balances: rebuild()),
        PayoutRefusal.insufficientBonus,
      );
    });

    test('buckets cannot be crossed to fund each other', () {
      // 25 bonus is available, but it was asked for as tips.
      expect(refuse(tips: 25.0), PayoutRefusal.insufficientTips);
    });
  });
}
