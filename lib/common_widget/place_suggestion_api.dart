import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<String>> getPlaceSuggestions(String input) async {
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final url =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=country:sa';
  final response = await http.get(Uri.parse(url));
  final data = jsonDecode(response.body);
  if (data['status'] == 'OK') {
    return List<String>.from(
        data['predictions'].map((place) => place['description']));
  } else {
    return [];
  }
}
