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
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
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
    final response = await http.get(url, headers: {'User-Agent': 'RoadSOS-AI/1.0'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['display_name'] ?? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
    }
    // Fallback to coordinates if request fails
    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }
}
