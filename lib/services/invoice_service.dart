import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';
import 'package:intl/intl.dart';

import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';

class InvoiceService {
  static Future<void> generateAndShowInvoice(
    BuildContext context,
    BookingModel booking,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final pdf = pw.Document();

    // Load logo if exists
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/images/app_icon_new.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Logo not found, proceed without it
    }

    final data = booking.completionData;
    if (data == null) return;

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final completedAtStr = booking.completedAt != null
        ? dateFormat.format(booking.completedAt!.toDate())
        : ((loc.localeName == 'ar')
            ? 'غير متوفر'
            : (loc.localeName == 'ur')
                ? 'دستیاب نہیں'
                : 'N/A');

    final isArabic = loc.localeName == 'ar' || loc.localeName == 'ur';
    final ttf = await PdfGoogleFonts.cairoRegular();
    final ttfBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(base: ttf, bold: ttfBold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logo != null)
                    pw.Container(width: 80, height: 80, child: pw.Image(logo)),
                  pw.SizedBox(height: 10),
                  pw.Text("Abo Glumbo", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text(loc.invoiceTitle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(loc.invoiceWord, style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                  pw.SizedBox(height: 10),
                  pw.Text(loc.invoiceNumber(booking.id.substring(0, 8).toUpperCase())),
                  pw.Text(loc.dateString(dateFormat.format(DateTime.now()))),
                  pw.Text(loc.statusPaid, style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          // Customer & Booking Info
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(loc.billTo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      booking.customer.name ??
                          ((loc.localeName == 'ar')
                              ? 'عميلنا العزيز'
                              : (loc.localeName == 'ur')
                                  ? 'معزز صارف'
                                  : 'Valued Customer'),
                    ),
                    pw.Text(booking.customer.phone ?? ""),
                    () {
                      final address = booking.customer.addresses.firstWhere(
                        (a) => a.isSelected == true,
                        orElse: () => booking.customer.addresses.isNotEmpty
                            ? booking.customer.addresses.first
                            : AddressModel(
                                id: '',
                                fullName: '',
                                buildingNumber: '',
                                phoneNumber: '',
                              ),
                      );

                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "${address.buildingNumber}${address.streetName != null ? ', ${address.streetName}' : ''}",
                          ),
                          if (booking.customer.districtName != null ||
                              booking.customer.cityName != null)
                            pw.Text(
                              "${booking.customer.districtName ?? ''}${booking.customer.districtName != null && booking.customer.cityName != null ? ', ' : ''}${booking.customer.cityName ?? ''}",
                            ),
                          if (booking.customer.location?.fullAddress != null &&
                              booking
                                  .customer
                                  .location!
                                  .fullAddress!
                                  .isNotEmpty)
                            pw.Text(booking.customer.location!.fullAddress!),
                          if (booking.serviceLocation != null)
                            pw.Text(
                              booking.serviceLocation!.localizedName(
                                loc.localeName,
                              ),
                            ),
                        ],
                      );
                    }(),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(loc.bookingDetailsInvoice, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(loc.serviceLabel(booking.service.nameLocalized(languageCode: loc.localeName) ?? '')),
                    pw.Text(loc.completedAtLabel(completedAtStr)),
                    pw.Text(loc.paymentModeLabel(booking.paymentModeCode.toUpperCase() == 'C' ? loc.insideApp : booking.paymentModeCode.toUpperCase() == 'A' ? loc.applePay : loc.outsideApp)),
                    if (booking.transactionId != null)
                      pw.Text(loc.transactionIdLabel(booking.transactionId!)),
                    pw.Text(
                      loc.warrantyLabel(
                        () {
                          final daysDiff = booking.warranty?.expiredOn != null &&
                                  (booking.warranty?.createdAt != null ||
                                      booking.completedAt != null)
                              ? booking.warranty!.expiredOn!.toDate().difference((booking.warranty!.createdAt ?? booking.completedAt)!.toDate()).inDays
                              : 7;

                          return (loc.localeName == 'ar')
                              ? "$daysDiff أيام"
                              : (loc.localeName == 'ur')
                                  ? "$daysDiff دن"
                                  : "$daysDiff Days";
                        }(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          // Items Table
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: (loc.localeName == 'ar')
                ? ['الوصف', 'الكمية', 'سعر الوحدة', 'المبلغ']
                : (loc.localeName == 'ur')
                    ? ['تفصیل', 'مقدار', 'فی اکائی قیمت', 'رقم']
                    : ['Description', 'Quantity', 'Unit Price', 'Amount'],
            data: [
              ...data.serviceItems.map(
                (item) => [
                  item.name,
                  item.quantity.toStringAsFixed(0),
                  loc.sarAmount(item.price.toStringAsFixed(2)),
                  loc.sarAmount((item.quantity * item.price).toStringAsFixed(2)),
                ],
              ),
              if (data.inspectionFee > 0)
                [
                  loc.inspectionFee,
                  '1',
                  loc.sarAmount(data.inspectionFee.toStringAsFixed(2)),
                  loc.sarAmount(data.inspectionFee.toStringAsFixed(2)),
                ],
            ],
          ),
          pw.SizedBox(height: 20),

          // Totals
          pw.Row(
            children: [
              pw.Spacer(flex: 2),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(loc.subtotal),
                        pw.Text(
                          loc.sarAmount(data.serviceCost.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                    if (data.inspectionFee > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(loc.inspectionFee),
                          pw.Text(
                            loc.sarAmount(
                                  data.inspectionFee.toStringAsFixed(2),
                                ),
                          ),
                        ],
                      ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          loc.totalLabel,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          loc.sarAmount(data.totalCost.toStringAsFixed(2)),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 60),
          pw.Center(
            child: pw.Text(
              loc.thankYouInvoice,
              style: pw.TextStyle(
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey,
              ),
            ),
          ),
        ],
      ),
    );

    // Show preview/print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
      name: 'Invoice_${booking.id.substring(0, 8)}',
    );
  }
}
