import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/emergency_location.dart';

class EmergencyService {
  final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

  Future<List<EmergencyLocation>> findNearbyHospitals(double lat, double lng) async {
    return _searchNearby(lat, lng, 'hospital');
  }

  Future<List<EmergencyLocation>> findNearbyPolice(double lat, double lng) async {
    return _searchNearby(lat, lng, 'police');
  }

  Future<List<EmergencyLocation>> _searchNearby(double lat, double lng, String type) async {
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=5000'
        '&type=$type'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;
      
      return results.take(10).map((place) {
        return EmergencyLocation(
          name: place['name'],
          lat: place['geometry']['location']['lat'],
          lng: place['geometry']['location']['lng'],
          address: place['vicinity'] ?? 'Address not available',
          type: type,
        );
      }).toList();
    } else {
      throw Exception('Failed to load nearby $type');
    }
  }
}
