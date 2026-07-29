import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/time_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class LocalizationHelper {
  String localizedBookingStatus(
    String bookingStatus, {
    required BuildContext context,
  }) {
    switch (bookingStatus.toLowerCase()) {
      case 'offers':
        return AppLocalizations.of(context)!.offers;
      case 'pending':
        return AppLocalizations.of(context)!.pending;
      case 'accepted':
      case 'confirmed':
        return AppLocalizations.of(context)!.accepted;
      case 'rejected':
        return AppLocalizations.of(context)!.rejected;
      case 'completed':
        return AppLocalizations.of(context)!.completed;
      case 'cancelled':
        return AppLocalizations.of(context)!.cancelled;
      case 'payment pending':
        return AppLocalizations.of(context)!.paymentPending;
      case 'ready_to_assign':
        return AppLocalizations.of(context)!.assigningTechnician;
      case 'timed_out':
        return AppLocalizations.of(context)!.timedOut;
      case 'not_found':
        return AppLocalizations.of(context)!.technicianNotFound;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }

  /// Renders in **Saudi time**, like every other formatter in the app.
  ///
  /// [date] is an absolute instant (typically `Timestamp.toDate()`, which comes
  /// back in the device's zone); it is converted to the Saudi wall clock here so
  /// a booking reads the same on a phone in Riyadh and a phone anywhere else.
  /// See [KsaTime].
  String formatDateLocalized(DateTime instant, BuildContext context) {
    final date = KsaTime.fromInstant(instant);
    final locale = Localizations.localeOf(context).languageCode;
    String formatted;
    if (locale == 'ar') {
      // Use Arabic date format and convert numbers
      formatted = intl.DateFormat('EEEE، d MMMM y - h:mm a', 'ar').format(date);
      // Convert Western digits to Arabic-Indic digits
      formatted = formatted.replaceAllMapped(RegExp(r'[0-9]'), (match) {
        const arabicNumbers = [
          '٠',
          '١',
          '٢',
          '٣',
          '٤',
          '٥',
          '٦',
          '٧',
          '٨',
          '٩',
        ];
        return arabicNumbers[int.parse(match.group(0)!)];
      });
    } else if (locale == 'ur') {
      // Use Urdu date format
      formatted = intl.DateFormat('EEEE، d MMMM y - h:mm a', 'ur').format(date);
    } else {
      formatted = intl.DateFormat('EEE, MMM d, y - h:mm a').format(date);
    }
    return formatted;
  }

  /// Formats date time as dd/MM/yy, hh:mm AM/PM (localized AM/PM), in KSA time.
  /// [instant] is an absolute instant; see [formatDateLocalized].
  String formatDateTimeCompact(DateTime instant, BuildContext context) {
    final date = KsaTime.fromInstant(instant);
    final locale = Localizations.localeOf(context).languageCode;
    String formatted = intl.DateFormat(
      'dd/MM/yy, hh:mm a',
      locale,
    ).format(date);

    if (locale == 'ar') {
      formatted = formatted.replaceAllMapped(RegExp(r'[0-9]'), (match) {
        const arabicNumbers = [
          '٠',
          '١',
          '٢',
          '٣',
          '٤',
          '٥',
          '٦',
          '٧',
          '٨',
          '٩',
        ];
        return arabicNumbers[int.parse(match.group(0)!)];
      });
    }
    return formatted;
  }

  String getLocalizedBookingStatus(String status, BuildContext context) {
    switch (status.toUpperCase()) {
      case 'P':
        return AppLocalizations.of(context)!.pending;
      case 'A':
        return AppLocalizations.of(context)!.accepted;
      case 'CP':
        return AppLocalizations.of(context)!.paymentPending;
      case 'C':
        return AppLocalizations.of(context)!.completed;
      case 'X':
      case 'XC':
        return AppLocalizations.of(context)!.cancelled;
      case 'VP':
        return AppLocalizations.of(context)!.verificationPending;
      default:
        return status;
    }
  }
}
