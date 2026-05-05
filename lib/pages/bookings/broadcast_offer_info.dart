import 'dart:async';
import 'package:aboglumbo_bbk_panel/common_widget/cached_video_player.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/widgets/counter_propose_sheet.dart';
import 'package:geolocator/geolocator.dart';

class BroadcastOfferInfo extends StatefulWidget {
  final JobOfferContainer offer;

  const BroadcastOfferInfo({super.key, required this.offer});

  @override
  State<BroadcastOfferInfo> createState() => _BroadcastOfferInfoState();
}

class _BroadcastOfferInfoState extends State<BroadcastOfferInfo> {
  bool _isLoading = false;
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
    final expiresAt = widget.offer.offerData['expiresAt'] as Timestamp?;
    if (expiresAt == null) return;

    final remaining = expiresAt.toDate().difference(DateTime.now()).inSeconds;
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

  Future<void> _acceptOffer() async {
    setState(() => _isLoading = true);
    try {
      final technician = LocalStore.getCachedUserData();
      if (technician == null) throw Exception('Technician data not found');

      await AppServices.acceptJobOffer(
        requestId: widget.offer.requestId,
        offerId: widget.offer.offerId,
        technician: technician,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted successfully')),
        );
        Navigator.pop(context);
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

  Future<void> _showProfessionalRejectionDialog() async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.areYouSure,
          style: DMSansFont.textStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.rejectionProfessionalMessage,
          style: DMSansFont.textStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _declineOffer();
            },
            child: Text(
              l10n.rejectOffer,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCounterOfferPicker();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.proposeAlternativeTime,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCounterOfferPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CounterProposeSheet(
        booking: widget
            .offer
            .booking!, // Assuming booking is available in offer container
        offerId: widget.offer.offerId,
      ),
    );
  }

  Future<void> _declineOffer() async {
    setState(() => _isLoading = true);
    try {
      await AppServices.declineJobOffer(widget.offer.offerId);
      if (mounted) Navigator.pop(context);
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

    final booking = widget.offer.booking;

    final serviceName = locale == 'en'
        ? (data['serviceName'] ?? booking?.service.name ?? '')
        : (data['serviceNameAr'] ??
              booking?.service.name_ar ??
              data['serviceName'] ??
              booking?.service.name ??
              '');

    final customerName =
        data['customerName'] ?? booking?.customer.name ?? 'Customer';

    final address =
        data['serviceLocation']?['fullAddress'] ??
        data['serviceLocation']?['streetName'] ??
        booking?.customer.location?.fullAddress ??
        'N/A';

    final notes =
        data['notes'] ?? booking?.notes ?? 'No additional description';
    final issueImage = data['issueImage'] ?? booking?.issueImage;
    final issueVideo = data['issueVideo'] ?? booking?.issueVideo;

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
          style: DMSansFont.textStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                timerText,
                style: DMSansFont.textStyle(
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

            // Issue Description
            Text(
              localization.serviceDescription,
              style: DMSansFont.textStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
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
                style: DMSansFont.textStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Issue Media
            if (issueImage != null || issueVideo != null) ...[
              Text(
                localization.issueMedia,
                style: DMSansFont.textStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              if (issueImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: issueImage,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(child: Loader()),
                  ),
                ),
              if (issueVideo != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedVideoPlayer(videoUrl: issueVideo),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : _showProfessionalRejectionDialog,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    localization.reject,
                    style: DMSansFont.textStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _acceptOffer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          localization.accept,
                          style: DMSansFont.textStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                style: DMSansFont.textStyle(
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
            width: 80,
            child: Text(
              label,
              style: DMSansFont.textStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: DMSansFont.textStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceRow(Map<String, dynamic> loc) {
    return FutureBuilder(
      future: Geolocator.getCurrentPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final dist = Geolocator.distanceBetween(
          snapshot.data!.latitude,
          snapshot.data!.longitude,
          loc['lat'],
          loc['lon'],
        );
        return _buildDetailRow(
          "Distance",
          "${(dist / 1000).toStringAsFixed(1)} km away",
        );
      },
    );
  }
}
