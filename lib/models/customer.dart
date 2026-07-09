import 'package:aboglumbo_bbk_panel/models/address.dart';
import 'package:aboglumbo_bbk_panel/models/location.dart';
import 'package:aboglumbo_bbk_panel/helpers/country_code_detector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String uid;
  final String? role;
  final String? name;
  final String? email;
  final String? phone;
  final String? country;
  final String? fcmToken;
  final String? lanCode;
  final LocationModel? location;
  final List<AddressModel> addresses;
  final List<String> favourites;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final bool? isAdmin;
  final String? buildingNumber;
  final String? streetName;
  final String? districtName;
  final String? cityName;
  final String? postcode;
  final bool? isBlocked;
  final String? extensionNumber;
  final String? profileUrl;

  CustomerModel({
    required this.uid,
    required this.role,
    this.name,
    this.email,
    this.phone,
    this.fcmToken,
    this.lanCode,
    this.country,
    this.location,
    this.addresses = const [],
    this.favourites = const [],
    this.createdAt,
    this.updatedAt,
    this.isAdmin,
    this.buildingNumber,
    this.streetName,
    this.districtName,
    this.cityName,
    this.isBlocked,
    this.postcode,
    this.extensionNumber,
    this.profileUrl,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      uid: json['uid'] ?? '',
      name: json['name'],
      role: json['role'],
      email: json['email'],
      phone: json['phone'],
      fcmToken: json['fcmToken'],
      lanCode: json['lanCode'],
      country: json['country'],
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : (json['detailedLocation'] != null
                ? LocationModel(
                    lat: json['detailedLocation']['lat'] ?? 0.0,
                    lon: json['detailedLocation']['lon'] ?? 0.0,
                    fullAddress: json['detailedLocation']['neighborhoodEn'],
                    city: json['detailedLocation']['cityEn'],
                    province: json['detailedLocation']['regionEn'],
                  )
                : null),
      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      favourites:
          (json['favourites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      isAdmin: json['isAdmin'],
      buildingNumber: json['buildingNumber'],
      streetName: json['streetName'],
      districtName: json['districtName'],
      cityName: json['cityName'],
      postcode: json['postcode'],
      extensionNumber: json['extensionNumber'],
      isBlocked: json['isBlocked'],
      profileUrl: json['profileUrl'],
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
      'role': role,
      'phone': formattedPhone,
      'fcmToken': fcmToken,
      'lanCode': lanCode,
      'country': country,
      'location': location?.toJson(),
      'addresses': addresses.map((e) => e.toJson()).toList(),
      'favourites': favourites,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isAdmin': isAdmin,
      'buildingNumber': buildingNumber,
      'streetName': streetName,
      'districtName': districtName,
      'cityName': cityName,
      'postcode': postcode,
      'isBlocked': isBlocked,
      'extensionNumber': extensionNumber,
      'profileUrl': profileUrl,
    };
  }

  CustomerModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? fcmToken,
    String? lanCode,
    String? country,
    LocationModel? location,
    List<AddressModel>? addresses,
    List<String>? favourites,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isAdmin,
    String? buildingNumber,
    String? streetName,
    String? districtName,
    bool? isBlocked,
    String? cityName,
    String? postcode,
    String? extensionNumber,
    String? profileUrl,
  }) {
    return CustomerModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fcmToken: fcmToken ?? this.fcmToken,
      lanCode: lanCode ?? this.lanCode,
      country: country ?? this.country,
      location: location ?? this.location,
      addresses: addresses ?? this.addresses,
      favourites: favourites ?? this.favourites,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAdmin: isAdmin ?? this.isAdmin,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      streetName: streetName ?? this.streetName,
      districtName: districtName ?? this.districtName,
      cityName: cityName ?? this.cityName,
      postcode: postcode ?? this.postcode,
      isBlocked: isBlocked ?? this.isBlocked,
      extensionNumber: extensionNumber ?? this.extensionNumber,
      profileUrl: profileUrl ?? this.profileUrl,
    );
  }

  Map<String, dynamic> toEditJson({required CustomerModel previous}) {
    final Map<String, dynamic> json = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    void checkAndSet(String key, dynamic current, dynamic previousValue) {
      if (current != previousValue && current != null) {
        json[key] = current;
      }
    }

    checkAndSet('name', name, previous.name);
    checkAndSet('role', role, previous.role);
    checkAndSet('email', email, previous.email);

    // Format phone number with country code for Firebase
    final formattedPhone = phone != null
        ? CountryCodeDetector.convertToFirebaseFormat(
            phone!,
            countryCode: country,
          )
        : null;
    final formattedPreviousPhone = previous.phone != null
        ? CountryCodeDetector.convertToFirebaseFormat(
            previous.phone!,
            countryCode: previous.country,
          )
        : null;
    checkAndSet('phone', formattedPhone, formattedPreviousPhone);

    checkAndSet('fcmToken', fcmToken, previous.fcmToken);
    checkAndSet('lanCode', lanCode, previous.lanCode);
    checkAndSet('country', country, previous.country);
    checkAndSet('location', location?.toJson(), previous.location?.toJson());
    checkAndSet(
      'addresses',
      addresses.map((e) => e.toJson()).toList(),
      previous.addresses.map((e) => e.toJson()).toList(),
    );
    checkAndSet('favourites', favourites, previous.favourites);
    checkAndSet('createdAt', createdAt, previous.createdAt);
    checkAndSet('isAdmin', isAdmin, previous.isAdmin);
    checkAndSet('buildingNumber', buildingNumber, previous.buildingNumber);
    checkAndSet('streetName', streetName, previous.streetName);
    checkAndSet('districtName', districtName, previous.districtName);
    checkAndSet('cityName', cityName, previous.cityName);
    checkAndSet('postcode', postcode, previous.postcode);
    checkAndSet('isBlocked', isBlocked, previous.isBlocked);
    checkAndSet('extensionNumber', extensionNumber, previous.extensionNumber);
    checkAndSet('profileUrl', profileUrl, previous.profileUrl);

    return json;
  }
}
