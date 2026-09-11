import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

/// Which location feature the disclosure is being shown for.
enum LocationDisclosureType {
  /// Live tracking shared with the customer during an active job.
  jobTracking,

  /// Periodic location used to match the technician with nearby job requests.
  jobOffers,
}

/// Prominent disclosure shown *before* any runtime location permission request.
///
/// Google Play requires that apps collecting location in the background explain,
/// in-app and ahead of the system permission dialog, what data is collected and
/// how it is used, with an affirmative action to continue.
class LocationDisclosureDialog extends StatelessWidget {
  const LocationDisclosureDialog({super.key, required this.type});

  final LocationDisclosureType type;

  /// Returns `true` only if the technician explicitly accepts.
  static Future<bool> show(
    BuildContext context, {
    required LocationDisclosureType type,
  }) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LocationDisclosureDialog(type: type),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final message = switch (type) {
      LocationDisclosureType.jobTracking =>
        locale?.locationDisclosureTrackingMessage ?? _fallbackTrackingMessage,
      LocationDisclosureType.jobOffers =>
        locale?.locationDisclosureJobOffersMessage ?? _fallbackJobOffersMessage,
    };

    return AlertDialog(
      backgroundColor: AppColors.bgWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.my_location_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              locale?.locationDisclosureTitle ?? _fallbackTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          message,
          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.45),
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            locale?.later ?? 'Later',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        eButton(
          context: context,
          text: locale?.continueText ?? 'Continue',
          onPressed: () => Navigator.pop(context, true),
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        ),
      ],
    );
  }
}

const _fallbackTitle = 'Location Access & Data Use';

const _fallbackTrackingMessage =
    'Abo Glumbo Technician collects your location data, including in the '
    'background when the app is closed or not in use. This location data is '
    'uploaded to our servers and shared with the customer so they can see your '
    'live location and track your arrival and job progress during an active '
    'job. Background collection runs only while you are tracking a job and '
    'stops when you stop tracking. You can change location access at any time '
    'in your device settings.';

const _fallbackJobOffersMessage =
    'Abo Glumbo Technician collects your location data, including in the '
    'background when the app is closed or not in use. This location data is '
    'uploaded to our servers and used to match you with nearby job requests '
    'and to show your current service area to our team, including the '
    'approximate city and area you are in. You can change location access at '
    'any time in your device settings.';
