import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/widgets/counter_propose_sheet.dart';
import 'package:flutter/material.dart';

class CounterOfferUtils {
  static Future<void> showCounterOfferDatePicker(BuildContext context, BookingModel booking) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CounterProposeSheet(booking: booking),
    );
  }

  static Future<void> handleCounterOfferResponse(BuildContext context, BookingModel booking, String response) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final bool success = await AppServices.respondToCounterOffer(
      booking: booking,
      response: response,
    );

    if (context.mounted) {
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? AppLocalizations.of(context)!.counterOfferResponse
              : 'Failed to process response',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
