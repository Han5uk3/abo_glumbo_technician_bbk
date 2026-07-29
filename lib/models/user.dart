import 'package:aboglumbo_bbk_panel/helpers/country_code_detector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/location.dart';

class UserModel {
  String? uid;
  String? name;
  String? email;
  String? phone;
  String? country;
  String? lanCode;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  LocationModel? location;
  LiveLocation? liveLocation;
  bool? isAdmin;
  bool? isVerified;
  String? districtName;
  List<String>? jobRoles;
  String? docUrl;
  String? profileUrl;
  String? fcmToken;
  /// Running **sum** of every review score this technician has received.
  /// Not a displayable rating on its own — use [averageRating].
  double? rating;

  /// Number of jobs that have been rated. Denominator for [averageRating].
  int? reviewCount;
  String? availableBalance;
  String? paidAmounts;
  List<String>? certifications;
  List<PayoutAccountModel>? payoutAccounts = <PayoutAccountModel>[];
  double? paidoutTips;
  bool? isOnline;
  String? highestTier;
  double? totalMonthlyBonus;
  Timestamp? lastBonusDate;
  int? currentMonthJobs;
  int? previousMonthJobs;
  String? tier;
  double? bonusAmount;
  String? previousMonthTier;
  double? previousMonthRating;
  String? lastBonusMonth;
  // Admin access tracking
  bool? isGrantedAdminByMain; // Track if admin access was granted by main admin
  int? adminAccessLevel; // 1 = Full Admin, 2 = Customer Service (view only)
  Timestamp? grantedAdminAt; // When admin access was granted
  GeoPoint? lastKnownLocation;
  String? geohash;
  String role;
  String? residenceIdUrl;
  String? sponsorWorkPermitUrl;
  String? chamberOfCommerceApprovalUrl;
  bool? isBlocked;
  String? rejectionReason;
  bool? isDocsPendingReview; // Flag to indicate docs are ready for admin review
  bool? isRegistrationComplete; // Flag for initial registration completion

  /// The technician's displayable star rating, 0.0 when they have no reviews yet.
  ///
  /// `rating` holds the running SUM of review scores and `reviewCount` the number
  /// of rated jobs; both are maintained transactionally by the
  /// `updateTechnicianRatingOnReview` Cloud Function. Always display through this
  /// getter rather than reading `rating` directly, otherwise the raw sum leaks
  /// into the UI as an absurd star value.
  double get averageRating {
    final count = reviewCount ?? 0;
    if (count <= 0) return 0.0;
    return (rating ?? 0.0) / count;
  }

  UserModel({
    this.uid,
    this.name,
    this.certifications,
    this.email,
    this.phone,
    this.lanCode,
    this.country,
    this.createdAt,
    this.updatedAt,
    this.location,
    this.liveLocation,
    this.isAdmin,
    this.isVerified,
    this.districtName,
    this.jobRoles,
    this.docUrl,
    this.profileUrl,
    this.fcmToken,
    this.rating,
    this.reviewCount,
    this.isOnline,
    this.payoutAccounts,
    this.availableBalance,
    this.paidAmounts,
    this.highestTier,
    this.totalMonthlyBonus,
    this.lastBonusDate,
    this.currentMonthJobs,
    this.previousMonthJobs,
    this.tier,
    this.bonusAmount,
    this.previousMonthTier,
    this.previousMonthRating,
    this.lastBonusMonth,
    this.isGrantedAdminByMain,
    this.adminAccessLevel,
    this.grantedAdminAt,
    this.lastKnownLocation,
    this.geohash,
    required this.role,
    this.paidoutTips,
    this.residenceIdUrl,
    this.sponsorWorkPermitUrl,
    this.chamberOfCommerceApprovalUrl,
    this.isBlocked,
    this.rejectionReason,
    this.isDocsPendingReview,
    this.isRegistrationComplete,
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? country,
    String? lanCode,
    LocationModel? location,
    LiveLocation? liveLocation,
    List<String>? favourites,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isAdmin,
    bool? isVerified,
    String? districtName,
    List<String>? jobRoles,
    String? docUrl,
    String? profileUrl,
    String? fcmToken,
    double? rating,
    int? reviewCount,
    List<PayoutAccountModel>? payoutAccounts,
    String? availableBalance,
    String? paidAmounts,
    String? highestTier,
    double? totalMonthlyBonus,
    List<String>? certifications,
    Timestamp? lastBonusDate,
    int? currentMonthJobs,
    int? previousMonthJobs,
    String? tier,
    double? bonusAmount,
    String? previousMonthTier,
    double? previousMonthRating,
    String? lastBonusMonth,
    double? paidoutTips,
    bool? isOnline,
    bool? isGrantedAdminByMain,
    int? adminAccessLevel,
    Timestamp? grantedAdminAt,
    GeoPoint? lastKnownLocation,
    String? geohash,
    String role = 'technician',
    String? residenceIdUrl,
    String? sponsorWorkPermitUrl,
    String? chamberOfCommerceApprovalUrl,
    bool? isBlocked,
    String? rejectionReason,
    bool? isDocsPendingReview,
    bool? isRegistrationComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      districtName: districtName ?? this.districtName,
      location: location ?? this.location,
      liveLocation: liveLocation ?? this.liveLocation,
      lanCode: lanCode ?? this.lanCode,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      isVerified: isVerified ?? this.isVerified,
      jobRoles: jobRoles ?? this.jobRoles,
      docUrl: docUrl ?? this.docUrl,
      profileUrl: profileUrl ?? this.profileUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      availableBalance: availableBalance ?? this.availableBalance,
      paidAmounts: paidAmounts ?? this.paidAmounts,
      payoutAccounts: payoutAccounts ?? this.payoutAccounts,
      highestTier: highestTier ?? this.highestTier,
      totalMonthlyBonus: totalMonthlyBonus ?? this.totalMonthlyBonus,
      lastBonusDate: lastBonusDate ?? this.lastBonusDate,
      currentMonthJobs: currentMonthJobs ?? this.currentMonthJobs,
      previousMonthJobs: previousMonthJobs ?? this.previousMonthJobs,
      tier: tier ?? this.tier,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      previousMonthTier: previousMonthTier ?? this.previousMonthTier,
      previousMonthRating: previousMonthRating ?? this.previousMonthRating,
      lastBonusMonth: lastBonusMonth ?? this.lastBonusMonth,
      paidoutTips: paidoutTips ?? this.paidoutTips,
      isGrantedAdminByMain: isGrantedAdminByMain ?? this.isGrantedAdminByMain,
      adminAccessLevel: adminAccessLevel ?? this.adminAccessLevel,
      grantedAdminAt: grantedAdminAt ?? this.grantedAdminAt,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      geohash: geohash ?? this.geohash,
      role: role,
      certifications: certifications ?? this.certifications,
      isOnline: isOnline ?? this.isOnline,
      residenceIdUrl: residenceIdUrl ?? this.residenceIdUrl,
      sponsorWorkPermitUrl: sponsorWorkPermitUrl ?? this.sponsorWorkPermitUrl,
      chamberOfCommerceApprovalUrl:
          chamberOfCommerceApprovalUrl ?? this.chamberOfCommerceApprovalUrl,
      isBlocked: isBlocked ?? this.isBlocked,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isDocsPendingReview: isDocsPendingReview ?? this.isDocsPendingReview,
      isRegistrationComplete:
          isRegistrationComplete ?? this.isRegistrationComplete,
    );
  }

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson({...data, 'uid': doc.id});
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'],
      email: json['email'],
      phone: json['phone'],

      lanCode: json['lanCode'],
      country: json['country'],
      liveLocation: json['liveLocation'] != null
          ? LiveLocation.fromJson(json['liveLocation'])
          : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      isAdmin: json['isAdmin'] ?? false,
      isVerified: json['isVerified'] ?? false,
      districtName: json['districtName'],
      role:
          json['role'] ??
          'technician', // Provide default value to prevent null error
      location: _parseLocation(json),
      jobRoles: json['jobRoles'] != null
          ? List<String>.from(json['jobRoles'])
          : <String>[],
      docUrl: json['docUrl'],
      profileUrl: json['profileUrl'],
      fcmToken: json['fcmToken'],
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      reviewCount: json['reviewCount'] != null
          ? (json['reviewCount'] as num).toInt()
          : null,
      payoutAccounts: json['payoutAccounts'] != null
          ? List<PayoutAccountModel>.from(
              json['payoutAccounts'].map((x) => PayoutAccountModel.fromJson(x)),
            )
          : <PayoutAccountModel>[],
      availableBalance: json['availableBalance']?.toString(),
      paidAmounts: json['paidAmounts']?.toString(),
      highestTier: json['highestTier'],
      totalMonthlyBonus: json['totalMonthlyBonus'] != null
          ? (json['totalMonthlyBonus'] as num).toDouble()
          : null,
      lastBonusDate: json['lastBonusDate'],
      paidoutTips: json['paidoutTips'] != null
          ? (json['paidoutTips'] as num).toDouble()
          : null,
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : <String>[],
      isOnline: json['isOnline'],
      currentMonthJobs: json['currentMonthJobs'] as int?,
      previousMonthJobs: json['previousMonthJobs'] as int?,
      tier: json['tier'],
      bonusAmount: json['bonusAmount'] != null
          ? (json['bonusAmount'] as num).toDouble()
          : null,
      previousMonthTier: json['previousMonthTier'],
      previousMonthRating: json['previousMonthRating'] != null
          ? (json['previousMonthRating'] as num).toDouble()
          : null,
      lastBonusMonth: json['lastBonusMonth'],
      isGrantedAdminByMain: json['isGrantedAdminByMain'] ?? false,
      adminAccessLevel: json['adminAccessLevel'] as int?,
      grantedAdminAt: json['grantedAdminAt'],
      lastKnownLocation: json['last_known_location'],
      geohash: json['geohash'],
      residenceIdUrl: json['residenceIdUrl'],
      sponsorWorkPermitUrl: json['sponsorWorkPermitUrl'],
      chamberOfCommerceApprovalUrl: json['chamberOfCommerceApprovalUrl'],
      isBlocked: json['isBlocked'],
      rejectionReason: json['rejectionReason'],
      isDocsPendingReview: json['isDocsPendingReview'],
      isRegistrationComplete: json['isRegistrationComplete'],
    );
  }

  Map<String, dynamic> toJson() {
    // Format phone number with country code when storing to Firebase
    final formattedPhone = phone != null
        ? CountryCodeDetector.convertToFirebaseFormat(
            phone!,
            countryCode: country,
          )
        : null;

    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': formattedPhone,
      'lanCode': lanCode,
      'country': country,
      'createdAt': createdAt,
      'location': location?.toJson(),
      'updatedAt': updatedAt,
      'isAdmin': isAdmin ?? false,
      'isVerified': isVerified,
      'districtName': districtName,
      'jobRoles': jobRoles,
      'docUrl': docUrl,
      'profileUrl': profileUrl,
      'role': role,
      'fcmToken': fcmToken,
      'rating': rating,
      'reviewCount': reviewCount,
      'payoutAccounts': payoutAccounts
          ?.map((account) => account.toJson())
          .toList(),
      'availableBalance': availableBalance,
      'paidAmounts': paidAmounts,
      'highestTier': highestTier,
      'totalMonthlyBonus': totalMonthlyBonus,
      'lastBonusDate': lastBonusDate,
      'isOnline': isOnline,
      'certifications': certifications,
      'paidoutTips': paidoutTips,
      'currentMonthJobs': currentMonthJobs,
      'previousMonthJobs': previousMonthJobs,
      'tier': tier,
      'bonusAmount': bonusAmount,
      'previousMonthTier': previousMonthTier,
      'previousMonthRating': previousMonthRating,
      'lastBonusMonth': lastBonusMonth,
      'isGrantedAdminByMain': isGrantedAdminByMain ?? false,
      'adminAccessLevel': adminAccessLevel,
      'grantedAdminAt': grantedAdminAt,
      'last_known_location': lastKnownLocation,
      'geohash': geohash,
      'residenceIdUrl': residenceIdUrl,
      'sponsorWorkPermitUrl': sponsorWorkPermitUrl,
      'chamberOfCommerceApprovalUrl': chamberOfCommerceApprovalUrl,
      'isBlocked': isBlocked,
      'rejectionReason': rejectionReason,
      'isDocsPendingReview': isDocsPendingReview,
      'isRegistrationComplete': isRegistrationComplete,
    };
  }

  Map<String, dynamic> toFirestore() {
    // Format phone number with country code when storing to Firebase
    final formattedPhone = phone != null
        ? CountryCodeDetector.convertToFirebaseFormat(
            phone!,
            countryCode: country,
          )
        : null;

    return {
      'name': name,
      'email': email,
      'phone': formattedPhone,
      'lanCode': lanCode,
      'country': country,
      'liveLocation': liveLocation?.toJson(),
      'location': location?.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isAdmin': isAdmin ?? false,
      'isVerified': isVerified,
      'districtName': districtName,
      'jobRoles': jobRoles,
      'docUrl': docUrl,
      'profileUrl': profileUrl,
      'fcmToken': fcmToken,
      'role': role,
      'rating': rating,
      'reviewCount': reviewCount,
      'payoutAccounts': payoutAccounts
          ?.map((account) => account.toJson())
          .toList(),
      'availableBalance': availableBalance,
      'paidAmounts': paidAmounts,
      'highestTier': highestTier,
      'totalMonthlyBonus': totalMonthlyBonus,
      'lastBonusDate': lastBonusDate,
      'certifications': certifications,
      'isOnline': isOnline,
      'paidoutTips': paidoutTips,
      'currentMonthJobs': currentMonthJobs,
      'previousMonthJobs': previousMonthJobs,
      'tier': tier,
      'bonusAmount': bonusAmount,
      'previousMonthTier': previousMonthTier,
      'previousMonthRating': previousMonthRating,
      'lastBonusMonth': lastBonusMonth,
      'isGrantedAdminByMain': isGrantedAdminByMain ?? false,
      'adminAccessLevel': adminAccessLevel,
      'grantedAdminAt': grantedAdminAt,
      'residenceIdUrl': residenceIdUrl,
      'sponsorWorkPermitUrl': sponsorWorkPermitUrl,
      'chamberOfCommerceApprovalUrl': chamberOfCommerceApprovalUrl,
      'isBlocked': isBlocked,
      'rejectionReason': rejectionReason,
      'isDocsPendingReview': isDocsPendingReview,
      'isRegistrationComplete': isRegistrationComplete,
    };
  }

  Map<String, dynamic> toEditJson({required UserModel previous}) {
    Map<String, dynamic> json = {'updatedAt': FieldValue.serverTimestamp()};

    if (name != previous.name && name != null) {
      json['name'] = name;
    }
    if (email != previous.email && email != null) {
      json['email'] = email;
    }
    if (phone != previous.phone && phone != null) {
      json['phone'] = phone;
    }
    if (lanCode != previous.lanCode && lanCode != null) {
      json['lanCode'] = lanCode;
    }
    if (country != previous.country && country != null) {
      json['country'] = country;
    }
    if (createdAt != previous.createdAt && createdAt != null) {
      json['createdAt'] = createdAt;
    }
    if (updatedAt != previous.updatedAt && updatedAt != null) {
      json['updatedAt'] = updatedAt;
    }
    if (isAdmin != previous.isAdmin && isAdmin != null) {
      json['isAdmin'] = isAdmin;
    }
    if (role != previous.role) {
      json['role'] = role;
    }
    if (isVerified != previous.isVerified && isVerified != null) {
      json['isVerified'] = isVerified;
    }
    if (districtName != previous.districtName && districtName != null) {
      json['districtName'] = districtName;
    }
    if (jobRoles != previous.jobRoles && jobRoles != null) {
      json['jobRoles'] = jobRoles;
    }
    if (docUrl != previous.docUrl && docUrl != null) {
      json['docUrl'] = docUrl;
    }
    if (profileUrl != previous.profileUrl && profileUrl != null) {
      json['profileUrl'] = profileUrl;
    }
    if (fcmToken != previous.fcmToken && fcmToken != null) {
      json['fcmToken'] = fcmToken;
    }
    if (rating != previous.rating && rating != null) {
      json['rating'] = rating;
    }
    if (reviewCount != previous.reviewCount && reviewCount != null) {
      json['reviewCount'] = reviewCount;
    }
    if (payoutAccounts != previous.payoutAccounts && payoutAccounts != null) {
      json['payoutAccounts'] = payoutAccounts;
    }
    if (availableBalance != previous.availableBalance &&
        availableBalance != null) {
      json['availableBalance'] = availableBalance;
    }
    if (paidAmounts != previous.paidAmounts && paidAmounts != null) {
      json['paidAmounts'] = paidAmounts;
    }
    if (highestTier != previous.highestTier && highestTier != null) {
      json['highestTier'] = highestTier;
    }
    if (totalMonthlyBonus != previous.totalMonthlyBonus &&
        totalMonthlyBonus != null) {
      json['totalMonthlyBonus'] = totalMonthlyBonus;
    }
    if (lastBonusDate != previous.lastBonusDate && lastBonusDate != null) {
      json['lastBonusDate'] = lastBonusDate;
    }

    if (certifications != previous.certifications && certifications != null) {
      json['certifications'] = certifications;
    }
    if (paidoutTips != previous.paidoutTips && paidoutTips != null) {
      json['paidoutTips'] = paidoutTips;
    }

    if (isOnline != previous.isOnline && isOnline != null) {
      json['isOnline'] = isOnline;
    }

    if (currentMonthJobs != previous.currentMonthJobs &&
        currentMonthJobs != null) {
      json['currentMonthJobs'] = currentMonthJobs;
    }

    if (previousMonthJobs != previous.previousMonthJobs &&
        previousMonthJobs != null) {
      json['previousMonthJobs'] = previousMonthJobs;
    }

    return json;
  }
}

// Keep your existing LiveLocation and PayoutAccountModel classes unchanged
class LiveLocation {
  double? latitude;
  double? longitude;
  LiveLocation({this.latitude, this.longitude});
  LiveLocation.fromJson(Map<String, dynamic> json) {
    latitude = json['latitude'];
    longitude = json['longitude'];
  }
  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  @override
  String toString() {
    return 'LiveLocation(latitude: $latitude, longitude: $longitude)';
  }
}

class PayoutAccountModel {
  String? id;
  String? accountHolderName;
  String? accountNumber;
  String? bankName;
  String? ifscCode;
  bool isPrimary;
  Timestamp? createdAt;
  Timestamp? updatedAt;

  PayoutAccountModel({
    this.id,
    this.accountHolderName,
    this.accountNumber,
    this.bankName,
    this.ifscCode,
    this.isPrimary = false,
    this.createdAt,
    this.updatedAt,
  });

  PayoutAccountModel copyWith({
    String? id,
    String? accountHolderName,
    String? accountNumber,
    String? bankName,
    String? ifscCode,
    String? accountType,
    bool? isPrimary,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return PayoutAccountModel(
      id: id ?? this.id,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      ifscCode: ifscCode ?? this.ifscCode,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PayoutAccountModel.fromJson(Map<String, dynamic> json) {
    return PayoutAccountModel(
      id: json['id'],
      accountHolderName: json['accountHolderName'],
      accountNumber: json['accountNumber'],
      bankName: json['bankName'],
      ifscCode: json['ifscCode'],
      isPrimary: json['isPrimary'] ?? false,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'ifscCode': ifscCode,
      'isPrimary': isPrimary,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PayoutAccountModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return PayoutAccountModel(
      id: snapshot.id,
      accountHolderName: data?['accountHolderName'],
      accountNumber: data?['accountNumber'],
      bankName: data?['bankName'],
      ifscCode: data?['ifscCode'],
      isPrimary: data?['isPrimary'] ?? false,
      createdAt: data?['createdAt'],
      updatedAt: data?['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'ifscCode': ifscCode,
      'isPrimary': isPrimary,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PayoutAccountModel.fromMap(Map<String, dynamic> map) {
    return PayoutAccountModel(
      id: map['id'],
      accountHolderName: map['accountHolderName'],
      accountNumber: map['accountNumber'],
      bankName: map['bankName'],
      ifscCode: map['ifscCode'],
      isPrimary: map['isPrimary'] ?? false,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}

/// Attempt to build a [LocationModel] from any legacy or current JSON shape.
/// Priority: new 'location' key → migrate from 'detailedLocation' key.
LocationModel? _parseLocation(Map<String, dynamic> json) {
  // New unified format
  if (json['location'] is Map<String, dynamic>) {
    final raw = json['location'] as Map<String, dynamic>;
    // Make sure it's the new format (has at least lat or fullAddress)
    if (raw.containsKey('lat') || raw.containsKey('fullAddress')) {
      return LocationModel.fromJson(raw);
    }
  }

  // Legacy: migrate from detailedLocation
  if (json['detailedLocation'] is Map<String, dynamic>) {
    final dl = json['detailedLocation'] as Map<String, dynamic>;
    final neighborhoodEn = dl['neighborhoodEn'] as String?;
    final cityEn = dl['cityEn'] as String?;
    final regionEn = dl['regionEn'] as String?;
    final lat = (dl['lat'] as num?)?.toDouble();
    final lon = (dl['lon'] as num?)?.toDouble();

    final parts = <String>[
      if (neighborhoodEn != null && neighborhoodEn.trim().isNotEmpty)
        neighborhoodEn.trim(),
      if (cityEn != null && cityEn.trim().isNotEmpty) cityEn.trim(),
      if (regionEn != null && regionEn.trim().isNotEmpty) regionEn.trim(),
    ];

    return LocationModel(
      lat: lat,
      lon: lon,
      city: cityEn,
      province: regionEn,
      street: neighborhoodEn,
      fullAddress: parts.isNotEmpty ? parts.join(', ') : null,
    );
  }

  return null;
}
