import 'package:flutter/material.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';

class ConflictDialogs {
  static Future<void> showTimeConflictDialog(
    BuildContext context, {
    required String agentName,
    required String conflictTime,
    required String conflictDate,
  }) async {
    return _showConflictDialog(
      context,
      icon: Icons.access_time_filled_rounded,
      iconColor: Colors.red,
      backgroundColor: Colors.red.shade50,
      title: AppLocalizations.of(context)!.timeConflictDetected,
      subtitle: AppLocalizations.of(context)!.agentUnavailable,
      agentName: agentName,
      conflictTime: conflictTime,
      conflictDate: conflictDate,
      warningIcon: Icons.warning_amber_rounded,
      warningLabel: AppLocalizations.of(context)!.alreadyBookedAt,
      warningMessage: AppLocalizations.of(
        context,
      )!.technicianCannotBeAssignedMultipleTimes,
    );
  }

  static Future<void> showWorkerCancelledDialog(
    BuildContext context, {
    required String agentName,
    required String conflictTime,
    required String conflictDate,
    required bool isThisBooking,
  }) async {
    return _showConflictDialog(
      context,
      icon: isThisBooking ? Icons.person_off_rounded : Icons.block_rounded,
      iconColor: isThisBooking ? Colors.orange : Colors.red,
      backgroundColor: isThisBooking
          ? Colors.orange.shade50
          : Colors.red.shade50,
      title: isThisBooking
          ? AppLocalizations.of(context)!.technicianPreviouslyCancelled
          : AppLocalizations.of(context)!.technicianRestrictedTitle,
      subtitle: isThisBooking
          ? AppLocalizations.of(context)!.thisAgentCancelledSameBookingBefore
          : AppLocalizations.of(context)!.cannotAssignCancelledTechnician,
      agentName: agentName,
      conflictTime: conflictTime,
      conflictDate: conflictDate,
      warningIcon: Icons.cancel_outlined,
      warningLabel: isThisBooking
          ? AppLocalizations.of(context)!.cancelledThisBookingOn
          : AppLocalizations.of(context)!.lastCancellationOn,
      warningMessage: isThisBooking
          ? AppLocalizations.of(context)!.agentPreviouslyCancelledWarning
          : AppLocalizations.of(context)!.technicianCancelledRestrictionMessage,
      isWarning: isThisBooking,
    );
  }

  static Future<void> _showConflictDialog(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required String agentName,
    required String conflictTime,
    required String conflictDate,
    required IconData warningIcon,
    required String warningLabel,
    required String warningMessage,
    bool isWarning = false,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(
                  backgroundColor,
                  icon,
                  iconColor,
                  title,
                  subtitle,
                  textTheme,
                ),
                _buildContent(
                  context,
                  colorScheme,
                  textTheme,
                  agentName,
                  conflictTime,
                  conflictDate,
                  warningIcon,
                  warningLabel,
                  warningMessage,
                  iconColor,
                  isWarning,
                ),
                _buildFooter(context, colorScheme, textTheme),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHeader(
    Color backgroundColor,
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: iconColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String agentName,
    String conflictTime,
    String conflictDate,
    IconData warningIcon,
    String warningLabel,
    String warningMessage,
    Color iconColor,
    bool isWarning,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _AgentInfoCard(
            agentName: agentName,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 16),
          _ConflictTimeCard(
            conflictTime: conflictTime,
            conflictDate: conflictDate,
            warningIcon: warningIcon,
            warningLabel: warningLabel,
            iconColor: iconColor,
            textTheme: textTheme,
          ),
          const SizedBox(height: 16),
          _WarningMessageCard(
            message: warningMessage,
            iconColor: isWarning ? Colors.amber : iconColor,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  static Widget _buildFooter(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, size: 18),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)?.gotIt ?? 'Got it',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentInfoCard extends StatelessWidget {
  final String agentName;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _AgentInfoCard({
    required this.agentName,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.agent ?? 'Agent',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  agentName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictTimeCard extends StatelessWidget {
  final String conflictTime;
  final String conflictDate;
  final IconData warningIcon;
  final String warningLabel;
  final Color iconColor;
  final TextTheme textTheme;

  const _ConflictTimeCard({
    required this.conflictTime,
    required this.conflictDate,
    required this.warningIcon,
    required this.warningLabel,
    required this.iconColor,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.lighten(0.45),
            iconColor.darken(0.30).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(warningIcon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Text(
                warningLabel,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  conflictTime,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  conflictDate,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: iconColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningMessageCard extends StatelessWidget {
  final String message;
  final Color iconColor;
  final TextTheme textTheme;

  const _WarningMessageCard({
    required this.message,
    required this.iconColor,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.lighten(0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: iconColor.darken(0.20),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: iconColor.darken(0.20),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorBrightness on Color {
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
