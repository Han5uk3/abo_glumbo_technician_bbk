/// A unified location model used for all technician/user profile locations.
/// Captures GPS coordinates plus reverse-geocoded address components from
/// the device's [Placemark] data.
class LocationModel {
  final double? lat;
  final double? lon;
  final String? fullAddress;
  final String? city;
  final String? province;
  final String? street;

  const LocationModel({
    this.lat,
    this.lon,
    this.fullAddress,
    this.city,
    this.province,
    this.street,
  });

  /// Build from GPS position + Placemark (from geocoding package).
  /// Pass [placemarks.first] as [placemark].
  factory LocationModel.fromGPS({
    required double lat,
    required double lon,
    dynamic placemark, // Placemark? — kept dynamic to avoid hard dep here
  }) {
    if (placemark == null) {
      return LocationModel(
        lat: lat,
        lon: lon,
        fullAddress: '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}',
      );
    }

    final city = _nonEmpty(placemark.locality);
    final province = _nonEmpty(placemark.administrativeArea);
    final street =
        _nonEmpty(placemark.thoroughfare) ??
        _nonEmpty(placemark.subThoroughfare);
    final neighborhood = _nonEmpty(placemark.subLocality);

    final addressParts = <String>[
      if (street != null) street,
      if (neighborhood != null) neighborhood,
      if (city != null) city,
      if (province != null) province,
    ];

    return LocationModel(
      lat: lat,
      lon: lon,
      city: city,
      province: province,
      street: street ?? neighborhood,
      fullAddress: addressParts.isNotEmpty ? addressParts.join(', ') : null,
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      fullAddress: json['fullAddress'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      street: json['street'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'fullAddress': fullAddress,
      'city': city,
      'province': province,
      'street': street,
    };
  }

  LocationModel copyWith({
    double? lat,
    double? lon,
    String? fullAddress,
    String? city,
    String? province,
    String? street,
  }) {
    return LocationModel(
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      fullAddress: fullAddress ?? this.fullAddress,
      city: city ?? this.city,
      province: province ?? this.province,
      street: street ?? this.street,
    );
  }

  /// Human-readable summary — most specific to least.
  String get displayName {
    if (fullAddress != null && fullAddress!.isNotEmpty) return fullAddress!;
    final parts = <String>[
      if (street != null && street!.isNotEmpty) street!,
      if (city != null && city!.isNotEmpty) city!,
      if (province != null && province!.isNotEmpty) province!,
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
  }

  @override
  String toString() =>
      'LocationModel(city: $city, province: $province, lat: $lat, lon: $lon)';

  static String? _nonEmpty(String? s) =>
      (s != null && s.trim().isNotEmpty) ? s.trim() : null;
}
