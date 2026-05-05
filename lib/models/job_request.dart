import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/models/customer.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart'; // Address is location in tech app? Wait let me check.

class JobRequestModel {
  final String id;
  final ServiceModel service;
  final CustomerModel customer;
  final Map<String, dynamic> address; // Using map for flexibility if models differ slightly
  final String notes;
  final String? issueImage;
  final String? issueVideo;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final String status;

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
    required this.status,
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
      status: json['status'] ?? 'pending',
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
      'status': status,
    };
  }
}
