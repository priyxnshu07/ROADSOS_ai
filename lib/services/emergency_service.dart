import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import '../models/emergency_location.dart';
import 'cache_service.dart';

class EmergencyService {
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final _cache = CacheService();

  Future<List<EmergencyLocation>> findNearbyHospitals(double lat, double lng, {int radius = 5000}) async {
    return _searchNearby(lat, lng, 'hospital', radius: radius);
  }

  Future<List<EmergencyLocation>> findNearbyPolice(double lat, double lng, {int radius = 5000}) async {
    return _searchNearby(lat, lng, 'police', radius: radius);
  }

  Future<List<EmergencyLocation>> _searchNearby(double lat, double lng, String type, {int radius = 5000}) async {
    // 1. CACHE CHECK: Round coords to 4 decimals (~11m precision)
    final cacheKey = _cache.getCoordsKey(lat, lng, type);
    final cachedData = await _cache.get(cacheKey);
    
    if (cachedData != null) {
      final List<dynamic> list = cachedData;
      return list.map((item) => EmergencyLocation(
        name: item['name'],
        lat: item['lat'],
        lng: item['lng'],
        address: item['address'],
        type: item['type'],
        phoneNumber: item['phoneNumber'],
        distance: item['distance'],
      )).toList();
    }

    if (kIsWeb) {
      return _searchNearbyWeb(lat, lng, type, radius);
    }

    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=$radius' 
        '&type=$type'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        final List<Future<EmergencyLocation>> locationFutures = results.map((place) async {
          final phone = await _getPlacePhone(place['place_id']);
          final double destinationLat = place['geometry']['location']['lat'];
          final double destinationLng = place['geometry']['location']['lng'];
          final double distanceInMeters = Geolocator.distanceBetween(lat, lng, destinationLat, destinationLng);
          
          return EmergencyLocation(
            name: place['name'],
            lat: destinationLat,
            lng: destinationLng,
            address: place['vicinity'] ?? 'Address not available',
            type: type,
            phoneNumber: phone,
            distance: distanceInMeters / 1000,
          );
        }).toList();

        final allResults = await Future.wait(locationFutures);
        allResults.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
        
        final topResults = allResults.take(5).toList();

        // SAVE TO CACHE
        await _cache.set(cacheKey, topResults.map((loc) => {
          'name': loc.name,
          'lat': loc.lat,
          'lng': loc.lng,
          'address': loc.address,
          'type': loc.type,
          'phoneNumber': loc.phoneNumber,
          'distance': loc.distance,
        }).toList());

        return topResults;
      }
      return [];
    } catch (e) {
      print('Emergency Service Speed Error: $e');
      return [];
    }
  }

  Future<List<EmergencyLocation>> _searchNearbyWeb(double lat, double lng, String type, int radius) async {
    final query = type == 'police' ? 'police' : 'hospital';
    final url = Uri.https('photon.komoot.io', '/api', {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'q': query,
      'limit': '15',
    });

    try {
      final response = await http.get(url, headers: {'User-Agent': 'RoadSOS-AI/1.0'}).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = (data['features'] as List?) ?? [];

        final results = features.map((feature) {
          final properties = (feature['properties'] as Map<String, dynamic>?) ?? {};
          final geometry = feature['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;
          final double destLat = (coordinates[1] as num).toDouble();
          final double destLng = (coordinates[0] as num).toDouble();
          final double dist = Geolocator.distanceBetween(lat, lng, destLat, destLng) / 1000;

          return EmergencyLocation(
            name: properties['name']?.toString() ?? 'Unknown $type',
            lat: destLat,
            lng: destLng,
            address: properties['street'] ?? properties['city'] ?? 'Nearby',
            type: type,
            phoneNumber: properties['phone'],
            distance: dist,
          );
        }).toList();

        results.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
        final topResults = results.take(5).toList();

        // SAVE TO CACHE
        final cacheKey = _cache.getCoordsKey(lat, lng, type);
        await _cache.set(cacheKey, topResults.map((loc) => {
          'name': loc.name,
          'lat': loc.lat,
          'lng': loc.lng,
          'address': loc.address,
          'type': loc.type,
          'phoneNumber': loc.phoneNumber,
          'distance': loc.distance,
        }).toList());

        return topResults;
      }
    } catch (_) {}
    return [];
  }

  Future<String?> _getPlacePhone(String placeId) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=formatted_phone_number'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result']?['formatted_phone_number'];
      }
    } catch (_) {}
    return null;
  }
}
