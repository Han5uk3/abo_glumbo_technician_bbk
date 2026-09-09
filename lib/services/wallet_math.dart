/// Pure money arithmetic for the unified wallet.
///
/// Deliberately free of Firestore, `dart:io` and Flutter, so the payout
/// routine's numbers can be exercised directly under `flutter test`. The I/O
/// and the queries live in `UnifiedPayoutServices`; every riyal that routine
/// computes is decided here.
///
/// Two rules hold everywhere below:
///
///  * **Available = lifetime − gone.** A balance is never carried forward from
///    the stored wallet document, it is always re-derived from source data
///    minus everything that has left the wallet (approved payouts and admin
///    clears). A cache that drifts is then self-correcting.
///  * **Every amount is rounded to whole halalas.** Money is stored as
///    `double`; without rounding, `10.10 + 15.20` is `25.299999999999997` and a
///    technician is refused the exact balance the app just showed them.
library;

/// The balances a rebuild derives for one technician.
class WalletBalances {
  const WalletBalances({
    required this.availableCardTips,
    required this.availableBonus,
    required this.availableInAppEarnings,
    required this.totalAvailable,
    required this.totalTips,
    required this.cashTips,
    required this.paidTips,
    required this.totalBonus,
    required this.paidBonus,
    required this.outsideAppEarnings,
    required this.totalCompletionAmount,
    required this.lifetimeTotal,
  });

  /// Payout-requestable.
  final double availableCardTips;
  final double availableBonus;
  final double availableInAppEarnings;

  /// `availableCardTips + availableBonus + availableInAppEarnings`.
  final double totalAvailable;

  /// Display only.
  final double totalTips;
  final double cashTips;
  final double paidTips;
  final double totalBonus;
  final double paidBonus;
  final double outsideAppEarnings;
  final double totalCompletionAmount;
  final double lifetimeTotal;
}

/// Why a payout request was refused, or `null` when it is allowed.
enum PayoutRefusal {
  pendingRequestExists,
  negativeAmount,
  insufficientTips,
  insufficientBonus,
  insufficientEarnings,
  nothingToPayOut,
  belowMinimum,
}

class WalletMath {
  const WalletMath._();

  /// Smallest payout a technician may request, in SAR.
  static const double minimumPayoutSar = 10.0;

  /// Rounds to 2 decimals, half away from zero. NaN and infinity collapse to 0
  /// rather than propagating into a stored balance.
  static double money(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return (value * 100).roundToDouble() / 100;
  }

  /// Firestore has handed money back as `int`, `double` and `String` over the
  /// life of this schema, so every raw read goes through one coercion.
  static double asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) {
      final d = value.toDouble();
      return d.isNaN || d.isInfinite ? 0.0 : d;
    }
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Rounds, then floors at zero. Used for every available balance: a negative
  /// available balance is always a data problem, never a debt owed back.
  static double _atLeastZero(double value) {
    final rounded = money(value);
    return rounded < 0 ? 0.0 : rounded;
  }

  /// Rebuilds every balance from source totals.
  ///
  /// `paid*` is the sum over **approved** payout requests. `cleared*` is the
  /// cumulative total an admin has written off with "clear wallet" — recorded
  /// on the wallet, because this rebuild knows nothing of it otherwise and
  /// would hand every cleared riyal straight back on the next refresh.
  ///
  /// Pending requests are deliberately *not* subtracted: the money is still
  /// the technician's until an admin approves, and a rejected or cancelled
  /// request must leave the balance untouched. Stacking two pending requests is
  /// prevented by [refuseRequest] instead.
  static WalletBalances balances({
    required double lifetimeCardTips,
    required double lifetimeCashTips,
    required double lifetimeBonus,
    required double lifetimeInAppEarnings,
    required double lifetimeOutsideAppEarnings,
    double paidTips = 0.0,
    double paidBonus = 0.0,
    double paidEarnings = 0.0,
    double clearedTips = 0.0,
    double clearedBonus = 0.0,
    double clearedEarnings = 0.0,
  }) {
    final availableCardTips =
        _atLeastZero(lifetimeCardTips - paidTips - clearedTips);
    final availableBonus =
        _atLeastZero(lifetimeBonus - paidBonus - clearedBonus);
    final availableInAppEarnings =
        _atLeastZero(lifetimeInAppEarnings - paidEarnings - clearedEarnings);

    final totalTips = money(lifetimeCardTips + lifetimeCashTips);
    final totalBonus = money(lifetimeBonus);
    final totalCompletionAmount =
        money(lifetimeInAppEarnings + lifetimeOutsideAppEarnings);

    return WalletBalances(
      availableCardTips: availableCardTips,
      availableBonus: availableBonus,
      availableInAppEarnings: availableInAppEarnings,
      totalAvailable: money(
        availableCardTips + availableBonus + availableInAppEarnings,
      ),
      totalTips: totalTips,
      cashTips: money(lifetimeCashTips),
      // Money that has left the wallet, however it left.
      paidTips: money(paidTips + clearedTips),
      totalBonus: totalBonus,
      paidBonus: money(paidBonus + clearedBonus),
      outsideAppEarnings: money(lifetimeOutsideAppEarnings),
      totalCompletionAmount: totalCompletionAmount,
      lifetimeTotal: money(totalTips + totalBonus + totalCompletionAmount),
    );
  }

  /// The reason a payout request must be refused, or `null` to allow it.
  ///
  /// Amounts are rounded before comparison so a floating-point tail cannot
  /// refuse a technician the exact balance the wallet screen showed them.
  static PayoutRefusal? refuseRequest({
    required double tips,
    required double bonus,
    required double earnings,
    required WalletBalances balances,
    required bool hasPendingRequest,
  }) {
    if (hasPendingRequest) return PayoutRefusal.pendingRequestExists;

    final t = money(tips), b = money(bonus), e = money(earnings);
    if (t < 0 || b < 0 || e < 0) return PayoutRefusal.negativeAmount;

    if (t > balances.availableCardTips) return PayoutRefusal.insufficientTips;
    if (b > balances.availableBonus) return PayoutRefusal.insufficientBonus;
    if (e > balances.availableInAppEarnings) {
      return PayoutRefusal.insufficientEarnings;
    }

    final total = money(t + b + e);
    if (total <= 0) return PayoutRefusal.nothingToPayOut;
    if (total < minimumPayoutSar) return PayoutRefusal.belowMinimum;

    return null;
  }
}
