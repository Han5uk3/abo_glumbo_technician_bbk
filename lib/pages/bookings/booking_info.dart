import 'dart:developer';
import 'package:aboglumbo_bbk_panel/common_widget/cached_video_player.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/date_formatter.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/helpers/localization_helper.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/booking_controllers.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/warranty_controllers.dart';
import 'package:aboglumbo_bbk_panel/pages/chat_screen.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/widgets/verify_payment_sheet.dart';
import 'package:aboglumbo_bbk_panel/services/chat_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/bookings/bloc/booking_bloc.dart';
import 'package:aboglumbo_bbk_panel/utils/dm_sans_font.dart';
import 'package:aboglumbo_bbk_panel/utils/counter_offer_utils.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:collection/collection.dart';

class BookingInfo extends StatefulWidget {
  final BookingModel booking;
  final bool isAdmin;
  final bool isWarranty;
  final bool isInAdminMode;

  const BookingInfo({
    super.key,
    required this.booking,
    required this.isAdmin,
    this.isWarranty = false,
    this.isInAdminMode = false,
  });

  @override
  State<BookingInfo> createState() => _BookingInfoState();
}

class _BookingInfoState extends State<BookingInfo> {
  bool isInitiatingChat = false;
  Future<void> handleChatButton() async {
    if (isInitiatingChat) return;

    setState(() {
      isInitiatingChat = true;
    });

    try {
      final chatService = TechnicianChatService();
      String chatId;

      // Fetch the latest booking data from Firestore to check chatroomId
      final bookingDoc = await AppFirestore.bookingsCollectionRef
          .doc(widget.booking.id)
          .get();

      String? latestChatroomId;
      if (bookingDoc.exists) {
        final data = bookingDoc.data() as Map<String, dynamic>?;
        latestChatroomId = data?['chatroomId'] as String?;
      }

      // Check if chatroomId exists in Firestore AND verify it exists in Realtime Database
      bool chatExists = false;
      if (latestChatroomId != null && latestChatroomId.isNotEmpty) {
        // Verify the chat actually exists in Realtime Database using the service method
        chatExists = await chatService.chatExists(latestChatroomId);

        if (chatExists) {
          log(
            '✅ Chat verified in both Firestore and Realtime Database: $latestChatroomId',
          );
        } else {
          log(
            '⚠️ Chat ID exists in Firestore but not in Realtime Database. Will create new chat.',
          );
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: AlertDialog(
              backgroundColor: AppColors.bgWhite,
              content: SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 24, child: Loader()),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.loadingChat,

                        style: DMSansFont.textStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (chatExists) {
        chatId = latestChatroomId!;
        log('✅ Using existing chat: $chatId');
        // Small delay to show the message
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        log('🔄 Initiating new chat...');
        // Get technician info
        String technicianName;
        String technicianPhoto;
        if (widget.isWarranty) {
          final tech = widget.booking.warranty?.assignedTechnician;
          technicianName = widget.isAdmin
              ? "Admin"
              : tech?.name ?? "Technician";
          technicianPhoto = widget.isAdmin ? "" : tech?.profileUrl ?? "";
        } else {
          technicianName = widget.isAdmin
              ? "Admin"
              : widget.booking.agent?.name ?? "Technician";
          technicianPhoto = widget.isAdmin
              ? ""
              : widget.booking.agent?.profileUrl ?? "";
        }
        // Create new chat
        chatId = await chatService.initiateChat(
          bookingId: widget.booking.id,
          customerId: widget.booking.customer.uid,
          customerName: widget.booking.customer.name ?? "Customer",
          customerPhoto: "",
          technicianName: technicianName,
          technicianPhoto: technicianPhoto,
        );
        log('✅ Chat created with ID: $chatId');
      }

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Navigate to chat screen
      if (mounted) {
        String technicianName;
        String technicianPhoto;
        if (widget.isWarranty) {
          final tech = widget.booking.warranty?.assignedTechnician;
          technicianName = widget.isAdmin
              ? "Admin"
              : tech?.name ?? "Technician";
          technicianPhoto = widget.isAdmin ? "" : tech?.profileUrl ?? "";
        } else {
          technicianName = widget.isAdmin
              ? "Admin"
              : widget.booking.agent?.name ?? "Technician";
          technicianPhoto = widget.isAdmin
              ? ""
              : widget.booking.agent?.profileUrl ?? "";
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TechnicianChatScreen(
              isAdmin: widget.isAdmin,
              chatId: chatId,
              participantName: widget.booking.customer.name ?? "Customer",
              participantId: widget.booking.customer.uid,
              participantPhoto: "",
              technicianName: technicianName,
              technicianPhoto: technicianPhoto,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${AppLocalizations.of(context)!.failedToStartChat}: $e",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      log('❌ Chat error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isInitiatingChat = false;
        });
      }
    }
  }

  void openDirections() {
    final addresses = widget.booking.customer.addresses;
    final selectedAddress =
        addresses.where((a) => a.isSelected == true).isNotEmpty
        ? addresses.firstWhere((a) => a.isSelected == true)
        : (addresses.isNotEmpty ? addresses.first : null);

    if (selectedAddress != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query='
          '${selectedAddress.lat},${selectedAddress.lon}';
      launchUrlString(url);
    }
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool hasChat,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: DMSansFont.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (hasChat) ...[
                const Spacer(),
                GestureDetector(
                  onTap: isInitiatingChat ? null : handleChatButton,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Divider(thickness: 1, color: Colors.grey.shade300),
          const SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: DMSansFont.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: DMSansFont.textStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                color: isHighlighted ? AppColors.blue1 : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoRow(
    String name,
    String description,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.build_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.serviceInfo ?? '',
                style: DMSansFont.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Divider(thickness: 1, color: Colors.grey.shade300),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 45,
                    width: 45,
                    child: CachedNetworkImage(
                      imageUrl: widget.booking.service.image ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: SizedBox(width: 20, height: 20, child: Loader()),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.image_outlined,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DMSansFont.textStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: DMSansFont.textStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Divider(thickness: 0.5, color: Colors.grey.shade300),
          if (widget.booking.service.price != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.price}\t\t  ',
                  style: DMSansFont.textStyle(fontSize: 12),
                ),
                Text(
                  '${AppLocalizations.of(context)!.sar} ${widget.booking.service.price}',
                  style: DMSansFont.textStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    AddressModel? customerSelectedAddress,
    BuildContext context,
  ) {
    final localization = AppLocalizations.of(context)!;
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                localization.location,
                style: DMSansFont.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Divider(thickness: 1, color: Colors.grey.shade300),
          const SizedBox(height: 4),
          Text(
            customerSelectedAddress?.streetName ??
                widget.booking.customer.location?.fullAddress ??
                "",
            style: DMSansFont.textStyle(fontSize: 12, color: Colors.black),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime, String locale) {
    return DateFormat('yyyy-MM-dd HH:mm', locale).format(dateTime);
  }

  void _showFullScreenImageNew(String imageUrl, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.of(context)!.image,
              style: const TextStyle(color: Colors.white),
            ),
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
                    Center(child: SizedBox(width: 24, child: Loader())),
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

  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> names = name.split(" ");
    if (names.length > 1) {
      return names[0][0].toUpperCase() + names[1][0].toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;

    final List<Widget> tabs = [];
    final List<Widget> tabViews = [];

    // Tab 1: SERVICE (Always shown)
    tabs.add(Tab(text: AppLocalizations.of(context)!.service));
    tabViews.add(
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildServiceInfoRow(
              locale == 'en'
                  ? (widget.booking.service.name ?? '')
                  : (widget.booking.service.name_ar ?? ''),
              locale == 'en'
                  ? (widget.booking.service.description ?? '')
                  : (widget.booking.service.description_ar ?? ''),
              context,
            ),
            _buildLocationCard(
              widget.booking.customer.addresses.firstOrNull,
              context,
            ),

            const SizedBox(height: 16),
            _buildSectionCard(
              context: context,
              hasChat: false,
              title: AppLocalizations.of(context)!.scheduledFor,
              icon: Icons.schedule_rounded,
              children: [
                _buildDetailRow(
                  AppLocalizations.of(context)!.bookedFor,
                  _formatDateTime(
                    widget.booking.bookingDateTime.toDate(),
                    locale,
                  ),
                ),
              ],
            ),
            if ((widget.booking.issueImage != null &&
                    widget.booking.issueImage!.isNotEmpty) ||
                (widget.booking.issueVideo != null &&
                    widget.booking.issueVideo!.isNotEmpty)) ...[
              const SizedBox(height: 16),
              _buildIssueMediaCard(context, textTheme, colorScheme),
            ],
            if (widget.booking.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionCard(
                context: context,
                hasChat: false,
                title: AppLocalizations.of(context)!.bookingNote,
                icon: Icons.note_rounded,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      widget.booking.notes,
                      style: DMSansFont.textStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );

    // Tab 2: CUSTOMER (Always shown)
    tabs.add(Tab(text: AppLocalizations.of(context)!.customer));
    tabViews.add(
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCustomerInfoCard(context, textTheme, colorScheme),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );

    // Tab 3: TECHNICIAN (Only for admin)
    if (widget.isAdmin && widget.booking.agent != null) {
      tabs.add(Tab(text: AppLocalizations.of(context)!.technician));
      tabViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildTechnicianInfoCard(context, textTheme, colorScheme),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    // Tab: COMPLETION (Conditional)
    final bool hasCompletionData =
        widget.booking.bookingStatusCode.toLowerCase() == 'c' ||
        widget.booking.completionData != null ||
        (widget.booking.technicianPaymentProof != null &&
            widget.booking.technicianPaymentProof!.isNotEmpty);

    if (hasCompletionData) {
      tabs.add(Tab(text: AppLocalizations.of(context)!.completionDetails));
      tabViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (widget.booking.bookingStatusCode.toLowerCase() == 'c' &&
                  widget.booking.completionData != null)
                _buildCompletionDataCard(context, textTheme, colorScheme),
              if (widget.booking.technicianPaymentProof != null &&
                  widget.booking.technicianPaymentProof!.isNotEmpty) ...[
                if (widget.booking.bookingStatusCode.toLowerCase() == 'c' &&
                    widget.booking.completionData != null)
                  const SizedBox(height: 16),
                _buildPaymentProofCard(context, textTheme, colorScheme),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    // Tab: REVIEW (Conditional)
    if (widget.booking.review != null) {
      tabs.add(Tab(text: AppLocalizations.of(context)!.reviews));
      tabViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildReviewCard(context, textTheme, colorScheme),
              const SizedBox(height: 16),
              _buildTipCard(context, textTheme, colorScheme),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    }

    // Tab: TIMELINE (Always shown)
    tabs.add(Tab(text: AppLocalizations.of(context)!.bookingTimeline));
    tabViews.add(
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.isAdmin &&
                widget.booking.warranty != null &&
                widget.booking.warranty!.rejectedTechnicians != null &&
                widget.booking.warranty!.rejectedTechnicians!.isNotEmpty) ...[
              _buildWarrantyRejectedTechniciansCard(
                context,
                textTheme,
                colorScheme,
              ),
              const SizedBox(height: 16),
            ],
            _buildBookingTimelineCard(
              context,
              textTheme,
              colorScheme,
              widget.isWarranty,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                elevation: 0,
                scrolledUnderElevation: 0,
                pinned: true,
                floating: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                shape: Border.all(style: BorderStyle.none),
                title: Text(AppLocalizations.of(context)!.bookingInfo),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: AppFirestore.bookingsCollectionRef
                        .doc(widget.booking.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docData =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      final currentBooking = docData != null
                          ? BookingModel.fromMap(docData)
                          : widget.booking;

                      final statusCode = currentBooking.bookingStatusCode;
                      final chatroomId = currentBooking.chatroomId;
                      final isTracking =
                          currentBooking.isStartTracking ?? false;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Review and Tip Card
                          if (!widget.isInAdminMode &&
                              ((statusCode.toLowerCase() == 'a' &&
                                      !widget.isAdmin) ||
                                  (!widget.isAdmin &&
                                      widget.isWarranty &&
                                      currentBooking
                                              .warranty?.warrantyStatusCode
                                              .toLowerCase() ==
                                          's'))) ...{
                            _buildChatWithCustomerButton(
                              context,
                              colorScheme,
                              chatroomId,
                              widget.isWarranty,
                            ),
                            const SizedBox(height: 16),
                          },

                          // Booking controls (Normal)
                          if (!widget.isInAdminMode &&
                              !widget.isWarranty &&
                              (statusCode.toLowerCase() == 'a'))
                            BookingControlsWidget(
                              booking: currentBooking,
                              isTracking: isTracking,
                              onTrackingStarted: openDirections,
                            ),

                          if (!widget.isAdmin &&
                              !widget.isWarranty &&
                              statusCode.toUpperCase() == 'P')
                            _buildPendingBookingControls(
                              context,
                              currentBooking,
                            ),

                          // blue booking id card
                          Container(
                            width: double.maxFinite,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xffEAF1FF).withOpacity(0.50),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.bookingId,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  "#${currentBooking.id}",
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () {
                                              Clipboard.setData(
                                                ClipboardData(
                                                  text: widget.booking.id,
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.bookingIdCopied,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: Icon(
                                              Icons.copy,
                                              size: 18,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  thickness: 0.5,
                                  color: Colors.black,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: _buildTimestampText(
                                    context,
                                    currentBooking,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          _buildCounterOfferUI(context, currentBooking),

                          // Verification Controls
                          if (!widget.isInAdminMode &&
                              !widget.isWarranty &&
                              statusCode == 'VP')
                            VerifyPaymentControls(booking: currentBooking),

                          // Warranty controls (Warranty)
                          if (widget.isWarranty &&
                              currentBooking.warranty != null) ...[
                            Builder(
                              builder: (context) {
                                final warrantyStatus = currentBooking
                                    .warranty?.warrantyStatusCode;
                                if (!widget.isInAdminMode &&
                                    warrantyStatus == 'S' &&
                                    (currentBooking
                                                .warranty
                                                ?.assignedTechnician
                                                ?.uid ==
                                            LocalStore.getUID() ||
                                        (LocalStore.getCachedUserData()
                                                ?.isAdmin ??
                                            false))) {
                                  return WarrantyControlsWidget(
                                    booking: currentBooking,
                                    isTracking: isTracking,
                                    isAdmin: widget.isAdmin,
                                    onTrackingStarted: openDirections,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors.primary,
                    tabs: tabs,
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: tabViews,
          ),
        ),
      ),
    );

  }

  Widget _buildPaymentProofCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.uploadFilesTitle,
                  style: DMSansFont.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.booking.technicianPaymentProof!.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final url = widget.booking.technicianPaymentProof![index];
                  return GestureDetector(
                    onTap: () => _viewInfoImage(url, context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(child: Loader()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewInfoImage(String url, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (context, url) => Center(child: Loader()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarrantyRejectedTechniciansCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_off_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.warrantyRejectedTechnicians,
                  style: DMSansFont.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // List of rejected technicians
            ...widget.booking.warranty!.rejectedTechnicians!.map((tech) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Technician Name
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.technicianName,
                          style: DMSansFont.textStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tech.name ?? 'Unknown',
                      style: DMSansFont.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Technician Phone Number
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.phone,
                          style: DMSansFont.textStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tech.phone ?? 'N/A',
                            style: DMSansFont.textStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Call Button
                        IconButton(
                          icon: const Icon(Icons.phone, size: 18),
                          color: Colors.green,
                          onPressed: () async {
                            if (tech.phone != null && tech.phone!.isNotEmpty) {
                              final phoneUrl = 'tel:${tech.phone}';
                              if (await canLaunchUrlString(phoneUrl)) {
                                await launchUrlString(phoneUrl);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.couldNotLaunchPhone,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cancellation Reason
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.reasonforrejection,
                          style: DMSansFont.textStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tech.reason ?? 'No reason provided',
                      style: DMSansFont.textStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancelled Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.cancelledDate,
                          style: DMSansFont.textStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tech.rejectedAt != null
                          ? _formatDateLocalized(
                              tech.rejectedAt!.toDate(),
                              context,
                            )
                          : 'N/A',
                      style: DMSansFont.textStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 🔥 UPDATED CHAT BUTTON - Accepts chatroomId parameter from StreamBuilder
  Widget _buildChatWithCustomerButton(
    BuildContext context,
    ColorScheme colorScheme,
    String? chatroomId,
    bool isWarranty,
  ) {
    final bool hasChatRoom = chatroomId != null && chatroomId.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInitiatingChat ? null : handleChatButton,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasChatRoom ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  hasChatRoom
                      ? AppLocalizations.of(context)!.continueChat
                      : AppLocalizations.of(context)!.chatWithCustomer,
                  style: DMSansFont.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssueMediaCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return _buildSectionCard(
      context: context,
      title: AppLocalizations.of(context)!.issueMedia,
      icon: Icons.image_outlined,
      hasChat: false,
      children: [
        if (widget.booking.issueImage != null &&
            widget.booking.issueImage!.isNotEmpty)
          GestureDetector(
            onTap: () =>
                _showFullScreenImageNew(widget.booking.issueImage!, context),
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
                    style: DMSansFont.textStyle(
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
        if (widget.booking.issueImage != null &&
            widget.booking.issueImage!.isNotEmpty &&
            widget.booking.issueVideo != null &&
            widget.booking.issueVideo!.isNotEmpty)
          const SizedBox(height: 12),
        if (widget.booking.issueVideo != null &&
            widget.booking.issueVideo!.isNotEmpty)
          GestureDetector(
            onTap: () =>
                _showFullScreenVideo(widget.booking.issueVideo!, context),
            child: Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.video_collection,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.video,
                    style: DMSansFont.textStyle(
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
    );
  }

  void _showFullScreenVideo(String videoUrl, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppLocalizations.of(context)!.video,
              style: const TextStyle(color: Colors.white),
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

  Widget _buildCustomerInfoCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return _buildSectionCard(
      context: context,
      title: AppLocalizations.of(context)!.customerInfo,
      icon: Icons.person_outline,
      hasChat: !widget.isAdmin && widget.booking.bookingStatusCode == 'A',
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.blue1.withOpacity(0.1),
              child: Text(
                _getInitials(widget.booking.customer.name ?? ""),
                style: DMSansFont.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.booking.customer.name ?? "",
                    style: DMSansFont.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.booking.customer.phone != null)
                    Text(
                      widget.booking.customer.phone!,
                      style: DMSansFont.textStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (widget.booking.bookingStatusCode != 'C' && !widget.isAdmin)
              GestureDetector(
                onTap: () async {
                  final phone = (widget.booking.customer.phone ?? "")
                      .replaceAll(RegExp(r'\s+'), '');
                  final phoneUrl = 'tel:$phone';
                  if (await canLaunchUrlString(phoneUrl)) {
                    await launchUrlString(phoneUrl);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechnicianInfoCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final agent = widget.isWarranty
        ? widget.booking.warranty?.assignedTechnician
        : widget.booking.agent;

    if (agent == null) return const SizedBox.shrink();

    return _buildSectionCard(
      context: context,
      title: AppLocalizations.of(context)!.technician,
      icon: Icons.person_outline,
      hasChat: false,
      children: [
        Row(
          children: [
            CachedNetworkImage(
              imageUrl: agent.profileUrl ?? "",
              imageBuilder: (context, imageProvider) =>
                  CircleAvatar(radius: 20, backgroundImage: imageProvider),
              placeholder: (context, url) => CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.blue1.withOpacity(0.1),
                child: Center(child: Loader()),
              ),
              errorWidget: (context, url, error) => CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.blue1.withOpacity(0.1),
                child: Text(
                  _getInitials(agent.name ?? ""),
                  style: DMSansFont.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name ?? "",
                    style: DMSansFont.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (agent.phone != null)
                    Text(
                      agent.phone!,
                      style: DMSansFont.textStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final phone = (agent.phone ?? "").replaceAll(
                  RegExp(r'\s+'),
                  '',
                );
                final phoneUrl = 'tel:$phone';
                if (await canLaunchUrlString(phoneUrl)) {
                  await launchUrlString(phoneUrl);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.green,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    bool needCopyButton = false,
  }) {
    return _buildDetailRow(label, value);
  }

  Widget _buildBookingTimelineCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    bool isWarranty,
  ) {
    List<Map<String, dynamic>> timelineItems = [];

    // Get current technician's cancellation date (if they cancelled)
    DateTime? currentTechCancelledAt;

    if (!widget.isAdmin && isWarranty) {
      final currentTechId = FirebaseAuth.instance.currentUser?.uid;
      if (currentTechId != null &&
          widget.booking.warranty?.rejectedTechnicians != null) {
        final cancelledByCurrentTech = widget
            .booking
            .warranty!
            .rejectedTechnicians!
            .firstWhereOrNull((tech) => tech.uid == currentTechId);

        if (cancelledByCurrentTech != null) {
          currentTechCancelledAt = cancelledByCurrentTech.rejectedAt!.toDate();
        }
      }
    }

    if (isWarranty) {
      // ==========================================
      // WARRANTY BOOKING TIMELINE ONLY
      // ==========================================

      // Created (original booking)
      if (widget.booking.createdAt != null) {
        final eventDate = widget.booking.createdAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.createdAt,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(
              context,
            )!.customerSubmittedBookingRequest,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Original service completed
      if (widget.booking.completedAt != null) {
        final eventDate = widget.booking.completedAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.originalServiceCompleted,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(
              context,
            )!.serviceHasBeenSuccessfullyCompleted,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty requested - always show this regardless of technician cancellation
      if (widget.booking.warranty?.requestedOn != null) {
        final eventDate = widget.booking.warranty!.requestedOn!.toDate();
        timelineItems.add({
          'title': AppLocalizations.of(context)!.warrantyRepairRequested,
          'time': _formatDateLocalized(eventDate, context),
          'description': AppLocalizations.of(
            context,
          )!.customerRequestedRepairUnderWarranty,
          'status': 'completed',
          'date': eventDate,
        });
      }

      // Warranty accepted
      if (widget.booking.warranty?.acceptedAt != null) {
        final eventDate = widget.booking.warranty!.acceptedAt!;
        final eventDateTime = eventDate.toDate();

        if (currentTechCancelledAt == null ||
            eventDateTime.isBefore(currentTechCancelledAt) ||
            eventDateTime.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.warrantyRepairAccepted,
            'time': _formatDateLocalized(eventDateTime, context),
            'description': AppLocalizations.of(
              context,
            )!.technicianAcceptedTheRequest,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty tracking started
      if (widget.booking.trackingStartedAt != null) {
        final eventDate = widget.booking.trackingStartedAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.trackingStartedAt,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(
              context,
            )!.serviceTrackingInitiated,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty tracking stopped
      if (widget.booking.trackingStoppedAt != null) {
        final eventDate = widget.booking.trackingStoppedAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.trackingStoppedAt,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(context)!.serviceTrackingStopped,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty completed
      if (widget.booking.warranty?.completedAt != null) {
        final eventDate = widget.booking.warranty!.completedAt!;
        final eventDateTime = eventDate.toDate();

        if (currentTechCancelledAt == null ||
            eventDateTime.isBefore(currentTechCancelledAt) ||
            eventDateTime.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.warrantyRepairCompleted,
            'time': _formatDateLocalized(eventDateTime, context),
            'description': AppLocalizations.of(
              context,
            )!.technicianCompletedTheRequest,
            'status': 'completed',
            'date': eventDate,
          });
        }
      }

      // Warranty rejected technicians - For technician view
      if (!widget.isAdmin &&
          widget.booking.warranty?.rejectedTechnicians != null &&
          widget.booking.warranty!.rejectedTechnicians!.isNotEmpty) {
        final currentTechId = LocalStore.getUID();

        if (currentTechId != null) {
          final currentTechCancellation = widget
              .booking
              .warranty!
              .rejectedTechnicians!
              .firstWhereOrNull((tech) => tech.uid == currentTechId);

          if (currentTechCancellation != null) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.youCancelledThisRequest,
              'time': _formatDateLocalized(
                currentTechCancellation.rejectedAt!.toDate(),
                context,
              ),
              'description': AppLocalizations.of(
                context,
              )!.youDeclinedThisWarrantyRequest,
              'status': 'cancelled',
              'date': currentTechCancellation.rejectedAt!,
            });
          }
        }
      }

      // Warranty rejected technicians - For admin view
      if (widget.isAdmin &&
          widget.booking.warranty?.rejectedTechnicians != null &&
          widget.booking.warranty!.rejectedTechnicians!.isNotEmpty) {
        for (var tech in widget.booking.warranty!.rejectedTechnicians!) {
          final eventDate = tech.rejectedAt!;
          final eventDateTime = eventDate.toDate();

          if (currentTechCancelledAt == null ||
              eventDateTime.isBefore(currentTechCancelledAt) ||
              eventDateTime.isAtSameMomentAs(currentTechCancelledAt)) {
            final workerName =
                tech.name ?? AppLocalizations.of(context)!.unknownTechnician;

            timelineItems.add({
              'title': AppLocalizations.of(context)!.technicianCancelled,
              'time': _formatDateLocalized(eventDateTime, context),
              'description':
                  '${AppLocalizations.of(context)!.cancelledByTechnician}: $workerName',
              'status': 'cancelled',
              'date': eventDate,
            });
          }
        }
      }

      // Warranty rejected by admin
      if (widget.booking.warranty?.rejectedAt != null) {
        final eventDate = widget.booking.warranty!.rejectedAt!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          final warrantyStatus =
              widget.booking.warranty?.warrantyStatusCode.toLowerCase() ?? '';
          final isAdminRejection =
              warrantyStatus == 's' || warrantyStatus == 'x';

          timelineItems.add({
            'title': isAdminRejection
                ? AppLocalizations.of(context)!.warrantyRejectedByAdmin
                : AppLocalizations.of(context)!.warrantyRejectedByTechnician,
            'time': _formatDateLocalized(eventDate, context),
            'description': isAdminRejection
                ? AppLocalizations.of(
                    context,
                  )!.warrantyRequestWasRejectedByAdmin
                : AppLocalizations.of(
                    context,
                  )!.warrantyRequestWasRejectedByTechnician,
            'status': 'rejected',
            'date': eventDate,
          });
        }
      }

      // Warranty expired
      if (widget.booking.warranty?.expiredOn != null) {
        final eventDate = widget.booking.warranty!.expiredOn!.toDate();

        if (currentTechCancelledAt == null ||
            eventDate.isBefore(currentTechCancelledAt) ||
            eventDate.isAtSameMomentAs(currentTechCancelledAt)) {
          timelineItems.add({
            'title': AppLocalizations.of(context)!.warrantyExpired,
            'time': _formatDateLocalized(eventDate, context),
            'description': AppLocalizations.of(
              context,
            )!.warrantyPeriodHasExpired,
            'status': 'rejected',
            'date': eventDate,
          });
        }
      }
    } else {
      // ==========================================
      // NORMAL BOOKING TIMELINE ONLY
      // ==========================================

      // Created
      if (widget.booking.createdAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.createdAt,
          'time': _formatDateLocalized(
            widget.booking.createdAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(
            context,
          )!.customerSubmittedBookingRequest,
          'status': 'completed',
          'date': widget.booking.createdAt!.toDate(),
        });
      }

      // Accepted
      if (widget.booking.acceptedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.acceptedAt,
          'time': _formatDateLocalized(
            widget.booking.acceptedAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(
            context,
          )!.serviceProviderConfirmedAppointment,
          'status': 'completed',
          'date': widget.booking.acceptedAt!.toDate(),
        });
      }

      // Tracking started
      if (widget.booking.trackingStartedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.trackingStartedAt,
          'time': _formatDateLocalized(
            widget.booking.trackingStartedAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(context)!.serviceTrackingInitiated,
          'status': 'completed',
          'date': widget.booking.trackingStartedAt!.toDate(),
        });
      }

      // Tracking stopped
      if (widget.booking.trackingStoppedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.trackingStoppedAt,
          'time': _formatDateLocalized(
            widget.booking.trackingStoppedAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(context)!.serviceTrackingStopped,
          'status': 'completed',
          'date': widget.booking.trackingStoppedAt!.toDate(),
        });
      }

      // Completed
      if (widget.booking.completedAt != null) {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.completedAt,
          'time': _formatDateLocalized(
            widget.booking.completedAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(
            context,
          )!.serviceHasBeenSuccessfullyCompleted,
          'status': 'completed',
          'date': widget.booking.completedAt!.toDate(),
        });
      }

      // Rejected
      if (widget.booking.bookingStatusCode.toLowerCase() == 'r') {
        final isAdminRejection = widget.booking.rejectedBy == "Admin";

        timelineItems.add({
          'title': isAdminRejection
              ? AppLocalizations.of(context)!.cancelledByAdmin
              : AppLocalizations.of(context)!.rejectedAt,
          'time': _formatDateLocalized(
            widget.booking.rejectedAt!.toDate(),
            context,
          ),
          'description': isAdminRejection
              ? '${AppLocalizations.of(context)!.cancelledBy}: ${AppLocalizations.of(context)!.admin}'
              : AppLocalizations.of(
                  context,
                )!.bookingWasRejectedByServiceProvider,
          'status': 'rejected',
          'date': widget.booking.rejectedAt!.toDate(),
        });
      }

      // Cancelled by customer
      if (widget.booking.bookingStatusCode.toLowerCase() == 'xc') {
        timelineItems.add({
          'title': AppLocalizations.of(context)!.cancelledByCustomer,
          'time': _formatDateLocalized(
            widget.booking.cancelledAt!.toDate(),
            context,
          ),
          'description': AppLocalizations.of(
            context,
          )!.bookingWasCancelledByCustomer,
          'status': 'rejected',
          'date': widget.booking.cancelledAt!.toDate(),
        });
      }

      // Worker cancellations (admin only)
      if (widget.isAdmin && widget.booking.cancelledWorkers.isNotEmpty) {
        for (var worker in widget.booking.cancelledWorkers) {
          final workerName = worker.agentName.isNotEmpty
              ? worker.agentName
              : AppLocalizations.of(context)!.unknownTechnician;

          timelineItems.add({
            'title': AppLocalizations.of(context)!.technicianCancelled,
            'time': _formatDateLocalized(worker.cancelledAt.toDate(), context),
            'description':
                '${AppLocalizations.of(context)!.cancelledByTechnician}: $workerName',
            'status': 'cancelled',
            'date': worker.cancelledAt.toDate(),
          });
        }
      }
    }

    // Counter Proposal Started
    if (widget.booking.counterProposalStartedAt != null) {
      final eventDate = widget.booking.counterProposalStartedAt!.toDate();
      timelineItems.add({
        'title': AppLocalizations.of(context)!.counterProposalStarted,
        'time': _formatDateLocalized(eventDate, context),
        'description': AppLocalizations.of(context)!.counterOfferSent,
        'status': 'completed',
        'date': eventDate,
      });
    }

    // Counter Proposal Accepted
    if (widget.booking.counterProposalAcceptedAt != null) {
      final eventDate = widget.booking.counterProposalAcceptedAt!.toDate();
      timelineItems.add({
        'title': AppLocalizations.of(context)!.counterProposalAccepted,
        'time': _formatDateLocalized(eventDate, context),
        'description': AppLocalizations.of(context)!.counterOfferResponse,
        'status': 'completed',
        'date': eventDate,
      });
    }

    // Sort ALL events by actual date (chronological order)
    timelineItems.sort((a, b) {
      final aDate = a['date'];
      final bDate = b['date'];

      // Convert Timestamp to DateTime if needed
      final aDateTime = aDate is DateTime
          ? aDate
          : (aDate as Timestamp).toDate();
      final bDateTime = bDate is DateTime
          ? bDate
          : (bDate as Timestamp).toDate();

      return aDateTime.compareTo(bDateTime);
    });

    // === ADD CURRENT/PENDING STATUS (ONLY if technician hasn't cancelled) ===

    if (currentTechCancelledAt == null) {
      bool isInProgress =
          widget.booking.trackingStartedAt != null &&
          widget.booking.trackingStoppedAt == null;

      if (isWarranty) {
        // Warranty current status
        // Only show pending status if warranty is not completed, rejected, or expired
        final warrantyStatusCode = widget.booking.warranty!.warrantyStatusCode
            .toLowerCase();
        final isWarrantyActive =
            widget.booking.warranty?.completedAt == null &&
            widget.booking.warranty?.rejectedAt == null &&
            warrantyStatusCode != 'e' && // Not expired
            warrantyStatusCode != 'x' && // Not rejected
            warrantyStatusCode != 'c'; // Not completed

        if (isWarrantyActive) {
          if (isInProgress) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.serviceInProgress,
              'time': AppLocalizations.of(context)!.current,
              'description': AppLocalizations.of(
                context,
              )!.serviceIsCurrentlyBeingPerformed,
              'status': 'current',
              'date': DateTime.now(),
            });
          } else if (widget.booking.warranty?.acceptedAt != null) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.waitingForServiceProvider,
              'time': AppLocalizations.of(context)!.pending,
              'description': AppLocalizations.of(
                context,
              )!.waitingForTechnicianToStartService,
              'status': 'current',
              'date': DateTime.now(),
            });
          } else {
            // Check if there are any rejected technicians
            final hasRejectedTechnicians =
                widget.booking.warranty?.rejectedTechnicians != null &&
                widget.booking.warranty!.rejectedTechnicians!.isNotEmpty;

            if (hasRejectedTechnicians) {
              // After technician rejection, waiting for admin to reassign
              timelineItems.add({
                'title': AppLocalizations.of(context)!.waitingForAdmin,
                'time': AppLocalizations.of(context)!.pending,
                'description': AppLocalizations.of(
                  context,
                )!.waitingForAdminToReassign,
                'status': 'current',
                'date': DateTime.now(),
              });
            } else {
              // Initial state, waiting for technician to accept
              timelineItems.add({
                'title': AppLocalizations.of(
                  context,
                )!.waitingForServiceProvider,
                'time': AppLocalizations.of(context)!.pending,
                'description': AppLocalizations.of(
                  context,
                )!.waitingForServiceProviderResponse,
                'status': 'current',
                'date': DateTime.now(),
              });
            }
          }
        }
      } else {
        // Normal booking current status
        if (widget.booking.completedAt == null &&
            widget.booking.rejectedAt == null &&
            widget.booking.bookingStatusCode.toLowerCase() != 'xc' &&
            widget.booking.bookingStatusCode.toLowerCase() != 'r') {
          if (isInProgress) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.serviceInProgress,
              'time': AppLocalizations.of(context)!.current,
              'description': AppLocalizations.of(
                context,
              )!.serviceIsCurrentlyBeingPerformed,
              'status': 'current',
              'date': DateTime.now(),
            });
          } else if (widget.booking.acceptedAt != null) {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.waitingForServiceProvider,
              'time': AppLocalizations.of(context)!.pending,
              'description': AppLocalizations.of(
                context,
              )!.waitingForTechnicianToStartService,
              'status': 'current',
              'date': DateTime.now(),
            });
          } else {
            timelineItems.add({
              'title': AppLocalizations.of(context)!.waitingForAcceptance,
              'time': AppLocalizations.of(context)!.pending,
              'description': AppLocalizations.of(
                context,
              )!.waitingForServiceProviderResponse,
              'status': 'current',
              'date': DateTime.now(),
            });
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.bookingTimeline,
                  style: DMSansFont.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ...timelineItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == timelineItems.length - 1;

              return _buildTimelineItem(
                title: item['title']!,
                time: item['time']!,
                description: item['description']!,
                status: item['status']!,
                isLast: isLast,
                colorScheme: colorScheme,
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helper method to format dates (you might already have this in your project)
  String _formatDateLocalized(DateTime date, BuildContext context) {
    return LocalizationHelper().formatDateLocalized(date, context);
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    required String description,
    required String status,
    required bool isLast,
    required ColorScheme colorScheme,
  }) {
    Color getStatusColor() {
      switch (status) {
        case 'completed':
          return Colors.green;
        case 'current':
          return colorScheme.primary;
        case 'rejected':
          return Colors.red;
        case 'cancelled':
          return Colors.orange;
        case 'pending':
        default:
          return colorScheme.outline;
      }
    }

    IconData getStatusIcon() {
      switch (status) {
        case 'completed':
          return Icons.check_circle;
        case 'current':
          return Icons.radio_button_checked;
        case 'rejected':
          return Icons.cancel;
        case 'cancelled':
          return Icons.block;
        case 'pending':
        default:
          return Icons.radio_button_unchecked;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: getStatusColor().withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(getStatusIcon(), size: 20, color: getStatusColor()),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: colorScheme.outline.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Timeline content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: DMSansFont.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status == 'pending'
                            ? colorScheme.onSurface.withOpacity(0.6)
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: DMSansFont.textStyle(
                    fontSize: 12,
                    color: status == 'pending'
                        ? colorScheme.onSurface.withOpacity(0.4)
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  time,
                  style: DMSansFont.textStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionDataCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (widget.booking.completionData == null) {
      return const SizedBox.shrink();
    }

    final completionData = widget.booking.completionData!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.tertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.completionDetails,
                  style: DMSansFont.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.booking.paymentCompleted) ...[
              _buildInfoRow(
                context,
                label: AppLocalizations.of(context)!.transactionId,
                value:
                    widget.booking.transactionId ??
                    widget.booking.orderId ??
                    "",
                textTheme: textTheme,
                colorScheme: colorScheme,
                needCopyButton: true,
              ),
              const SizedBox(height: 16),
            ],

            _buildInfoRow(
              context,
              label: AppLocalizations.of(context)!.invoiceType,
              value: completionData.mode == 0
                  ? AppLocalizations.of(context)!.inspection
                  : AppLocalizations.of(context)!.fullService,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),

            // Upload Files
            if (completionData.fileUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.uploadFilesTitle,
                style: DMSansFont.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              ..._buildFileLinks(context, completionData.fileUrls, colorScheme),
            ],

            // Service Items
            if (completionData.serviceItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.serviceItems,
                style: DMSansFont.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: completionData.serviceItems
                        .asMap()
                        .entries
                        .map(
                          (entry) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 12,
                                    child: Text(
                                      entry.value.name,
                                      style: DMSansFont.textStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'x${entry.value.quantity.toInt()}',
                                      style: DMSansFont.textStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      '${AppLocalizations.of(context)!.sar} ${entry.value.price.toStringAsFixed(2)}',
                                      style: DMSansFont.textStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (entry.key !=
                                  completionData.serviceItems.length - 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Divider(
                                    color: colorScheme.outline.withOpacity(0.2),
                                    height: 1,
                                  ),
                                ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],

            // Service Cost
            if (completionData.serviceCost > 0) ...[
              const SizedBox(height: 12),
              _buildCostRow(
                context,
                label: AppLocalizations.of(context)!.serviceCost,
                amount: completionData.serviceCost,
                colorScheme: colorScheme,
              ),
            ],

            // Payment Mode (before total)
            // if (widget.booking.bookingStatusCode.toLowerCase() == 'c' &&
            //     widget.booking.paymentCompleted) ...[
            //   const SizedBox(height: 16),
            //   _buildInfoRow(
            //     context,
            //     label: AppLocalizations.of(context)!.paymentMode,
            //     value: widget.booking.paymentModeCode.toLowerCase() == 'c'
            //         ? AppLocalizations.of(context)!.card
            //         : widget.booking.paymentModeCode.toLowerCase() == 'a'
            //         ? AppLocalizations.of(context)!.applePay
            //         : AppLocalizations.of(context)!.cashInHand,
            //     textTheme: textTheme,
            //     colorScheme: colorScheme,
            //   ),
            // ],

            // Total Cost
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.booking.paymentCompleted
                        ? AppLocalizations.of(context)!.amountPaid
                        : AppLocalizations.of(context)!.amountToBePaid,
                    style: DMSansFont.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.sar} ${completionData.totalCost.toStringAsFixed(2)}',
                    style: DMSansFont.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(
    BuildContext context, {
    required String label,
    required double amount,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DMSansFont.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          '${AppLocalizations.of(context)!.sar} ${amount.toStringAsFixed(2)}',
          style: DMSansFont.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFileLinks(
    BuildContext context,
    List<String> fileUrls,
    ColorScheme colorScheme,
  ) {
    return fileUrls
        .asMap()
        .entries
        .map(
          (entry) => Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == fileUrls.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => launchUrlString(entry.value),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(entry.value),
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getFileName(entry.value),
                        style: DMSansFont.textStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  IconData _getFileIcon(String fileUrl) {
    String lowerUrl = fileUrl.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx')) {
      return Icons.description;
    } else if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png')) {
      return Icons.image;
    }
    return Icons.attachment;
  }

  String _getFileName(String fileUrl) {
    return "file ${int.tryParse((fileUrl.split('/').last.split('?').first.split("_").elementAt(3).substring(0, 1)))! + 1}${(fileUrl.split('/').last.split('?').first.split("_").elementAt(3).substring(1))}";
  }

  Widget _buildReviewCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final review = widget.booking.review;
    if (review == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.reviews, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.review,
                  style: DMSansFont.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 30,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: review.rating != null ? review.rating!.toInt() : 0,
                itemBuilder: (context, index) {
                  return Icon(Icons.star, color: Colors.amber, size: 20);
                },
              ),
            ),
            const SizedBox(height: 16),
            if (review.review.isNotEmpty) ...[
              Text(
                '"${review.review}"',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Text(
                AppLocalizations.of(context)!.noReview,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final review = widget.booking.review;
    if (review == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.monetization_on, color: AppColors.green),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.tip,
                  style: DMSansFont.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            if (review.tipAmount != null && review.tipAmount! > 0) ...[
              _buildInfoRow(
                context,
                label: AppLocalizations.of(context)!.amount,
                value:
                    '${review.tipAmount} ${AppLocalizations.of(context)!.sar}',
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                label: AppLocalizations.of(context)!.paymentMode,
                value: review.paymentType?.toLowerCase() == 'cash'
                    ? AppLocalizations.of(context)!.cashInHand
                    : review.paymentType?.toLowerCase() == 'card'
                    ? AppLocalizations.of(context)!.card
                    : AppLocalizations.of(context)!.unknown,
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCounterOfferUI(BuildContext context, BookingModel booking) {
    final activeOffer = booking.activeCounterOffer;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;

    if (activeOffer != null) {
      if (activeOffer.status == 'pending') {
        if (activeOffer.proposedBy == 'customer') {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_repeat_rounded,
                      color: Colors.orange.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.customerProposedNewTime,
                        style: DMSansFont.textStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        size: 16,
                        color: Colors.orange.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatDateTimeDay(
                            activeOffer.proposedTime.toDate(),
                            locale,
                          ),
                          style: DMSansFont.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleCounterOfferResponse(
                          context,
                          booking,
                          'rejected',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(l10n.rejectOffer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _handleCounterConfirm(context, booking, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(l10n.acceptOffer),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: Colors.blue.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.waitingForCustomer,
                      style: DMSansFont.textStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${l10n.newProposedTime}: ${formatDateTimeDay(activeOffer.proposedTime.toDate(), locale)}",
                  style: DMSansFont.textStyle(
                    fontSize: 13,
                    color: Colors.grey[800]!,
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        final bool isRejected = activeOffer.status == 'rejected';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRejected ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRejected ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isRejected
                        ? Icons.cancel_outlined
                        : Icons.check_circle_outline,
                    color: isRejected ? Colors.red : Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isRejected ? l10n.proposalRejected : l10n.proposalAccepted,
                    style: DMSansFont.textStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isRejected ? Colors.red : Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isRejected) ...[
                Text(
                  activeOffer.proposedBy == 'technician'
                      ? l10n.customerRejectedProposal
                      : l10n.youRejectedProposal,
                  style: DMSansFont.textStyle(
                    fontSize: 13,
                    color: Colors.grey[700]!,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        CounterOfferUtils.showCounterOfferDatePicker(
                          context,
                          booking,
                        ),
                    icon: const Icon(Icons.history_toggle_off, size: 18),
                    label: Text(l10n.proposeNewTime),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  "${l10n.appointmentRescheduledTo}: ${formatDateTimeDay(activeOffer.proposedTime.toDate(), locale)}",
                  style: DMSansFont.textStyle(
                    fontSize: 13,
                    color: Colors.grey[700]!,
                  ),
                ),
              ],
            ],
          ),
        );
      }
    } else if (!widget.isAdmin &&
        !widget.isWarranty &&
        booking.bookingStatusCode.toUpperCase() == 'P') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        child: ElevatedButton.icon(
          onPressed: () =>
              CounterOfferUtils.showCounterOfferDatePicker(context, booking),
          icon: const Icon(Icons.history_toggle_off, size: 20),
          label: Text(
            l10n.proposeNewTime,
            style: DMSansFont.textStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPendingBookingControls(
    BuildContext context,
    BookingModel booking,
  ) {
    if (booking.activeCounterOffer != null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () =>
                        _showAcceptConfirmationDialog(context, booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.accept,
                      style: DMSansFont.textStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _showRejectBookingDialog(context, booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.reject,
                      style: DMSansFont.textStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => CounterOfferUtils.showCounterOfferDatePicker(
                context,
                booking,
              ),
              icon: const Icon(Icons.history_toggle_off, size: 20),
              label: Text(
                l10n.proposeNewTime,
                style: DMSansFont.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptConfirmationDialog(
    BuildContext context,
    BookingModel booking,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.acceptBooking,
          style: DMSansFont.textStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          l10n.areYouSureYouWantToAcceptThisBooking,
          style: DMSansFont.textStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await AppFirestore.bookingsCollectionRef
                    .doc(booking.id)
                    .update({
                      'bookingStatusCode': 'A',
                      'acceptedAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.anErrorOccurred),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showRejectBookingDialog(BuildContext context, BookingModel booking) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.rejectBooking,
          style: DMSansFont.textStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          l10n.areYouSureYouWantToRejectThisBooking,
          style: DMSansFont.textStyle(color: Colors.grey[600]),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<BookingBloc>().add(
                        CancelBooking(
                          bookingId: booking.id,
                          agentUid: booking.agent?.uid ?? '',
                          agentName: booking.agent?.name ?? '',
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.reject,
                      style: DMSansFont.textStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      CounterOfferUtils.showCounterOfferDatePicker(
                        context,
                        booking,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.proposeNewTime,
                      style: DMSansFont.textStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.cancel,
                      style: DMSansFont.textStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCounterConfirm(
    BuildContext context,
    BookingModel booking,
    String response,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.acceptOffer),
        content: Text(l10n.rescheduleBookingTimeConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.yes,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _handleCounterOfferResponse(context, booking, response);
    }
  }

  Future<void> _handleCounterOfferResponse(
    BuildContext context,
    BookingModel booking,
    String response,
  ) async {
    final success = await AppServices.respondToCounterOffer(
      booking: booking,
      response: response,
    );
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.completed)),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.anErrorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTimestampText(BuildContext context, BookingModel booking) {
    if (widget.isWarranty) return _buildWarrantyTimestamp(context, booking);
    return _buildBookingTimestamp(context, booking);
  }

  Widget _buildBookingTimestamp(BuildContext context, BookingModel booking) {
    final locale = AppLocalizations.of(context)?.localeName ?? 'en';

    if (booking.bookingStatusCode == "P" && booking.createdAt != null) {
      return _timestampText(
        "${AppLocalizations.of(context)!.bookedOn} : ${formatBookingDateTime(booking.createdAt!.toDate(), locale)}",
      );
    }
    if (booking.acceptedAt != null && booking.bookingStatusCode == "A") {
      return _timestampText(
        "${AppLocalizations.of(context)!.acceptedAt} : ${formatBookingDateTime(booking.acceptedAt!.toDate(), locale)}",
      );
    }
    if (booking.completedAt != null && booking.bookingStatusCode == "C") {
      return _timestampText(
        "${AppLocalizations.of(context)!.completedOn} : ${formatBookingDateTime(booking.completedAt!.toDate(), locale)}",
      );
    }
    if (booking.bookingStatusCode == "X" ||
        booking.bookingStatusCode == "XC" ||
        booking.bookingStatusCode == "R") {
      if (booking.bookingStatusCode != "R") {
        if (booking.cancelledAt == null) return const SizedBox.shrink();
        return _timestampText(
          "${AppLocalizations.of(context)!.cancelledOn} : ${formatBookingDateTime(booking.cancelledAt!.toDate(), locale)}",
        );
      }
      if (booking.rejectedAt == null) return const SizedBox.shrink();
      return _timestampText(
        "${AppLocalizations.of(context)!.rejectedOn} : ${formatBookingDateTime(booking.rejectedAt!.toDate(), locale)}",
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildWarrantyTimestamp(BuildContext context, BookingModel booking) {
    final warranty = booking.warranty;
    if (warranty == null) return const SizedBox.shrink();
    final locale = AppLocalizations.of(context)?.localeName ?? 'en';
    final statusCode = warranty.warrantyStatusCode;
    final timestampMap = {
      "A": (warranty.createdAt != null)
          ? "${AppLocalizations.of(context)!.warrantyAppliedOn} : ${formatBookingDateTime(warranty.createdAt!.toDate(), locale)}"
          : null,
      "C": (warranty.completedAt != null)
          ? "${AppLocalizations.of(context)!.completedOn} : ${formatBookingDateTime(warranty.completedAt!.toDate(), locale)}"
          : null,
      "E": (warranty.expiredOn != null)
          ? "${AppLocalizations.of(context)!.expiredOn} : ${formatBookingDateTime(warranty.expiredOn!.toDate(), locale)}"
          : null,
      "X": (warranty.rejectedAt != null)
          ? "${AppLocalizations.of(context)!.rejectedOn} : ${formatBookingDateTime(warranty.rejectedAt!.toDate(), locale)}"
          : null,
      "R": (warranty.requestedOn != null)
          ? "${AppLocalizations.of(context)!.requestedOn} : ${formatBookingDateTime(warranty.requestedOn!.toDate(), locale)}"
          : null,
      "S": (warranty.acceptedAt != null)
          ? "${AppLocalizations.of(context)!.acceptedOn} : ${formatBookingDateTime(warranty.acceptedAt!.toDate(), locale)}"
          : null,
    };
    final text = timestampMap[statusCode];
    return text != null ? _timestampText(text) : const SizedBox.shrink();
  }

  Widget _timestampText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_month, size: 19, color: AppColors.black1),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: AppColors.black1, fontSize: 10.5)),
      ],
    );
  }
}

class VerifyPaymentControls extends StatelessWidget {
  final BookingModel booking;
  const VerifyPaymentControls({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.verificationPending,
                style: DMSansFont.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.waitingForTechnicianVerification,
            style: DMSansFont.textStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () =>
                  showVerifyPaymentSheet(context, booking: booking),
              icon: const Icon(Icons.verified_rounded, color: Colors.white),
              label: Text(
                AppLocalizations.of(context)!.verifyPayment,
                style: DMSansFont.textStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height + 1; // +1 for the divider
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1; // +1 for the divider

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _tabBar,
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
