import 'dart:async';
import 'package:aboglumbo_bbk_panel/common_widget/cached_video_player.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:aboglumbo_bbk_panel/services/time_service.dart';

class BroadcastOfferInfo extends StatefulWidget {
  final JobOfferContainer offer;

  const BroadcastOfferInfo({super.key, required this.offer});

  @override
  State<BroadcastOfferInfo> createState() => _BroadcastOfferInfoState();
}

class _BroadcastOfferInfoState extends State<BroadcastOfferInfo> {
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final status = widget.offer.offerData['status'] as String?;
    if (status == 'accepted_by_technician') {
      return; // No countdown if already accepted
    }

    final expiresAt = widget.offer.offerData['expiresAt'] as Timestamp?;
    if (expiresAt == null) return;

    final remaining = expiresAt.toDate().difference(TimeService.now).inSeconds;
    if (remaining <= 0) {
      Navigator.pop(context);
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
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final data = widget.offer.offerData;

    final booking = widget.offer.booking;

    final serviceName = locale == 'ur'
        ? (data['serviceNameUr'] ??
              booking?.service.name_ur ??
              data['serviceNameAr'] ??
              booking?.service.name_ar ??
              data['serviceName'] ??
              booking?.service.name ??
              '')
        : locale == 'ar'
        ? (data['serviceNameAr'] ??
              booking?.service.name_ar ??
              data['serviceName'] ??
              booking?.service.name ??
              '')
        : (data['serviceName'] ?? booking?.service.name ?? '');

    final customerName =
        data['customerName'] ?? booking?.customer.name ?? localization.customer;

    final selectedAddress =
        booking?.customer.addresses
            .where((a) => a.isSelected == true)
            .firstOrNull ??
        booking?.customer.addresses.firstOrNull;
    final displayAddress = selectedAddress?.displayAddress.isNotEmpty == true
        ? selectedAddress!.displayAddress
        : null;
    final selectedText = booking?.customerSelectedAddressText ?? '';

    final address = selectedText.isNotEmpty
        ? selectedText
        : data['serviceLocation']?['fullAddress'] ??
              data['serviceLocation']?['streetName'] ??
              displayAddress ??
              booking?.customer.location?.fullAddress ??
              localization.notAvailable;

    final String? offerNotes = data['notes'];
    final String? bookingNotes = booking?.notes;
    final notes = (offerNotes != null && offerNotes.isNotEmpty)
        ? offerNotes
        : (bookingNotes != null && bookingNotes.isNotEmpty
            ? bookingNotes
            : localization.noAdditionalDescription);

    final String? offerIssueImage = data['issueImage'];
    final String? bookingIssueImage = booking?.issueImage;
    final issueImage = (offerIssueImage != null && offerIssueImage.isNotEmpty)
        ? offerIssueImage
        : (bookingIssueImage != null && bookingIssueImage.isNotEmpty ? bookingIssueImage : null);

    final String? offerIssueVideo = data['issueVideo'];
    final String? bookingIssueVideo = booking?.issueVideo;
    final issueVideo = (offerIssueVideo != null && offerIssueVideo.isNotEmpty)
        ? offerIssueVideo
        : (bookingIssueVideo != null && bookingIssueVideo.isNotEmpty ? bookingIssueVideo : null);
    final bookingDateTime =
        data['bookingDateTime'] as Timestamp? ?? booking?.bookingDateTime;

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final timerText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (data['status'] != 'accepted_by_technician')
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  timerText,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Details
            _buildInfoCard(
              context,
              localization.customerInfo,
              Icons.person_outline,
              [
                _buildDetailRow(localization.customerName, customerName),
                _buildDetailRow(localization.location, address),
                if (data['serviceLocation']?['lat'] != null)
                  _buildDistanceRow(data['serviceLocation']),
              ],
            ),
            const SizedBox(height: 20),

            // Appointment Details
            if (bookingDateTime != null) ...[
              _buildInfoCard(
                context,
                localization.appointmentDetails,
                Icons.calendar_today_outlined,
                [
                  _buildDetailRow(
                    localization.date,
                    DateFormat(
                      'EEEE, d MMMM yyyy',
                      locale,
                    ).format(bookingDateTime.toDate()),
                  ),
                  _buildDetailRow(
                    localization.time,
                    DateFormat(
                      'hh:mm a',
                      locale,
                    ).format(bookingDateTime.toDate()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Customer Notes / Issue Description
            if (notes.isNotEmpty) ...[
              _buildInfoCard(
                context,
                localization.bookingNote,
                Icons.note_alt_outlined,
                [
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
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Issue Media
            if ((issueImage != null && issueImage.isNotEmpty) ||
                (issueVideo != null && issueVideo.isNotEmpty)) ...[
              _buildInfoCard(
                context,
                localization.issueMedia,
                Icons.image_outlined,
                [
                  if (issueImage != null && issueImage.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullScreenImageNew(issueImage, context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.image, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.image,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                  if (issueImage != null && issueImage.isNotEmpty &&
                      issueVideo != null && issueVideo.isNotEmpty)
                    const SizedBox(height: 12),
                  if (issueVideo != null && issueVideo.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullScreenVideo(issueVideo, context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.videocam, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.video,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceRow(Map<String, dynamic> loc) {
    final localization = AppLocalizations.of(context)!;
    final technician = LocalStore.getCachedUserData();
    double? techLat;
    double? techLon;

    // Try to get tech location from cache
    if (technician?.liveLocation?.latitude != null) {
      techLat = technician!.liveLocation!.latitude;
      techLon = technician.liveLocation!.longitude;
    } else if (technician?.lastKnownLocation != null) {
      techLat = technician!.lastKnownLocation!.latitude;
      techLon = technician.lastKnownLocation!.longitude;
    } else if (technician?.location?.lat != null) {
      techLat = technician!.location!.lat;
      techLon = technician.location!.lon;
    }

    if (techLat != null && techLon != null) {
      final dist = Geolocator.distanceBetween(
        techLat,
        techLon,
        loc['lat'],
        loc['lon'],
      );
      return _buildDetailRow(
        localization.distance,
        localization.kmAway((dist / 1000).toStringAsFixed(1)),
      );
    }

    // Fallback to real-time GPS if cache is empty
    return FutureBuilder(
      future: Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final dist = Geolocator.distanceBetween(
          snapshot.data!.latitude,
          snapshot.data!.longitude,
          loc['lat'],
          loc['lon'],
        );
        return _buildDetailRow(
          localization.distance,
          localization.kmAway((dist / 1000).toStringAsFixed(1)),
        );
      },
    );
  }

  void _showFullScreenImageNew(String imageUrl, BuildContext context) {
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

  void _showFullScreenVideo(String videoUrl, BuildContext context) {
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
