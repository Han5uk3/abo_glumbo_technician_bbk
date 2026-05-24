import 'dart:async';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/broadcast_offer_info.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_info.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/widgets/counter_propose_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Renamed to BookingListTileWidget to match customer side standardized naming
class BookingListTileWidget extends StatelessWidget {
  final BookingModel booking;
  final bool isAdmin;
  final VoidCallback? onAssign;
  final bool isWarranty;
  final Widget? actionOverride;
  final String? offerId;
  final bool isFromOffersTab;

  const BookingListTileWidget({
    super.key,
    required this.booking,
    this.isAdmin = false,
    this.onAssign,
    this.isWarranty = false,
    this.actionOverride,
    this.offerId,
    this.isFromOffersTab = false,
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

    final bool isCurrentlyAssignedToMe = isWarranty
        ? booking.warranty?.assignedTechnician?.uid == LocalStore.getUID()
        : booking.agent?.uid == LocalStore.getUID();

    final bool currentTechCancelled = isWarranty
        ? (booking.warranty?.rejectedTechnicians?.any(
                (worker) => worker.uid == LocalStore.getUID(),
              ) ??
              false)
        : booking.cancelledWorkers.any(
            (worker) => worker.uid == LocalStore.getUID(),
          );

    final localization = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return GestureDetector(
      onTap: (currentTechCancelled && !isCurrentlyAssignedToMe)
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingInfo(
                  booking: booking,
                  isAdmin: isAdmin,
                  isWarranty: isWarranty,
                  offerId: offerId,
                  isFromOffersTab: isFromOffersTab,
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
                            booking.service.nameLocalized(languageCode: locale) ??
                                booking.service.name ??
                                '',
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
                              : (booking.bookingStatusCode == "C" ||
                                    booking.bookingStatusCode == "VP")
                              ? ((booking.completionData?.totalCost ?? 0) +
                                        (booking.service.price ?? 0))
                                    .toStringAsFixed(1)
                              : (booking.service.price ?? 0).toStringAsFixed(1),
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

            if (isAdmin && !isWarranty) ...[
              if (booking.agent != null) ...[
                const SizedBox(height: 8),
                _buildDetailTile(
                  Icons.handyman_outlined,
                  booking.agent?.name ?? '',
                  prefix: "${localization.technicianName}: ",
                  color: Colors.grey[600],
                ),
              ] else if (booking.bookingStatusCode == 'P') ...[
                const SizedBox(height: 8),
                _buildDetailTile(
                  Icons.warning_amber_rounded,
                  localization.noTechnicianAssigned,
                  color: Colors.orange[700],
                  isBold: true,
                ),
              ],
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
                if (actionOverride != null)
                  actionOverride!
                else if (isAdmin &&
                    onAssign != null &&
                    (booking.bookingStatusCode == 'P' ||
                        booking.bookingStatusCode == 'A' ||
                        (isWarranty &&
                            (booking.warranty!.warrantyStatusCode == 'R' ||
                                booking.warranty!.warrantyStatusCode ==
                                    'S'))) &&
                    (LocalStore.getCachedAdminData()?.hasFullAccess ?? true))
                  _buildActionButton(
                    label:
                        (booking.bookingStatusCode == 'A' ||
                            (isWarranty &&
                                booking.warranty?.warrantyStatusCode == 'S'))
                        ? localization.change
                        : localization.assign,
                    color: AppColors.primary,
                    onPressed: onAssign!,
                  )
                else
                  _buildStatusBadge(
                    context,
                    localization,
                    currentTechCancelled,
                    isCurrentlyAssignedToMe,
                  ),
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
    bool currentTechCancelled,
    bool isCurrentlyAssignedToMe,
  ) {
    if (booking.bookingStatusCode == 'VP') {
      return _statusBadge(
        localization.paymentPending.toUpperCase(),
        Colors.orange,
      );
    }

    if (currentTechCancelled && !isCurrentlyAssignedToMe) {
      return _statusBadge(localization.rejected.toUpperCase(), Colors.red);
    }

    String label = '';
    Color color = Colors.grey;

    if (isWarranty) {
      final status = booking.warranty!.warrantyStatusCode.toUpperCase();

      // Client-side expiration check for Active or Rejected
      final bool isExpired =
          (status == 'A' || status == 'X') && _calculateDaysLeft(booking) <= 0;

      if (isExpired) {
        label = localization.expired;
        color = Colors.grey;
      } else {
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
      }
    } else {
      switch (booking.bookingStatusCode) {
        case 'C':
          if (booking.paymentCompleted == false) {
            label = localization.paymentPending;
            color = Colors.orange;
          } else {
            label = localization.completed;
            color = Colors.green;
          }
          break;
        case 'CP':
          label = localization.paymentPending;
          color = Colors.orange;
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
          if (booking.autoAssignmentStatus == 'ready_to_assign') {
            label = localization.assigningTechnician;
            color = AppColors.primary;
          } else {
            label = localization.pending;
            color = Colors.orange;
          }
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

  int _calculateDaysLeft(BookingModel booking) {
    final warranty = booking.warranty;
    if (warranty == null || warranty.createdAt == null) return 0;

    final expiryDate =
        warranty.expiredOn?.toDate() ??
        warranty.createdAt!.toDate().add(const Duration(days: 7));
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    return difference < 0 ? 0 : difference;
  }

  Widget _buildTimestamp(BuildContext context) {
    String text = '';
    if (isWarranty) {
      final warranty = booking.warranty;
      if (warranty != null) {
        final statusCode = warranty.warrantyStatusCode;
        if (statusCode == 'R' && warranty.requestedOn != null) {
          text = LocalizationHelper().formatDateTimeCompact(
            warranty.requestedOn!.toDate(),
            context,
          );
        } else if (statusCode == 'S' && warranty.acceptedAt != null) {
          text = LocalizationHelper().formatDateTimeCompact(
            warranty.acceptedAt!.toDate(),
            context,
          );
        } else if (statusCode == 'C' && warranty.completedAt != null) {
          text = LocalizationHelper().formatDateTimeCompact(
            warranty.completedAt!.toDate(),
            context,
          );
        } else if (statusCode == 'X' && warranty.rejectedAt != null) {
          text = LocalizationHelper().formatDateTimeCompact(
            warranty.rejectedAt!.toDate(),
            context,
          );
        } else if (warranty.createdAt != null) {
          text = LocalizationHelper().formatDateTimeCompact(
            warranty.createdAt!.toDate(),
            context,
          );
        }
      }
    } else {
      if (booking.bookingStatusCode == 'P' && booking.createdAt != null) {
        text = LocalizationHelper().formatDateTimeCompact(
          booking.createdAt!.toDate(),
          context,
        );
      } else if (booking.bookingStatusCode == 'A' &&
          booking.acceptedAt != null) {
        text = LocalizationHelper().formatDateTimeCompact(
          booking.acceptedAt!.toDate(),
          context,
        );
      } else if (booking.bookingStatusCode == 'C' &&
          booking.completedAt != null) {
        text = LocalizationHelper().formatDateTimeCompact(
          booking.completedAt!.toDate(),
          context,
        );
      } else if ((booking.bookingStatusCode == 'X' ||
              booking.bookingStatusCode == 'XC' ||
              booking.bookingStatusCode == 'R') &&
          booking.cancelledAt != null) {
        text = LocalizationHelper().formatDateTimeCompact(
          booking.cancelledAt!.toDate(),
          context,
        );
      } else if (booking.bookingStatusCode == 'VP' &&
          booking.paymentCompletedAt != null) {
        text = LocalizationHelper().formatDateTimeCompact(
          booking.paymentCompletedAt!.toDate(),
          context,
        );
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

class JobOfferTileWidget extends StatefulWidget {
  final JobOfferContainer offer;
  final bool isAdmin;
  final VoidCallback? onAssign;

  const JobOfferTileWidget({
    super.key,
    required this.offer,
    this.isAdmin = false,
    this.onAssign,
  });

  @override
  State<JobOfferTileWidget> createState() => _JobOfferTileWidgetState();
}

class _JobOfferTileWidgetState extends State<JobOfferTileWidget> {
  bool _isLoading = false;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  double? _distance;
  bool _isCalculatingDistance = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _calculateDistance();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  Future<void> _calculateDistance() async {
    try {
      final serviceLoc = widget.offer.offerData['serviceLocation'];
      if (serviceLoc == null) return;

      final destLat = serviceLoc['lat'] as double?;
      final destLon = serviceLoc['lon'] as double?;
      if (destLat == null || destLon == null) return;

      if (mounted) {
        setState(() {
          _isCalculatingDistance = true;
        });
      }

      final position = await Geolocator.getCurrentPosition();
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        destLat,
        destLon,
      );

      if (mounted) {
        setState(() {
          _distance = dist / 1000; // Convert to km
          _isCalculatingDistance = false;
        });
      }
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      if (mounted) {
        setState(() {
          _isCalculatingDistance = false;
        });
      }
    }
  }

  void _startCountdown() {
    final expiresAt = widget.offer.offerData['expiresAt'] as Timestamp?;
    if (expiresAt == null) return;

    final remaining = expiresAt.toDate().difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _declineOffer(context);
      return;
    }

    setState(() => _secondsRemaining = remaining);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _declineOffer(context);
      }
    });
  }

  Future<void> _acceptOffer(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final technician = LocalStore.getCachedUserData();
      if (technician == null) throw Exception('Technician data not found');

      await AppServices.acceptJobOffer(
        bookingId: widget.offer.booking?.id,
        requestId: widget.offer.requestId,
        offerId: widget.offer.offerId,
        technician: technician,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.offerAcceptedSuccessfully ?? 'Offer accepted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showProfessionalRejectionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bool isRebook = widget.offer.offerData['isRebook'] == true;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Text(
                l10n.areYouSure,
                style: DMSansFont.textStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.rejectionProfessionalMessage,
          style: DMSansFont.textStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          if (isRebook) ...[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _declineOffer(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.rejectOffer,
                      style: DMSansFont.textStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _proposeNewTime(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.proposeAlternativeTime,
                      style: DMSansFont.textStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.cancel,
                      style: DMSansFont.textStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _declineOffer(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.rejectOffer,
                      style: DMSansFont.textStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _declineOffer(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await AppServices.declineJobOffer(widget.offer.offerId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final data = widget.offer.offerData;

    final customerName = data['customerName'] ?? 'Customer';
    final serviceName = locale == 'en'
        ? (data['serviceName'] ?? '')
        : (data['serviceNameAr'] ?? data['serviceName'] ?? '');
    final address =
        data['serviceLocation']?['fullAddress'] ??
        data['serviceLocation']?['streetName'] ??
        'N/A';

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timerText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isUrgent = _secondsRemaining <= 30;
    final timerColor = isUrgent ? Colors.red : AppColors.primary;

    return GestureDetector(
      onTap: () {
        if (widget.offer.booking != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingInfo(
                booking: widget.offer.booking!,
                isAdmin: widget.isAdmin,
                offerId: widget.offer.offerId,
                isFromOffersTab: true,
              ),
            ),
          );
        } else {
          // Navigate to a simplified info page for broadcast offers
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BroadcastOfferInfo(offer: widget.offer),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    serviceName,
                    style: DMSansFont.textStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: timerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: timerColor),
                      const SizedBox(width: 4),
                      Text(
                        timerText,
                        style: DMSansFont.textStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: timerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person_outline, customerName),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.location_on_outlined, address),
            if (data['bookingDateTime'] != null ||
                widget.offer.booking?.bookingDateTime != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.calendar_today_outlined,
                DateFormat('EEE, d MMM • hh:mm a').format(
                  ((data['bookingDateTime'] as Timestamp?) ??
                          widget.offer.booking!.bookingDateTime)
                      .toDate(),
                ),
              ),
            ],
            if (_distance != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.directions_car_outlined,
                localization.kmAway(_distance!.toStringAsFixed(1)),
                color: AppColors.primary,
              ),
            ] else if (_isCalculatingDistance) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.directions_car_outlined,
                localization.calculatingDistance,
                color: Colors.grey[500],
              ),
            ],
            if (widget.isAdmin) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Text(
                      localization.viewOnly.toUpperCase(),
                      style: DMSansFont.textStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (widget.onAssign != null) ...[
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: localization.assign,
                      color: AppColors.primary,
                      onPressed: widget.onAssign!,
                    ),
                  ],
                ],
              ),
            ] else if (data['status'] == 'accepted_by_technician' ||
                data['status'] == 'counter_offered') ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      localization.awaitingCustomerAction,
                      style: DMSansFont.textStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildSmallButton(
                    label: localization.reject,
                    color: Colors.red,
                    onPressed: () => _showProfessionalRejectionDialog(context),
                    isOutlined: true,
                  ),
                  const SizedBox(width: 12),
                  _buildSmallButton(
                    label: localization.accept,
                    color: AppColors.primary,
                    onPressed: () => _acceptOffer(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _proposeNewTime(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CounterProposeSheet(
        offerId: widget.offer.offerId,
        requestId: widget.offer.requestId,
        customerId: widget.offer.offerData['customerId'],
        currentBookingTime:
            (widget.offer.offerData['bookingDateTime'] as Timestamp).toDate(),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: DMSansFont.textStyle(
              fontSize: 13,
              color: color ?? Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallButton({
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
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                label,
                style: DMSansFont.textStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                label,
                style: DMSansFont.textStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}

// Removed backward-compatibility typedef as all usages have been updated.
