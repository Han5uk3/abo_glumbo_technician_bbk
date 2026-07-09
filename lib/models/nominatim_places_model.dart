class PlaceResult {
  final String displayName;
  final String? displayNameEn;
  final String? displayNameAr;
  final String? displayNameUr;
  final String addressType;
  final double latitude;
  final double longitude;

  final double south;
  final double north;
  final double west;
  final double east;

  PlaceResult({
    required this.displayName,
    this.displayNameEn,
    this.displayNameAr,
    this.displayNameUr,
    required this.addressType,
    required this.latitude,
    required this.longitude,
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final box = json['boundingbox'];
    final nameDetails = json['namedetails'] as Map<String, dynamic>?;

    return PlaceResult(
      displayName: json['display_name'] ?? '',
      displayNameEn: nameDetails?['name:en'] ?? nameDetails?['name'],
      displayNameAr: nameDetails?['name:ar'] ?? nameDetails?['name'],
      displayNameUr: nameDetails?['name:ur'] ?? nameDetails?['name'],
      addressType: json['addresstype'] ?? '',
      latitude: double.parse(json['lat']),
      longitude: double.parse(json['lon']),
      south: double.parse(box[0]),
      north: double.parse(box[1]),
      west: double.parse(box[2]),
      east: double.parse(box[3]),
    );
  }

  String getNameEn() => displayNameEn ?? displayName;
  String getNameAr() => displayNameAr ?? displayName;
  String getNameUr() => displayNameUr ?? displayName;

  String getLocalizedName(String languageCode) {
    if (languageCode == 'ar') return getNameAr();
    if (languageCode == 'ur') return getNameUr();
    return getNameEn();
  }
}
