import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    // ADDED: Try for high accuracy with a strict timeout, then fall back to last known or lower accuracy
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      // Fallback: Try lower accuracy/cached location
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
    }
  }

  Future<String> getAreaName(double lat, double lon) async {
    // Use OpenStreetMap Nominatim reverse geocoding
    final url = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'json',
      'lat': lat.toString(),
      'lon': lon.toString(),
      'zoom': '18',
      'addressdetails': '1',
    });

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'RoadSOS-AI/1.0',
      }).timeout(const Duration(seconds: 4)); // ADDED: Strict timeout for network call
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
      }
    } catch (_) {
      // Fallback to coordinates immediately on timeout or error
    }
    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }
}
