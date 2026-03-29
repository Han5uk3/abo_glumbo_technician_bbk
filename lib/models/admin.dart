import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  String? uid;
  String name;
  String email;
  String phoneNumber;
  int accessLevel; // 1 = Customer Service, 2 = Full Admin
  Timestamp? createdAt;
  bool isCoreAdmin;

  AdminModel({
    this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.accessLevel,
    this.createdAt,
    this.isCoreAdmin = false,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return AdminModel(
      uid: id ?? json['uid'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      accessLevel: json['accessLevel'] ?? 1,
      createdAt: json['createdAt'],
      isCoreAdmin: json['isCoreAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'accessLevel': accessLevel,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'isCoreAdmin': isCoreAdmin,
    };
  }

  AdminModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    int? accessLevel,
    Timestamp? createdAt,
    bool? isCoreAdmin,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accessLevel: accessLevel ?? this.accessLevel,
      createdAt: createdAt ?? this.createdAt,
      isCoreAdmin: isCoreAdmin ?? this.isCoreAdmin,
    );
  }
}
