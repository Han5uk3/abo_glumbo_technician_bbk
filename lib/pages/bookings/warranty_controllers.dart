import 'dart:developer';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/warranty_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/location_services.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:permission_handler/permission_handler.dart';

class WarrantyControlsWidget extends StatefulWidget {
  final BookingModel booking;
  final bool isTracking;
  final bool isAdmin;
  final VoidCallback? onTrackingStarted;

  static final BookingTrackerService _trackerService = BookingTrackerService();

  const WarrantyControlsWidget({
    super.key,
    required this.booking,
    required this.isTracking,
    required this.isAdmin,
    this.onTrackingStarted,
  });

  @override
  State<WarrantyControlsWidget> createState() => _WarrantyControlsWidgetState();
}

class _WarrantyControlsWidgetState extends State<WarrantyControlsWidget> {
  bool isCancelButtonBlocked = false;

  @override
  void initState() {
    super.initState();
    _initializeCancelButtonState();
  }

  final formKey = GlobalKey<FormState>();
  final reasonController = TextEditingController();
  void _initializeCancelButtonState() {
    final isCurrentlyTracking =
        WarrantyControlsWidget._trackerService.isTracking.value;
    setState(() {
      isCancelButtonBlocked = isCurrentlyTracking;
    });
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WarrantyBloc, WarrantyState>(
      listener: (context, state) {
        if (state is WarrantyCancelSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.bookingCancelledSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is WarrantyCancelFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is WarrantyCompleteSuccess) {
          setState(() => isCancelButtonBlocked = false);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.warrantyRepairCompleted,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is WarrantyCompleteFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is WarrantyStartWorkingSuccess) {
          setState(() => isCancelButtonBlocked = true);
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
        } else if (state is WarrantyStartWorkingFailure) {
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
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 6),
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
        } else if (state is WarrantyStopWorkingSuccess) {
          setState(() => isCancelButtonBlocked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.stopTrackingBookingSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is WarrantyStopWorkingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
          log("stop tracking error: ${state.error}");
        } else if (state is WarrantyPauseWorkingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.trackingPausedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is WarrantyPauseWorkingFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
          log("pause tracking error: ${state.error}");
        }
      },
      builder: (context, state) {
        final isCancelLoading = state is WarrantyCancelLoading;
        final isCompleteLoading = state is WarrantyCompleteLoading;
        final isStartWorkingLoading = state is WarrantyStartWorkingLoading;
        final isStopWorkingLoading = state is WarrantyStopWorkingLoading;
        final isPauseWorkingLoading = state is WarrantyPauseWorkingLoading;

        return ValueListenableBuilder<bool>(
          valueListenable: WarrantyControlsWidget._trackerService.isTracking,
          builder: (context, serviceIsTracking, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: WarrantyControlsWidget._trackerService.isPaused,
              builder: (context, serviceIsPaused, child) {
                final currentTrackingBookingId =
                    WarrantyControlsWidget._trackerService.currentBookingId;
                final isThisBookingActive =
                    (serviceIsTracking || serviceIsPaused) &&
                    currentTrackingBookingId == widget.booking.id;

                final isThisBookingTracked =
                    serviceIsTracking &&
                    currentTrackingBookingId == widget.booking.id;

                final shouldBlockCancel = serviceIsTracking || serviceIsPaused;

                // Check warranty status
                final warrantyStatus =
                    widget.booking.warranty?.warrantyStatusCode ?? '';
                final isWarrantyStarted = warrantyStatus == 'S' || warrantyStatus == 'R';

                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Only show tracking and cancel buttons if warranty is started
                      if (isWarrantyStarted &&
                          widget.booking.trackingStoppedAt == null) ...[
                        Row(
                          children: [
                            if (!isThisBookingActive)
                              Expanded(
                                child: _buildButton(
                                  onPressed:
                                      shouldBlockCancel ||
                                          isCancelLoading ||
                                          isCompleteLoading ||
                                          isStartWorkingLoading ||
                                          isStopWorkingLoading ||
                                          isPauseWorkingLoading
                                      ? null
                                      : () => _showCancelBottomSheet(context),
                                  label: AppLocalizations.of(context)!.cancel,
                                  color: shouldBlockCancel
                                      ? Colors.grey
                                      : Colors.red.shade50,
                                  textColor: shouldBlockCancel
                                      ? Colors.grey.shade700
                                      : Colors.red.shade700,
                                  borderColor: shouldBlockCancel
                                      ? Colors.grey.shade200
                                      : Colors.red.shade200,
                                  isLoading: isCancelLoading,
                                ),
                              ),
                            if (!isThisBookingActive) const SizedBox(width: 12),
                            if (isThisBookingActive)
                              Expanded(
                                child: _buildButton(
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
                                  color: Colors.orange.shade50,
                                  textColor: Colors.orange.shade700,
                                  borderColor: Colors.orange.shade200,
                                  isLoading: isPauseWorkingLoading,
                                ),
                              ),
                            if (isThisBookingActive) const SizedBox(width: 12),
                            Expanded(
                              child: _buildButton(
                                onPressed:
                                    (isStartWorkingLoading ||
                                        isStopWorkingLoading ||
                                        isPauseWorkingLoading ||
                                        isCancelLoading ||
                                        isCompleteLoading ||
                                        ((serviceIsTracking ||
                                                serviceIsPaused) &&
                                            WarrantyControlsWidget
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
                                color: isThisBookingActive
                                    ? Colors.green.shade50
                                    : Colors.blue.shade50,
                                textColor: isThisBookingActive
                                    ? Colors.green.shade700
                                    : Colors.blue.shade700,
                                borderColor: isThisBookingActive
                                    ? Colors.green.shade200
                                    : Colors.blue.shade200,
                                isLoading:
                                    isStartWorkingLoading ||
                                    isStopWorkingLoading,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Complete work button (free for warranty)
                      if (isWarrantyStarted &&
                          widget.booking.trackingStoppedAt != null)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (isCompleteLoading)
                                ? null
                                : () =>
                                      _showCompleteWarrantyBottomSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isCompleteLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.completeWarrantyRepair,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
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

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    required Color color,
    required Color textColor,
    required Color borderColor,
    bool isLoading = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.grey.shade100 : color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: onPressed == null ? Colors.grey.shade300 : borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: onPressed == null
                          ? Colors.grey.shade500
                          : textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  void _showCancelBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Icon

                      // Title
                      Text(
                        AppLocalizations.of(context)!.cancelWarrantyRepair,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.areYouSureYouWantToCancelThisWarrantyRepairThisActionCannotBeUndone,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Reason input field
                      TextFormField(
                        controller: reasonController,
                        autofocus: false,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          labelText: AppLocalizations.of(
                            context,
                          )!.reasonforrejection,
                          hintText: AppLocalizations.of(
                            context,
                          )!.enterReasonForReject,
                          border: const OutlineInputBorder(),
                          errorMaxLines: 2,
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(
                              context,
                            )!.pleaseProvideARejectionReason;
                          }
                          if (value.trim().length < 10) {
                            return AppLocalizations.of(
                              context,
                            )!.reasonMustBeAtLeast10Characters;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 34),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                reasonController.clear();
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.no,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                try {
                                  final technician = widget
                                      .booking
                                      .warranty
                                      ?.assignedTechnician;

                                  if (technician == null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.noTechnicianAssigned,
                                          ),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                    return;
                                  }

                                  if (context.mounted) {
                                    context.read<WarrantyBloc>().add(
                                      CancelWarranty(
                                        bookingId: widget.booking.id,
                                        technicianUid: technician.uid ?? '',
                                        technicianName: technician.name ?? '',
                                        technicianPhone: technician.phone ?? '',
                                        rejectionReason: reasonController.text
                                            .trim(),
                                      ),
                                    );

                                    reasonController.clear();
                                    Navigator.of(context).pop();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(
                                                context,
                                              )?.errorOccurred(e.toString()) ??
                                              'Error: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.yes,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStartTrackingBottomSheet(BuildContext context) {
    final trackerService = WarrantyControlsWidget._trackerService;
    if (trackerService.isTracking.value &&
        trackerService.currentBookingId != null &&
        trackerService.currentBookingId != widget.booking.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.anotherBookingIsAlreadyBeingTracked,
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(
                Icons.play_circle_outline,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.startTracking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.areYouSureYouWantToStartTrackingThisWarrantyRepair,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(bottomSheetContext).pop();
                        final uid = LocalStore.getUID();
                        if (uid != null) {
                          parentContext.read<WarrantyBloc>().add(
                            StartWorkingOnWarranty(
                              context: parentContext,
                              bookingId: widget.booking.id,
                              uid: uid,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStopTrackingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(
                Icons.check_circle_outline,
                size: 60,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.arrivedAtLocation,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.areYouSureYouWantToStopTrackingThisWarrantyRepair,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<WarrantyBloc>().add(
                          StopWorkingOnWarranty(bookingId: widget.booking.id),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPauseTrackingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(
                Icons.pause_circle_outline,
                size: 60,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.pauseTracking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.areYouSureYouWantToPauseTrackingThisBooking,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.read<WarrantyBloc>().add(
                          PauseWorkingOnWarranty(bookingId: widget.booking.id),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResumeTrackingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(
                Icons.play_circle_outline,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.resumeTracking,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.areYouSureYouWantToStartTrackingThisBooking,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final uid = LocalStore.getUID();
                        if (uid != null) {
                          context.read<WarrantyBloc>().add(
                            StartWorkingOnWarranty(
                              context: context,
                              bookingId: widget.booking.id,
                              uid: uid,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.yes,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompleteWarrantyBottomSheet(BuildContext context) {
    final trackerService = WarrantyControlsWidget._trackerService;
    if (trackerService.isTracking.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.cannotCompleteBookingWhileTracking,
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(
                Icons.check_circle_outline,
                size: 60,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.completeWarrantyRepair,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(
                  context,
                )!.areYouSureYouWantToCompleteThisWarrantyRepairThisIsAFreeService,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.no,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Trigger complete warranty event
                        context.read<WarrantyBloc>().add(
                          CompleteWarranty(bookingId: widget.booking.id),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.complete,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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
