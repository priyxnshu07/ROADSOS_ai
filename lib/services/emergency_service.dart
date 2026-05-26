import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/emergency_location.dart';

/// Finds nearby hospitals and police using Photon (OpenStreetMap).
/// Google Places REST API cannot be called from Flutter web (CORS).
class EmergencyService {
  Future<List<EmergencyLocation>> findNearbyHospitals(double lat, double lng) async {
    return _searchNearby(lat, lng, 'hospital');
  }

  Future<List<EmergencyLocation>> findNearbyPolice(double lat, double lng) async {
    return _searchNearby(lat, lng, 'police');
  }

  Future<List<EmergencyLocation>> _searchNearby(double lat, double lng, String type) async {
    final query = type == 'police' ? 'police' : 'hospital';
    final url = Uri.https('photon.komoot.io', '/api', {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'q': query,
      'limit': '10',
    });

    final response = await http.get(
      url,
      headers: const {'User-Agent': 'RoadSOS-AI/1.0'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load nearby $type (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = (data['features'] as List?) ?? [];

    if (features.isEmpty) {
      return [];
    }

    return features.map((feature) {
      final properties = (feature['properties'] as Map<String, dynamic>?) ?? {};
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;

      final name = properties['name']?.toString() ??
          properties['street']?.toString() ??
          'Unknown $type';

      final addressParts = [
        properties['housenumber'],
        properties['street'],
        properties['city'],
        properties['state'],
      ].whereType<String>().where((part) => part.isNotEmpty).toList();

      return EmergencyLocation(
        name: name,
        lat: (coordinates[1] as num).toDouble(),
        lng: (coordinates[0] as num).toDouble(),
        address: addressParts.isEmpty ? 'Nearby' : addressParts.join(', '),
        type: type,
      );
    }).toList();
  }
}
