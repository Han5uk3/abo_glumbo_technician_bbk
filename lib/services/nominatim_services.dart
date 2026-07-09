import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NominatimService {
  static const _host = 'nominatim.openstreetmap.org';

  /// Search for a city/place and return all results.
  static Future<List<Map<String, dynamic>>> search({
    required String query,
    required Locale locale,
    String? countryCode,
  }) async {
    final params = <String, String>{
      'q': query,
      'format': 'jsonv2',
      'namedetails': '1',
    };

    if (countryCode != null && countryCode.isNotEmpty) {
      params['countrycodes'] = countryCode.toLowerCase();
    }

    final uri = Uri.https(_host, '/search', params);
    log('Nominatim request: $uri');

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'Abo Glumbo/1.0 (+https://aboglumbo.com)',
        'Accept': 'application/json',

        // Current app language
        'Accept-Language': 'ar',
      },
    );
    log('Nominatim response [${response.statusCode}]: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Nominatim error ${response.statusCode}: ${response.body}',
      );
    }

    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }
}
