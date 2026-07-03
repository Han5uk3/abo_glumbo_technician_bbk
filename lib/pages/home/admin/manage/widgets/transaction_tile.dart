import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:aboglumbo_bbk_panel/models/transaction.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shimmer/shimmer.dart';

class TransactionTile extends StatefulWidget {
  const TransactionTile({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  late Future<BookingModel?> _bookingFuture;

  @override
  void initState() {
    super.initState();
    // Cache the future to prevent refetching on parent rebuilds
    _bookingFuture = AppServices.getBooking(widget.transaction.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        widget.transaction.paymentStatus.toLowerCase() == 'completed' ||
        widget.transaction.paymentStatus.toLowerCase() == 'paid';

    return FutureBuilder<BookingModel?>(
      future: _bookingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerTile();
        }
        final booking = snapshot.data;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showTransactionDetailsDialog(context, booking),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildPaymentIcon(isCompleted),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTransactionInfo(context, booking)),
                  const SizedBox(width: 12),
                  _buildAmountBadge(isCompleted, context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentIcon(bool isCompleted) {
    final isCash = widget.transaction.paymentMethod.toLowerCase().contains(
      'cash',
    );

    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCompleted
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.orange.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isCompleted ? Colors.green : Colors.orange).withOpacity(
                  0.3,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isCash ? Icons.money : Icons.credit_card,
            color: Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionInfo(BuildContext context, BookingModel? booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          booking?.customer.name ?? '-',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Payment Method
        Row(
          children: [
            Icon(
              widget.transaction.paymentMethod.toLowerCase().contains('cash')
                  ? Icons.payments
                  : Icons.credit_card,
              size: 14,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.transaction.paymentMethod.toLowerCase().contains(
                          'cash',
                        ) ||
                        widget.transaction.paymentMethod.toLowerCase().contains(
                          'outside',
                        )
                    ? AppLocalizations.of(context)!.outsideApp
                    : AppLocalizations.of(context)!.inApp,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Date
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _formatDate(widget.transaction.createdAt.toDate(), context),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountBadge(bool isCompleted, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : LinearGradient(
                colors: [Colors.orange.shade50, Colors.orange.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? Colors.green : Colors.orange).withOpacity(
              0.1,
            ),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.amount,
            style: TextStyle(
              fontSize: 10,
              color: isCompleted
                  ? Colors.green.shade600
                  : Colors.orange.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${widget.transaction.amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isCompleted
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      // Format: day-month-year hr:min am/pm
      final formatter = DateFormat(
        locale == 'ar' ? 'dd-MM-yyyy hh:mm a' : 'dd-MM-yyyy hh:mm a',
        locale,
      );
      return formatter.format(date);
    } else if (difference.inDays > 0) {
      return AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
    } else {
      return AppLocalizations.of(context)!.justNow;
    }
  }

  void _showTransactionDetailsDialog(
    BuildContext context,
    BookingModel? booking,
  ) {
    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loading),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final isCompleted =
        widget.transaction.paymentStatus.toLowerCase() == 'completed' ||
        widget.transaction.paymentStatus.toLowerCase() == 'paid';
    final statusColor = isCompleted ? Colors.green : Colors.orange;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header with Status
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.shade400, statusColor.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.transactionDetails,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isCompleted
                                      ? AppLocalizations.of(context)!.completed
                                      : AppLocalizations.of(context)!.pending,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Amount Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.amount,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${widget.transaction.amount.toStringAsFixed(2)} ${AppLocalizations.of(context)!.sar}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking Information Card
                      _buildInfoCard(
                        context,
                        AppLocalizations.of(context)!.bookingInfo,
                        Icons.event_note_rounded,
                        Colors.blue,
                        [
                          _buildDetailRow(
                            context,
                            AppLocalizations.of(context)!.bookingId,
                            booking.newBookingId ??
                                widget.transaction.bookingId,
                            copyable: true,
                          ),
                          _buildDetailRow(
                            context,
                            AppLocalizations.of(context)!.orderId,
                            widget.transaction.orderId,
                            copyable: true,
                          ),
                          _buildDetailRow(
                            context,
                            AppLocalizations.of(context)!.bookingName,
                            booking.service.nameLocalized(
                                  languageCode: Localizations.localeOf(
                                    context,
                                  ).languageCode,
                                ) ??
                                booking.service.name ??
                                "",
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            context,
                            AppLocalizations.of(context)!.date,
                            _formatDate(
                              widget.transaction.createdAt.toDate(),
                              context,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // People Information Card
                      _buildInfoCard(
                        context,
                        '${AppLocalizations.of(context)!.customer} & ${AppLocalizations.of(context)!.agent}',
                        Icons.people_rounded,
                        Colors.purple,
                        [
                          _buildDetailRow(
                            context,
                            AppLocalizations.of(context)!.customerName,
                            booking.customer.name ?? '-',
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            context,
                            AppLocalizations.of(context)!.technicianName,
                            booking.agent?.name ??
                                AppLocalizations.of(context)!.notAssigned,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Payment Information Card
                      _buildInfoCard(
                        context,
                        AppLocalizations.of(context)!.paymentMode,
                        Icons.payment_rounded,
                        Colors.teal,
                        [
                          _buildDetailRow(
                            context,
                            AppLocalizations.of(context)!.paymentMethod,
                            getPaymentMethodText(
                              context,
                              widget.transaction.paymentMethod,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.close,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  String getPaymentMethodText(BuildContext context, String method) {
    final lowerMethod = method.toLowerCase();
    if (lowerMethod.contains('outside') ||
        lowerMethod.contains('cash') ||
        lowerMethod.contains('hand')) {
      return AppLocalizations.of(context)!.outsideApp;
    } else {
      return AppLocalizations.of(context)!.inApp;
    }
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color is MaterialColor ? color.shade700 : color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color is MaterialColor ? color.shade800 : color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool copyable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (copyable)
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: Colors.blue.shade700),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.copiedToClipboard,
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              // Info Placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount Badge Placeholder
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
