import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aboglumbo_bbk_panel/models/user.dart';

class WarrantyModel {
  String? id;
  UserModel? assignedTechnician;
  String? assignedTechnicianId;
  String warrantyStatusCode;
  bool? claimrequested;
  List<RejectedTechnicianModel>? rejectedTechnicians;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  Timestamp? requestedOn;
  Timestamp? completedAt;

  /// When an admin (re)assigned a technician to this claim. Distinct from
  /// [acceptedAt], which is only set once that technician actually accepts.
  Timestamp? assignedAt;
  Timestamp? acceptedAt;
  Timestamp? rejectedAt;
  Timestamp? expiredOn;
  Timestamp? preferredDateTime;
  bool? availability;
  Timestamp? trackingStartedAt;
  Timestamp? trackingStoppedAt;
  Timestamp? arrivedAt;

  WarrantyModel({
    this.id,
    this.assignedTechnician,
    this.assignedTechnicianId,
    this.warrantyStatusCode = 'A',
    this.claimrequested,
    this.rejectedTechnicians = const [],
    this.createdAt,
    this.updatedAt,
    this.requestedOn,
    this.completedAt,
    this.assignedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.expiredOn,
    this.preferredDateTime,
    this.availability,
    this.trackingStartedAt,
    this.trackingStoppedAt,
    this.arrivedAt,
  });

  factory WarrantyModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert timestamp fields
    Timestamp? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value;
      if (value is String) {
        try {
          return Timestamp.fromDate(DateTime.parse(value));
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return WarrantyModel(
      id: json['id'],
      assignedTechnician: json['assignedTechnician'] != null
          ? UserModel.fromJson(
              json['assignedTechnician'] as Map<String, dynamic>,
            )
          : null,
      assignedTechnicianId: json['assignedTechnicianId'],
      warrantyStatusCode: json['warrantyStatusCode']?.toString() ?? 'A',
      claimrequested: json['claimrequested'] as bool?,
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
      requestedOn: parseTimestamp(json['requestedOn']),
      completedAt: parseTimestamp(json['completedAt']),
      assignedAt: parseTimestamp(json['assignedAt']),
      acceptedAt:
          parseTimestamp(json['acceptedAt']) ??
          parseTimestamp(json['acceptedOn']),
      rejectedAt: parseTimestamp(json['rejectedAt']),
      expiredOn: parseTimestamp(json['expiredOn']),
      preferredDateTime: parseTimestamp(json['preferredDateTime']),
      availability: json['availability'] as bool?,
      trackingStartedAt: parseTimestamp(json['trackingStartedAt']),
      trackingStoppedAt: parseTimestamp(json['trackingStoppedAt']),
      arrivedAt: parseTimestamp(json['arrivedAt']),
      rejectedTechnicians: (json['rejectedTechnicians'] is List)
          ? (json['rejectedTechnicians'] as List)
                .map(
                  (e) => RejectedTechnicianModel.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignedTechnician': assignedTechnician?.toJson(),
      'assignedTechnicianId': assignedTechnicianId,
      'warrantyStatusCode': warrantyStatusCode,
      'claimrequested': claimrequested,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'requestedOn': requestedOn,
      'completedAt': completedAt,
      'assignedAt': assignedAt,
      'acceptedAt': acceptedAt,
      'rejectedAt': rejectedAt,
      'expiredOn': expiredOn,
      'preferredDateTime': preferredDateTime,
      'availability': availability,
      'trackingStartedAt': trackingStartedAt,
      'trackingStoppedAt': trackingStoppedAt,
      'arrivedAt': arrivedAt,
      'rejectedTechnicians': rejectedTechnicians
          ?.map((e) => e.toJson())
          .toList(),
    };
  }

  static WarrantyModel fromDocumentSnapshot(QueryDocumentSnapshot doc) {
    return WarrantyModel.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  String toString() {
    return 'WarrantyModel(id: $id, status: $warrantyStatusCode, '
        'assignedTo: ${assignedTechnician?.name ?? "None"} (${assignedTechnician?.uid ?? "N/A"}), '
        'requestedOn: $requestedOn, acceptedAt: $acceptedAt, '
        'completedAt: $completedAt, rejectedAt: $rejectedAt)';
  }
}

class RejectedTechnicianModel {
  String? uid;
  String? name;
  String? phone;
  String? reason;
  Timestamp? rejectedAt;

  RejectedTechnicianModel({
    this.uid,
    this.name,
    this.phone,
    this.reason,
    this.rejectedAt,
  });

  factory RejectedTechnicianModel.fromJson(Map<String, dynamic> json) {
    // Safely parse timestamp
    Timestamp? rejectedAtTimestamp;
    final rejectedAtValue = json['rejectedAt'];
    if (rejectedAtValue != null) {
      if (rejectedAtValue is Timestamp) {
        rejectedAtTimestamp = rejectedAtValue;
      } else if (rejectedAtValue is String) {
        try {
          rejectedAtTimestamp = Timestamp.fromDate(
            DateTime.parse(rejectedAtValue),
          );
        } catch (e) {
          rejectedAtTimestamp = null;
        }
      }
    }

    return RejectedTechnicianModel(
      uid: json['uid'],
      name: json['name'],
      phone: json['phone'],
      reason: json['reason'],
      rejectedAt: rejectedAtTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'reason': reason,
      'rejectedAt': rejectedAt,
    };
  }
}
