import 'package:aboglumbo_bbk_panel/common_widget/cached_video_player.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/counter_offer.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/services/time_service.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Read-only admin view of a raw `booking_request` document (a request that
/// hasn't been picked up/converted into a real [BookingModel]-backed booking
/// yet). Deliberately separate from [BookingInfo]: that widget assumes a full
/// booking shape (e.g. non-nullable `bookingStatusCode`, which these raw
/// request docs never have) and is full of action controls that don't apply
/// here — this page only ever reads [request.data] directly and renders it,
/// with no accept/reject/assign affordances.
class BookingRequestDetailsPage extends StatelessWidget {
  final RawBookingRequest request;

  const BookingRequestDetailsPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final data = request.data;

    final service = data['service'] != null
        ? ServiceModel.fromJson(data['service'] as Map<String, dynamic>)
        : null;
    final customer = data['customer'] != null
        ? CustomerModel.fromJson(data['customer'] as Map<String, dynamic>)
        : null;

    final serviceName =
        service?.nameLocalized(languageCode: locale) ??
        service?.name ??
        localization.service;
    final customerName = customer?.name ?? localization.customer;

    final selectedAddress =
        customer?.addresses.where((a) => a.isSelected == true).firstOrNull ??
        customer?.addresses.firstOrNull;
    final serviceLocation = data['serviceLocation'] as Map<String, dynamic>?;
    final address =
        serviceLocation?['fullAddress'] ??
        serviceLocation?['streetName'] ??
        (selectedAddress?.displayAddress.isNotEmpty == true
            ? selectedAddress!.displayAddress
            : null) ??
        customer?.location?.fullAddress ??
        localization.notAvailable;

    final bookingDateTime = data['bookingDateTime'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;
    final notes = (data['notes'] as String?)?.trim();
    final issueImage = data['issueImage'] as String?;
    final issueVideo = data['issueVideo'] as String?;

    final counterOfferData =
        data['activeCounterOffer'] as Map<String, dynamic>?;
    final counterOffer = counterOfferData != null
        ? CounterOfferModel.fromMap(counterOfferData)
        : null;

    final isAwaitingCustomer =
        counterOffer?.status.toLowerCase() == 'pending';
    final statusLabel = isAwaitingCustomer
        ? localization.awaitingCustomerAction
        : localization.searchingForTechnician;
    final statusColor = isAwaitingCustomer ? Colors.blue : AppColors.primary;
    final statusIcon = isAwaitingCustomer
        ? Icons.hourglass_top_outlined
        : Icons.search;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          serviceName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(statusLabel, statusColor, statusIcon),
            const SizedBox(height: 20),

            _buildInfoCard(localization.customerInfo, Icons.person_outline, [
              _buildDetailRow(localization.customerName, customerName),
              _buildDetailRow(localization.location, address),
              if (customer?.phone != null && customer!.phone!.isNotEmpty)
                _buildDetailRow(localization.phone, customer.phone!),
            ]),
            const SizedBox(height: 20),

            if (bookingDateTime != null) ...[
              _buildInfoCard(
                localization.appointmentDetails,
                Icons.calendar_today_outlined,
                [
                  _buildDetailRow(
                    localization.date,
                    DateFormat(
                      'EEEE, d MMMM yyyy',
                      locale,
                    ).format(KsaTime.fromInstant(bookingDateTime.toDate())),
                  ),
                  _buildDetailRow(
                    localization.time,
                    DateFormat(
                      'hh:mm a',
                      locale,
                    ).format(KsaTime.fromInstant(bookingDateTime.toDate())),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            if (counterOffer != null) ...[
              _buildInfoCard(
                localization.counterProposalStatus,
                Icons.swap_horiz,
                [
                  _buildDetailRow(
                    localization.proposedBy,
                    counterOffer.proposedByName,
                  ),
                  _buildDetailRow(
                    localization.proposedTime,
                    DateFormat('EEE, d MMM yyyy hh:mm a', locale).format(
                      KsaTime.fromInstant(counterOffer.proposedTime.toDate()),
                    ),
                  ),
                  _buildDetailRow(localization.status, statusLabel),
                ],
              ),
              const SizedBox(height: 20),
            ],

            if (notes != null && notes.isNotEmpty) ...[
              _buildInfoCard(localization.bookingNote, Icons.note_alt_outlined, [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    notes,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
            ],

            if ((issueImage != null && issueImage.isNotEmpty) ||
                (issueVideo != null && issueVideo.isNotEmpty)) ...[
              _buildInfoCard(localization.issueMedia, Icons.image_outlined, [
                if (issueImage != null && issueImage.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, issueImage),
                    child: _buildMediaRow(
                      context,
                      Icons.image,
                      localization.image,
                    ),
                  ),
                if (issueImage != null &&
                    issueImage.isNotEmpty &&
                    issueVideo != null &&
                    issueVideo.isNotEmpty)
                  const SizedBox(height: 12),
                if (issueVideo != null && issueVideo.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullScreenVideo(context, issueVideo),
                    child: _buildMediaRow(
                      context,
                      Icons.videocam,
                      localization.video,
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
            ],

            _buildInfoCard(localization.requestInfo, Icons.info_outline, [
              if (createdAt != null)
                _buildDetailRow(
                  localization.requestedOn,
                  DateFormat(
                    'EEE, d MMM yyyy hh:mm a',
                    locale,
                  ).format(KsaTime.fromInstant(createdAt.toDate())),
                ),
              _buildDetailRow(localization.status, statusLabel),
            ]),
            const SizedBox(height: 20),

            Center(
              child: Container(
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
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String label, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaRow(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            leading: IconButton(
              iconSize: 18,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.of(context)!.image,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: SizedBox(width: 24, child: Loader())),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenVideo(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              iconSize: 18,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.of(context)!.video,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          body: Center(
            child: CachedVideoPlayer(
              videoUrl: videoUrl,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
