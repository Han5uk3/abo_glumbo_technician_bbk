import 'dart:developer';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/widgets/complete_work_bottom_sheet.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:permission_handler/permission_handler.dart';

class BookingControlsWidget extends StatefulWidget {
  final BookingModel booking;
  final bool isTracking;
  final VoidCallback? onTrackingStarted;

  static final BookingTrackerService _trackerService = BookingTrackerService();

  const BookingControlsWidget({
    super.key,
    required this.booking,
    required this.isTracking,
    this.onTrackingStarted,
  });

  @override
  State<BookingControlsWidget> createState() => _BookingControlsWidgetState();
}

class _BookingControlsWidgetState extends State<BookingControlsWidget> {
  bool isCancelBookingButtonBlocked = false;

  @override
  void initState() {
    super.initState();
    _initializeCancelButtonState();
  }

  void _initializeCancelButtonState() {
    final isCurrentlyTracking =
        BookingControlsWidget._trackerService.isTracking.value;
    setState(() {
      isCancelBookingButtonBlocked = isCurrentlyTracking;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingCancelSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bookingCancelledSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingCancelFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is BookingCompleteSuccess) {
          setState(() => isCancelBookingButtonBlocked = false);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bookingCompletedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingCompleteFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is BookingStartWorkingSuccess) {
          setState(() => isCancelBookingButtonBlocked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.startedWorkingOnBookingSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Call the callback to open directions
          widget.onTrackingStarted?.call();
        } else if (state is BookingStartWorkingFailure) {
          final isPermissionError =
              state.error.contains(
                AppLocalizations.of(
                  context,
                )!.backgroundLocationPermissionRequired,
              ) ||
              state.error.contains('Background location permission') ||
              state.error.contains('Allow all the time') ||
              state.error.contains('Background location') ||
              state.error.contains('Always Allow permission');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isPermissionError
                        ? Icons.location_off
                        : Icons.error_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPermissionError
                          ? AppLocalizations.of(
                              context,
                            )!.backgroundLocationPermissionRequired
                          : state.error.replaceAll('Exception: ', ''),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: isPermissionError ? 12 : 6),
              action: isPermissionError
                  ? SnackBarAction(
                      label: AppLocalizations.of(context)!.openSettings,
                      textColor: Colors.white,
                      onPressed: () => openAppSettings(),
                    )
                  : null,
            ),
          );
          log('start tracking error: ${state.error}');
        } else if (state is BookingStopWorkingSuccess) {
          setState(() => isCancelBookingButtonBlocked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.stopTrackingBookingSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingStopWorkingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
          log("stop tracking error: ${state.error}");
        } else if (state is BookingPauseWorkingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.trackingPausedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BookingPauseWorkingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
          log("pause tracking error: ${state.error}");
        }
      },
      builder: (context, state) {
        final isCancelLoading = state is BookingCancelLoading;
        final isCompleteLoading = state is BookingCompleteLoading;
        final isStartWorkingLoading = state is BookingStartWorkingLoading;
        final isStopWorkingLoading = state is BookingStopWorkingLoading;
        final isPauseWorkingLoading = state is BookingPauseWorkingLoading;

        return ValueListenableBuilder<bool>(
          valueListenable: BookingControlsWidget._trackerService.isTracking,
          builder: (context, serviceIsTracking, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: BookingControlsWidget._trackerService.isPaused,
              builder: (context, serviceIsPaused, child) {
                final currentTrackingBookingId =
                    BookingControlsWidget._trackerService.currentBookingId;
                final isThisBookingActive =
                    (serviceIsTracking || serviceIsPaused) &&
                    currentTrackingBookingId == widget.booking.id;

                final isThisBookingTracked =
                    serviceIsTracking &&
                    currentTrackingBookingId == widget.booking.id;

                final shouldBlockCancel = serviceIsTracking || serviceIsPaused;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (widget.booking.trackingStoppedAt == null)
                        Row(
                          children: [
                            if (!isThisBookingActive)
                              Expanded(
                                child: _buildActionButton(
                                  onPressed:
                                      shouldBlockCancel ||
                                          isCancelLoading ||
                                          isCompleteLoading ||
                                          isStartWorkingLoading ||
                                          isStopWorkingLoading ||
                                          isPauseWorkingLoading
                                      ? null
                                      : () => _showCancelBottomSheet(context),
                                  label: AppLocalizations.of(
                                    context,
                                  )!.cancelBooking,
                                  color: Colors.red,
                                  isOutlined: true,
                                  isLoading: isCancelLoading,
                                ),
                              ),
                            if (!isThisBookingActive) const SizedBox(width: 12),
                            if (isThisBookingActive)
                              Expanded(
                                child: _buildActionButton(
                                  onPressed:
                                      (isStartWorkingLoading ||
                                          isStopWorkingLoading ||
                                          isPauseWorkingLoading ||
                                          isCancelLoading ||
                                          isCompleteLoading)
                                      ? null
                                      : isThisBookingTracked
                                      ? () => _showPauseTrackingBottomSheet(
                                          context,
                                        )
                                      : () => _showResumeTrackingBottomSheet(
                                          context,
                                        ),
                                  label: isThisBookingTracked
                                      ? AppLocalizations.of(
                                          context,
                                        )!.pauseTracking
                                      : AppLocalizations.of(
                                          context,
                                        )!.resumeTracking,
                                  color: Colors.orange,
                                  isOutlined: true,
                                  isLoading: isPauseWorkingLoading,
                                ),
                              ),
                            if (isThisBookingActive) const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                onPressed:
                                    (isStartWorkingLoading ||
                                        isStopWorkingLoading ||
                                        isPauseWorkingLoading ||
                                        isCancelLoading ||
                                        isCompleteLoading ||
                                        ((serviceIsTracking ||
                                                serviceIsPaused) &&
                                            BookingControlsWidget
                                                    ._trackerService
                                                    .currentBookingId !=
                                                widget.booking.id))
                                    ? null
                                    : isThisBookingActive
                                    ? () =>
                                          _showStopTrackingBottomSheet(context)
                                    : () => _showStartTrackingBottomSheet(
                                        context,
                                      ),
                                label: isThisBookingActive
                                    ? AppLocalizations.of(
                                        context,
                                      )!.arrivedAtLocation
                                    : AppLocalizations.of(
                                        context,
                                      )!.startTracking,
                                fontSize: isThisBookingActive ? 12 : 12,
                                color: isThisBookingActive
                                    ? Colors.green
                                    : AppColors.blue1,
                                isOutlined: true,
                                isLoading:
                                    isStartWorkingLoading ||
                                    isStopWorkingLoading,
                              ),
                            ),
                          ],
                        ),
                      if (widget.booking.trackingStoppedAt != null)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (isCompleteLoading)
                                ? null
                                : () => _showCompleteWorkBottomSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isCompleteLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!.completeWork,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required String label,
    required Color color,
    bool isOutlined = false,
    bool isLoading = false,
    double fontSize = 12,
  }) {
    final isDisabled = onPressed == null;
    final baseColor = isDisabled ? Colors.grey : color;

    return SizedBox(
      height: 48,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: baseColor.withOpacity(0.3)),
                backgroundColor: baseColor.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: baseColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: baseColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: baseColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
    );
  }

  void _showCancelBottomSheet(BuildContext context) {
    _showAppBottomSheet(
      context: context,
      icon: Icons.cancel_outlined,
      iconColor: Colors.red,
      title: AppLocalizations.of(context)!.cancelBooking,
      message: AppLocalizations.of(
        context,
      )!.areYouSureYouWantToCancelThisBooking,
      primaryActionLabel: AppLocalizations.of(context)!.yes,
      primaryAction: () {
        Navigator.of(context).pop();
        context.read<BookingBloc>().add(
          CancelBooking(
            bookingId: widget.booking.id,
            agentUid: widget.booking.agent?.uid ?? '',
            agentName: widget.booking.agent?.name ?? '',
          ),
        );
      },
      secondaryActionLabel: AppLocalizations.of(context)!.no,
    );
  }

  void _showStartTrackingBottomSheet(BuildContext context) {
    _showAppBottomSheet(
      context: context,
      icon: Icons.play_circle_outline,
      iconColor: AppColors.blue1,
      title: AppLocalizations.of(context)!.startTracking,
      message: AppLocalizations.of(
        context,
      )!.areYouSureYouWantToStartTrackingThisBooking,
      primaryActionLabel: AppLocalizations.of(context)!.yes,
      primaryAction: () {
        Navigator.of(context).pop();
        context.read<BookingBloc>().add(
          StartWorkingOnBooking(
            bookingId: widget.booking.id,
            uid: widget.booking.agent?.uid ?? '',
            context: context,
          ),
        );
      },
      secondaryActionLabel: AppLocalizations.of(context)!.no,
    );
  }

  void _showStopTrackingBottomSheet(BuildContext context) {
    _showAppBottomSheet(
      context: context,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      title: AppLocalizations.of(context)!.arrivedAtLocation,
      message: AppLocalizations.of(
        context,
      )!.areYouSureYouWantToStopTrackingThisBooking,
      primaryActionLabel: AppLocalizations.of(context)!.yes,
      primaryAction: () {
        Navigator.of(context).pop();
        context.read<BookingBloc>().add(
          StopWorkingOnBooking(bookingId: widget.booking.id),
        );
      },
      secondaryActionLabel: AppLocalizations.of(context)!.no,
    );
  }

  void _showPauseTrackingBottomSheet(BuildContext context) {
    _showAppBottomSheet(
      context: context,
      icon: Icons.pause_circle_outline,
      iconColor: Colors.orange,
      title: AppLocalizations.of(context)!.pauseTracking,
      message: AppLocalizations.of(
        context,
      )!.areYouSureYouWantToPauseTrackingThisBooking,
      primaryActionLabel: AppLocalizations.of(context)!.yes,
      primaryAction: () {
        Navigator.of(context).pop();
        context.read<BookingBloc>().add(
          PauseWorkingOnBooking(bookingId: widget.booking.id),
        );
      },
      secondaryActionLabel: AppLocalizations.of(context)!.no,
    );
  }

  void _showResumeTrackingBottomSheet(BuildContext context) {
    _showAppBottomSheet(
      context: context,
      icon: Icons.play_circle_outline,
      iconColor: AppColors.blue1,
      title: AppLocalizations.of(context)!.resumeTracking,
      message: AppLocalizations.of(
        context,
      )!.areYouSureYouWantToStartTrackingThisBooking,
      primaryActionLabel: AppLocalizations.of(context)!.yes,
      primaryAction: () {
        Navigator.of(context).pop();
        context.read<BookingBloc>().add(
          StartWorkingOnBooking(
            bookingId: widget.booking.id,
            uid: widget.booking.agent?.uid ?? '',
            context: context,
          ),
        );
      },
      secondaryActionLabel: AppLocalizations.of(context)!.no,
    );
  }

  void _showCompleteWorkBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompleteWorkBottomSheet(booking: widget.booking),
    );
  }

  void _showAppBottomSheet({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String primaryActionLabel,
    required VoidCallback primaryAction,
    String? secondaryActionLabel,
    VoidCallback? secondaryAction,
    String? additionalActionLabel,
    VoidCallback? additionalAction,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]!),
              ),
              const SizedBox(height: 32),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Addtional Action (e.g. Propose New Time) - Full Width & Prominent
                  if (additionalActionLabel != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: additionalAction,
                        icon: const Icon(Icons.history_toggle_off, size: 20),
                        label: Text(
                          additionalActionLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Primary and Secondary Actions in a Row
                  Row(
                    children: [
                      // Secondary Action (No/Cancel)
                      if (secondaryActionLabel != null)
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed:
                                  secondaryAction ??
                                  () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                secondaryActionLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (secondaryActionLabel != null)
                        const SizedBox(width: 12),

                      // Primary Action (Yes/Confirm)
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: primaryAction,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: iconColor,
                              side: BorderSide(
                                color: iconColor.withOpacity(0.5),
                              ),
                              backgroundColor: iconColor.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              primaryActionLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
