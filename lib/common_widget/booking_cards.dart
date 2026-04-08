import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_info.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';

// Renamed to BookingListTileWidget to match customer side standardized naming
class BookingListTileWidget extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;
  final VoidCallback? onAssign;
  final bool isWarranty;
  final bool isInAdminMode;

  const BookingListTileWidget({
    super.key,
    required this.booking,
    this.isAdmin = false,
    this.onAssign,
    this.isWarranty = false,
    this.isInAdminMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final addresses = booking.customer.addresses;
    AddressModel? selectedAddress =
        addresses.where((a) => a.isSelected == true).isNotEmpty
        ? addresses.firstWhere((a) => a.isSelected == true)
        : addresses.isNotEmpty
        ? addresses.first
        : null;

    final bool bookingCancelled = booking.cancelledWorkers.any(
      (worker) => worker.uid == LocalStore.getUID(),
    );

    final localization = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

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
        width: double.maxFinite,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(16), // Increased for premium feel
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section (Service Info)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            (booking.service.image != null &&
                                booking.service.image!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: booking.service.image!,
                                height: 48,
                                width: 48,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 48,
                                  width: 48,
                                  color: Colors.grey[100],
                                  child: Center(child: Loader()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 48,
                                  width: 48,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Container(
                                height: 48,
                                width: 48,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "#${booking.id}",
                                style: DMSansFont.textStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (isWarranty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    localization.warranty.toUpperCase(),
                                    style: DMSansFont.textStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locale == 'en'
                                ? (booking.service.name ?? '')
                                : (booking.service.name_ar ?? ''),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DMSansFont.textStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isWarranty
                              ? "0.0" // Warranty repairs are free
                              : "${(booking.bookingStatusCode == "C" || booking.bookingStatusCode == "VP") ? ((booking.completionData?.totalCost ?? 0) + (booking.service.price ?? 0)).toStringAsFixed(1) : (booking.service.price ?? 0).toStringAsFixed(1)}",
                          style: DMSansFont.textStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          localization.sar,
                          style: DMSansFont.textStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details Section
            _buildDetailTile(
              Icons.person_outline_rounded,
              booking.customer.name ?? '',
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildDetailTile(
              Icons.location_on_outlined,
              (selectedAddress != null && selectedAddress.id.isNotEmpty)
                  ? (selectedAddress.streetName ?? '')
                  : (booking.customer.location?.fullAddress ?? 'N/A'),
              color: Colors.grey[600],
            ),

            if (isAdmin && !isWarranty && booking.agent != null) ...[
              const SizedBox(height: 8),
              _buildDetailTile(
                Icons.handyman_outlined,
                booking.agent?.name ?? '',
                prefix: "${localization.technicianName}: ",
                color: Colors.grey[600],
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(thickness: 1, height: 1, color: Color(0xffF0F0F0)),
            ),

            // Footer Section
            Row(
              children: [
                Expanded(child: _buildTimestamp(context)),

                // Action Buttons or Status Badge
                if (isAdmin &&
                    ((!isWarranty &&
                            onAssign != null &&
                            booking.bookingStatusCode == 'P') ||
                        (isWarranty &&
                            booking.warranty!.warrantyStatusCode == 'R')) &&
                    (LocalStore.getCachedAdminData()?.accessLevel != 1))
                  _buildActionButton(
                    label: localization.assign,
                    color: AppColors.primary,
                    onPressed: onAssign!,
                  )
                else
                  _buildStatusBadge(context, localization),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String text, {
    bool isBold = false,
    String? prefix,
    Color? color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: (color ?? Colors.grey[600]!).withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: DMSansFont.textStyle(
                fontSize: 12,
                color: color ?? Colors.black,
              ),
              children: [
                if (prefix != null)
                  TextSpan(
                    text: prefix,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                TextSpan(
                  text: text,
                  style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 36,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                label,
                style: DMSansFont.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                label,
                style: DMSansFont.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    AppLocalizations localization,
  ) {
    if (booking.bookingStatusCode == 'VP') {
      return _statusBadge(
        localization.verificationPending.toUpperCase(),
        Colors.orange,
      );
    }

    final bool currentTechCancelled = isWarranty
        ? (booking.warranty?.rejectedTechnicians?.any(
                (worker) => worker.uid == LocalStore.getUID(),
              ) ??
              false)
        : booking.cancelledWorkers.any(
            (worker) => worker.uid == LocalStore.getUID(),
          );

    if (currentTechCancelled) {
      return _statusBadge(localization.rejected.toUpperCase(), Colors.red);
    }

    String label = '';
    Color color = Colors.grey;

    if (isWarranty) {
      final status = booking.warranty!.warrantyStatusCode;
      switch (status) {
        case 'C':
          label = localization.completed;
          color = Colors.green;
          break;
        case 'X':
          label = localization.rejected;
          color = Colors.red;
          break;
        case 'E':
          label = localization.expired;
          color = Colors.grey;
          break;
        case 'S':
          label = localization.accepted;
          color = Colors.green;
          break;
        case 'A':
          label = localization.requested;
          color = AppColors.blue1;
          break;
      }
    } else {
      switch (booking.bookingStatusCode) {
        case 'C':
          label = localization.completed;
          color = Colors.green;
          break;
        case 'X':
        case 'XC':
        case 'R':
          label = localization.canceled;
          color = Colors.red;
          break;
        case 'A':
          label = localization.accepted;
          color = Colors.green;
          break;
        case 'P':
          label = localization.pending;
          color = Colors.orange;
          break;
      }
    }

    if (label.isEmpty) return const SizedBox.shrink();
    return _statusBadge(label.toUpperCase(), color);
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: DMSansFont.textStyle(
          fontWeight: FontWeight.bold,
          fontSize: 9,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    String text = '';
    final localization = AppLocalizations.of(context)!;

    if (isWarranty) {
      final warranty = booking.warranty;
      if (warranty != null) {
        final statusCode = warranty.warrantyStatusCode;
        if (statusCode == 'R' && warranty.requestedOn != null) {
          text =
              "${localization.requestedOn}: ${LocalizationHelper().formatDateLocalized(warranty.requestedOn!.toDate(), context)}";
        } else if (statusCode == 'S' && warranty.acceptedAt != null) {
          text =
              "${localization.acceptedOn}: ${LocalizationHelper().formatDateLocalized(warranty.acceptedAt!.toDate(), context)}";
        } else if (statusCode == 'C' && warranty.completedAt != null) {
          text =
              "${localization.completedOn}: ${LocalizationHelper().formatDateLocalized(warranty.completedAt!.toDate(), context)}";
        } else if (statusCode == 'X' && warranty.rejectedAt != null) {
          text =
              "${localization.rejectedOn}: ${LocalizationHelper().formatDateLocalized(warranty.rejectedAt!.toDate(), context)}";
        } else if (warranty.createdAt != null) {
          text =
              "${localization.bookedOn}: ${LocalizationHelper().formatDateLocalized(warranty.createdAt!.toDate(), context)}";
        }
      }
    } else {
      if (booking.bookingStatusCode == 'P' && booking.createdAt != null) {
        text =
            "${localization.bookedOn}: ${LocalizationHelper().formatDateLocalized(booking.createdAt!.toDate(), context)}";
      } else if (booking.bookingStatusCode == 'A' &&
          booking.acceptedAt != null) {
        text =
            "${localization.acceptedOn}: ${LocalizationHelper().formatDateLocalized(booking.acceptedAt!.toDate(), context)}";
      } else if (booking.bookingStatusCode == 'C' &&
          booking.completedAt != null) {
        text =
            "${localization.completedOn}: ${LocalizationHelper().formatDateLocalized(booking.completedAt!.toDate(), context)}";
      } else if ((booking.bookingStatusCode == 'X' ||
              booking.bookingStatusCode == 'XC' ||
              booking.bookingStatusCode == 'R') &&
          booking.cancelledAt != null) {
        text =
            "${localization.cancelledOn}: ${LocalizationHelper().formatDateLocalized(booking.cancelledAt!.toDate(), context)}";
      } else if (booking.bookingStatusCode == 'VP' &&
          booking.paymentCompletedAt != null) {
        text =
            "${localization.paymentCompletedAt}: ${LocalizationHelper().formatDateLocalized(booking.paymentCompletedAt!.toDate(), context)}";
      }
    }

    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[400]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: DMSansFont.textStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}

// Removed backward-compatibility typedef as all usages have been updated.
