import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String id;
  final String? invoiceUrl;
  final String? invoiceUrlEn;
  final String? invoiceUrlAr;
  final String? invoiceUrlUr;
  final Timestamp createdAt;
  final String bookingId;
  final String? newBookingId;
  final String userId;
  final String? technicianId;

  InvoiceModel({
    required this.id,
    this.invoiceUrl,
    this.invoiceUrlEn,
    this.invoiceUrlAr,
    this.invoiceUrlUr,
    required this.createdAt,
    required this.bookingId,
    this.newBookingId,
    required this.userId,
    this.technicianId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (invoiceUrl != null) 'invoiceUrl': invoiceUrl,
      if (invoiceUrlEn != null) 'invoiceUrlEn': invoiceUrlEn,
      if (invoiceUrlAr != null) 'invoiceUrlAr': invoiceUrlAr,
      if (invoiceUrlUr != null) 'invoiceUrlUr': invoiceUrlUr,
      'createdAt': createdAt,
      'bookingId': bookingId,
      if (newBookingId != null) 'newBookingId': newBookingId,
      'userId': userId,
      if (technicianId != null) 'technicianId': technicianId,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      invoiceUrl: map['invoiceUrl'],
      invoiceUrlEn: map['invoiceUrlEn'],
      invoiceUrlAr: map['invoiceUrlAr'],
      invoiceUrlUr: map['invoiceUrlUr'],
      createdAt: map['createdAt'],
      bookingId: map['bookingId'],
      newBookingId: map['newBookingId'],
      userId: map['userId'],
      technicianId: map['technicianId'],
    );
  }
}
