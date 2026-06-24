import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';

/// Welcome modal for technicians with availability disabled
class TechnicianWelcomeModal extends StatelessWidget {
  final String technicianName;
  final VoidCallback onEnableAvailability;

  const TechnicianWelcomeModal({
    super.key,
    required this.technicianName,
    required this.onEnableAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.welcomeToAboGlumboTechnician(technicianName),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.welcomeDescription,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                    textAlign: TextAlign.start,
                  ),

                  const SizedBox(height: 32),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onEnableAvailability,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.enableAvailability,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the technician welcome modal
  static Future<void> show(
    BuildContext context, {
    required String technicianName,
    required VoidCallback onEnableAvailability,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TechnicianWelcomeModal(
        technicianName: technicianName,
        onEnableAvailability: onEnableAvailability,
      ),
    );
  }
}
