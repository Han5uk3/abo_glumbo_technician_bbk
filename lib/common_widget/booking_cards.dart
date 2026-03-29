import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/warranty_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_info.dart';
import 'package:aboglumbo_bbk_panel/pages/home/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingCards extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;
  final VoidCallback? onAssign;
  final bool isWarranty;
  final bool isInAdminMode;

  BookingCards({
    super.key,
    required this.booking,
    this.isAdmin = false,
    this.onAssign,
    this.isWarranty = false,
    this.isInAdminMode = false,
  });

  Color _getStatusColor() {
    final bool bookingCancelled = isWarranty
        ? (booking.warranty?.rejectedTechnicians?.any(
                (worker) => worker.uid == LocalStore.getUID(),
              ) ??
              false)
        : booking.cancelledWorkers.any(
            (worker) => worker.uid == LocalStore.getUID(),
          );

    if (bookingCancelled) {
      return Colors.red;
    }
    if (isWarranty) {
      switch (booking.warranty!.warrantyStatusCode) {
        case "X":
          return Colors.red;
        case "E":
          return Colors.grey;
        case "R":
          return Colors.blue;
        case "S":
          return Colors.orange;
        case "C":
          return Colors.green;
        default:
          return Colors.blue;
      }
    } else {
      switch (booking.bookingStatusCode) {
        case "X":
        case "R":
        case "XC":
          return Colors.red;
        case "C":
          return Colors.green;
        default:
          return Colors.blue;
      }
    }
  }

  final TextEditingController reasonController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final addresses = booking.customer.addresses;
    AddressModel? selectedAddress =
        addresses.where((a) => a.isSelected == true).isNotEmpty
        ? addresses.firstWhere((a) => a.isSelected == true)
        : null;

    final bool bookingCancelled = booking.cancelledWorkers.any(
      (worker) => worker.uid == LocalStore.getUID(),
    );

    return GestureDetector(
      onTap: bookingCancelled
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingInfo(
                  booking: booking,
                  isAdmin: isAdmin,
                  isWarranty: isWarranty,
                  isInAdminMode: isInAdminMode,
                ),
              ),
            ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // Top section with service name and status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.localeName == 'en'
                          ? (booking.service.name ?? '')
                          : (booking.service.name_ar ?? ''),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  if (!isInAdminMode &&
                      ((!isAdmin &&
                              booking.bookingStatusCode == 'P' &&
                              !booking.cancelledWorkers.any(
                                (worker) => worker.uid == LocalStore.getUID(),
                              )) ||
                          (!isAdmin &&
                              isWarranty &&
                              booking.warranty!.warrantyStatusCode == 'R' &&
                              !(booking.warranty!.rejectedTechnicians?.any(
                                    (tech) => tech.uid == LocalStore.getUID(),
                                  ) ??
                                  false)))) ...[
                    ElevatedButton(
                      onPressed: () {
                        _showAcceptConfirmationDialog(
                          context,
                          booking,
                          isWarranty,
                        );
                      },
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        backgroundColor: WidgetStatePropertyAll(Colors.green),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.accept,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        showRejectBookingDialog(context, booking, isWarranty);
                      },
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        backgroundColor: WidgetStatePropertyAll(Colors.red),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.reject,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                  if (((isAdmin &&
                          !isWarranty &&
                          onAssign != null &&
                          booking.bookingStatusCode == 'P') ||
                      (isAdmin &&
                          isWarranty &&
                          booking.warranty!.warrantyStatusCode == 'R')) &&
                      (LocalStore.getCachedAdminData()?.accessLevel != 1))
                    OutlinedButton(
                      onPressed: onAssign,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(60, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.assign ?? 'Assign',
                      ),
                    ),
                ],
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Customer row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // (selectedAddress != null &&
                              //         selectedAddress.id.isNotEmpty)
                              //     ? (selectedAddress.fullName)
                              //     :
                              (booking.customer.name ?? ''),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (booking.customer.location != null)
                              Text(
                                (selectedAddress != null &&
                                        selectedAddress.id.isNotEmpty)
                                    ? (selectedAddress.streetName ?? '')
                                    : (booking.customer.location?.name ?? ''),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Agent row (if exists)
                  if (isAdmin && !isWarranty && booking.agent != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.support_agent,
                            size: 16,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking.agent?.name ?? '',
                            style: textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Assigned Technician row for warranty bookings
                  if (isAdmin && isWarranty) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final technician = booking.warranty?.assignedTechnician;
                        final warrantyStatusCode = booking
                            .warranty!
                            .warrantyStatusCode
                            .toLowerCase();

                        // Only show technician info for active warranties (not completed, rejected, or expired)
                        final isActiveWarranty =
                            warrantyStatusCode != 'c' && // Not completed
                            warrantyStatusCode != 'x' && // Not rejected
                            warrantyStatusCode != 'e'; // Not expired

                        // Don't show technician section for inactive warranties
                        if (!isActiveWarranty) {
                          return const SizedBox.shrink();
                        }

                        if (technician != null) {
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: colorScheme.secondaryContainer,
                                child: Icon(
                                  Icons.support_agent,
                                  size: 16,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  technician.name ?? '',
                                  style: textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }

                        // No technician assigned yet - show waiting message
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: colorScheme.errorContainer,
                              child: Icon(
                                Icons.pending_actions,
                                size: 16,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                      context,
                                    )?.waitingForAdminAction ??
                                    'Waiting for admin action',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.error,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Date info
                  Column(
                    spacing: 2,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  LocalizationHelper().formatDateLocalized(
                                    booking.bookingDateTime.toDate(),
                                    context,
                                  ),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Warranty-specific date display
                      if (isWarranty) ...[
                        if (booking.warranty?.warrantyStatusCode == 'R' &&
                            booking.warranty?.requestedOn != null)
                          Text(
                            "${AppLocalizations.of(context)!.requestedOn}: ${LocalizationHelper().formatDateLocalized(booking.warranty!.requestedOn!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (booking.warranty?.warrantyStatusCode == 'S' &&
                            booking.warranty?.acceptedAt != null)
                          Text(
                            "${AppLocalizations.of(context)!.acceptedOn}: ${LocalizationHelper().formatDateLocalized(booking.warranty!.acceptedAt!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (booking.warranty?.warrantyStatusCode == 'C' &&
                            booking.warranty?.completedAt != null)
                          Text(
                            "${AppLocalizations.of(context)!.completedOn}: ${LocalizationHelper().formatDateLocalized(booking.warranty!.completedAt!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (booking.warranty?.warrantyStatusCode == 'X' &&
                            booking.warranty?.rejectedAt != null)
                          Text(
                            "${AppLocalizations.of(context)!.rejectedOn}: ${LocalizationHelper().formatDateLocalized(booking.warranty!.rejectedAt!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (booking.warranty?.warrantyStatusCode == 'E' &&
                            booking.warranty?.expiredOn != null)
                          Text(
                            "${AppLocalizations.of(context)!.expiredOn}: ${LocalizationHelper().formatDateLocalized(booking.warranty!.expiredOn!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ]
                      // Normal booking date display
                      else ...[
                        if (booking.bookingStatusCode == 'P' &&
                            booking.cancelledWorkers.any(
                              (worker) => worker.uid != LocalStore.getUID(),
                            )) ...{
                          if (booking.createdAt != null)
                            Text(
                              "${AppLocalizations.of(context)!.bookedOn}: ${LocalizationHelper().formatDateLocalized(booking.createdAt!.toDate(), context)}",
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        } else if (booking.bookingStatusCode == 'A') ...{
                          if (booking.acceptedAt != null)
                            Text(
                              "${AppLocalizations.of(context)!.acceptedOn}: ${LocalizationHelper().formatDateLocalized(booking.acceptedAt!.toDate(), context)}",
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (isAdmin)
                            Text(
                              "${AppLocalizations.of(context)!.acceptedBy}: ${booking.agent?.name ?? ''}",
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        } else if (booking.bookingStatusCode == 'C') ...{
                          if (booking.completedAt != null)
                            if (booking.paymentCompleted == false) ...{
                              Text(
                                "${AppLocalizations.of(context)!.completedOn}: ${LocalizationHelper().formatDateLocalized(booking.completedAt!.toDate(), context)}",
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isAdmin)
                                Text(
                                  "${AppLocalizations.of(context)!.completedBy}: ${booking.agent?.name ?? ''}",
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            } else if (booking.paymentCompleted == true &&
                                booking.paymentCompletedAt != null) ...{
                              Text(
                                "${AppLocalizations.of(context)!.paymentCompletedAt}: ${LocalizationHelper().formatDateLocalized(booking.paymentCompletedAt!.toDate(), context)}",
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            },
                        } else if (booking.bookingStatusCode == 'XC') ...{
                          if (booking.cancelledAt != null)
                            Text(
                              "${AppLocalizations.of(context)!.cancelledOn}: ${LocalizationHelper().formatDateLocalized(booking.cancelledAt!.toDate(), context)}",
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            "${AppLocalizations.of(context)!.cancelledBy}: ${AppLocalizations.of(context)!.customer}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        } else if (booking.bookingStatusCode == 'XC') ...{
                          Text(
                            "${AppLocalizations.of(context)!.rejectedOn}: ${LocalizationHelper().formatDateLocalized(booking.cancelledWorkers.firstWhere((worker) => worker.uid == LocalStore.getUID()).cancelledAt.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!isAdmin)
                            Text(
                              "${AppLocalizations.of(context)!.rejectedBy}: ${AppLocalizations.of(context)!.admin}",
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        } else if (booking.bookingStatusCode == 'R') ...{
                          Text(
                            "${AppLocalizations.of(context)!.rejectedAt}: ${LocalizationHelper().formatDateLocalized(booking.rejectedAt!.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          Text(
                            "${AppLocalizations.of(context)!.rejectedBy}: ${AppLocalizations.of(context)!.admin}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        } else if (!isAdmin &&
                            booking.cancelledWorkers.any(
                              (worker) => worker.uid == LocalStore.getUID(),
                            )) ...{
                          Text(
                            "${AppLocalizations.of(context)!.rejectedOn}: ${LocalizationHelper().formatDateLocalized(booking.cancelledWorkers.firstWhere((worker) => worker.uid == LocalStore.getUID()).cancelledAt.toDate(), context)}",
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        },
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAcceptConfirmationDialog(
    BuildContext context,
    BookingModel booking,
    bool isWarranty,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.start,
          backgroundColor: Colors.white,
          title: Text(
            isWarranty
                ? AppLocalizations.of(context)!.acceptWarrantyRepair
                : AppLocalizations.of(context)!.acceptBooking,
          ),
          content: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToAcceptThisBooking,
          ),
          actions: [
            eButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              text: AppLocalizations.of(context)!.cancel,
              context: context,
              textColor: Colors.black,
              backgroundColor: Colors.white,
            ),
            eButton(
              onPressed: isWarranty
                  ? () {
                      AppFirestore.bookingsCollectionRef
                          .doc(booking.id)
                          .update({
                            'warranty.warrantyStatusCode': 'S',
                            'warranty.acceptedAt': FieldValue.serverTimestamp(),
                            'warranty.updatedAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) =>
                              Home(newIndex: 2, selectedFilter: "S"),
                        ),
                        (route) => false,
                      );
                    }
                  : () {
                      AppFirestore.bookingsCollectionRef
                          .doc(booking.id)
                          .update({
                            'bookingStatusCode': 'A',
                            'acceptedAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) =>
                              Home(newIndex: 1, selectedFilter: "A"),
                        ),
                        (route) => false,
                      );
                    },
              text: AppLocalizations.of(context)!.accept,
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.green,
            ),
          ],
        );
      },
    );
  }

  void showRejectBookingDialog(
    BuildContext context,
    BookingModel booking,
    bool isWarranty,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          actionsAlignment: MainAxisAlignment.start,
          title: Text(AppLocalizations.of(context)!.rejectBooking),
          content: isWarranty
              ? Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.areYouSureYouWantToRejectThisBooking,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.reasonforrejection,
                          hintText: AppLocalizations.of(
                            context,
                          )!.enterReasonForReject,
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
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
                    ],
                  ),
                )
              : Text(
                  AppLocalizations.of(
                    context,
                  )!.areYouSureYouWantToRejectThisBooking,
                ),
          actions: [
            eButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              text: AppLocalizations.of(context)!.cancel,
              context: context,
              textColor: Colors.black,
              backgroundColor: Colors.white,
            ),
            eButton(
              onPressed: isWarranty
                  ? () async {
                      if (formKey.currentState!.validate()) {
                        final technician = booking.warranty?.assignedTechnician;

                        if (context.mounted && technician != null) {
                          context.read<WarrantyBloc>().add(
                            CancelWarranty(
                              bookingId: booking.id,
                              technicianName: technician.name ?? "",
                              technicianPhone: technician.phone ?? "",
                              technicianUid: technician.uid ?? '',
                              rejectionReason: reasonController.text.trim(),
                            ),
                          );

                          Navigator.of(context).pop();
                        }
                      }
                    }
                  : () {
                      context.read<BookingBloc>().add(
                        CancelBooking(
                          bookingId: booking.id,
                          agentUid: booking.agent?.uid ?? '',
                          agentName: booking.agent?.name ?? '',
                        ),
                      );
                      Navigator.of(context).pop();
                    },
              text: AppLocalizations.of(context)!.reject,
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.red,
            ),
          ],
        );
      },
    );
  }
}
