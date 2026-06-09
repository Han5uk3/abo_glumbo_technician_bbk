import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';


class JobRequestModel {
  final String id;
  final ServiceModel service;
  final CustomerModel customer;
  final Map<String, dynamic> address;
  final String notes;
  final String? issueImage;
  final String? issueVideo;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final bool isOnHour;
  final Timestamp? bookingDateTime;
  final String status;
  final bool isRebook;
  final String? rebookTechnicianId;

  JobRequestModel({
    required this.id,
    required this.service,
    required this.customer,
    required this.address,
    required this.notes,
    this.issueImage,
    this.issueVideo,
    required this.createdAt,
    required this.expiresAt,
    this.isOnHour = true,
    this.bookingDateTime,
    required this.status,
    this.isRebook = false,
    this.rebookTechnicianId,
  });

  factory JobRequestModel.fromJson(Map<String, dynamic> json) {
    return JobRequestModel(
      id: json['id'] ?? '',
      service: ServiceModel.fromJson(json['service']),
      customer: CustomerModel.fromJson(json['customer']),
      address: json['address'] as Map<String, dynamic>,
      notes: json['notes'] ?? '',
      issueImage: json['issueImage'],
      issueVideo: json['issueVideo'],
      createdAt: json['createdAt'] as Timestamp,
      expiresAt: json['expiresAt'] as Timestamp,
      isOnHour: json['isOnHour'] ?? true,
      bookingDateTime: json['bookingDateTime'] as Timestamp?,
      status: json['status'] ?? 'pending',
      isRebook: json['isRebook'] ?? false,
      rebookTechnicianId: json['rebookTechnicianId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': service.toJson(),
      'customer': customer.toJson(),
      'address': address,
      'notes': notes,
      'issueImage': issueImage,
      'issueVideo': issueVideo,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'isOnHour': isOnHour,
      'bookingDateTime': bookingDateTime,
      'status': status,
      'isRebook': isRebook,
      'rebookTechnicianId': rebookTechnicianId,
    };
  }
}
