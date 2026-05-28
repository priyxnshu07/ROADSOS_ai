import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_location.dart';
import '../services/emergency_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../widgets/emergency_card.dart';
import '../widgets/loading_animations.dart';

class EmergencyMapScreen extends StatefulWidget {
  const EmergencyMapScreen({super.key});

  @override
  State<EmergencyMapScreen> createState() => _EmergencyMapScreenState();
}

class _EmergencyMapScreenState extends State<EmergencyMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<Marker> _webMarkers = [];
  List<EmergencyLocation> _nearbyServices = [];
  bool _isLoading = true;
  String _loadingMessage = "Initializing GPS...";
  int _currentSearchRadius = 5000;

  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      setState(() => _loadingMessage = "ACQUIRING GPS LOCK...");
      final position = await _locationService.getCurrentLocation();
      setState(() => _currentPosition = position);
      await _loadServicesAt(position);
    } catch (e) {
      debugPrint("EmergencyMap Error: $e");
      if (!mounted) return;
      
      final fallback = Position(
        latitude: 28.6139,
        longitude: 77.2090,
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
      );
      
      await _loadServicesAt(fallback);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('GPS Signal Weak. Using estimated regional data.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadServicesAt(Position position, {int radius = 5000}) async {
    if (mounted) {
      setState(() {
        _currentSearchRadius = radius;
        _loadingMessage = "Scanning ${radius / 1000}km Radius...";
      });
    }
    
    final emergencyService = EmergencyService();
    
    try {
      final results = await Future.wait([
        emergencyService.findNearbyHospitals(position.latitude, position.longitude, radius: radius),
        emergencyService.findNearbyPolice(position.latitude, position.longitude, radius: radius),
      ]).timeout(const Duration(seconds: 8));

      final allServices = [...results[0], ...results[1]];

      if (allServices.isEmpty && radius < 20000) {
        final nextRadius = radius == 5000 ? 10000 : 20000;
        await _loadServicesAt(position, radius: nextRadius);
        return;
      }

      if (mounted) {
        setState(() {
          _nearbyServices = allServices;
          _webMarkers = [
            Marker(
              point: LatLng(position.latitude, position.longitude),
              width: 40, height: 40,
              child: const Icon(Icons.person_pin_circle, color: AppColors.primaryRed, size: 40),
            ),
            ...allServices.map((loc) {
              return Marker(
                point: LatLng(loc.lat, loc.lng),
                width: 36, height: 36,
                child: Icon(
                  loc.type == 'hospital' ? Icons.local_hospital : Icons.local_police,
                  color: loc.type == 'hospital' ? AppColors.secondaryBlue : Colors.indigoAccent,
                  size: 36,
                ),
              );
            }),
          ];
        });
      }
    } catch (_) {}
  }

  Future<void> _onCall(String? number) async {
    if (number == null) {
      final url = Uri.parse('tel:102');
      if (await canLaunchUrl(url)) await launchUrl(url);
      return;
    }
    final url = Uri.parse('tel:${number.replaceAll(' ', '')}');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _onNavigate(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('EMERGENCY SERVICES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                _currentPosition?.latitude ?? 28.6139,
                _currentPosition?.longitude ?? 77.2090,
              ),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.roadsos.ai',
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1.0, 0.0, 0.0, 0.0, 255.0,
                      0.0, -1.0, 0.0, 0.0, 255.0,
                      0.0, 0.0, -1.0, 0.0, 255.0,
                      0.0, 0.0, 0.0, 1.0, 0.0,
                    ]),
                    child: tileWidget,
                  );
                },
              ),
              MarkerLayer(markers: _webMarkers),
            ],
          ),
          
          // BOTTOM SHEET UI
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: const BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NEARBY ASSISTANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                        if (!_isLoading)
                          Text('${_currentSearchRadius / 1000}KM RANGE', style: const TextStyle(color: AppColors.primaryRed, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: 3,
                            itemBuilder: (context, index) => const SkeletonCard(),
                          )
                        : _nearbyServices.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('NO UNITS FOUND WITHIN ${_currentSearchRadius / 1000}KM', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 20),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() => _isLoading = true);
                                        _loadServicesAt(_currentPosition!, radius: 50000);
                                      },
                                      icon: const Icon(Icons.zoom_out_map, color: AppColors.primaryRed),
                                      label: const Text('SEARCH WIDER AREA (50KM)', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: _nearbyServices.length,
                                itemBuilder: (context, index) {
                                  final service = _nearbyServices[index];
                                  return EmergencyCard(
                                    title: service.name.toUpperCase(),
                                    address: service.address,
                                    distance: service.distance,
                                    phoneNumber: service.phoneNumber,
                                    onCall: () => _onCall(service.phoneNumber),
                                    onNavigate: () => _onNavigate(service.lat, service.lng),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          
          // TOP STATUS INDICATOR
          if (_isLoading)
            Positioned(
              top: 20,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(12)),
                child: Center(child: DataLoadingIndicator(message: _loadingMessage)),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.close, color: Colors.white),
      ),
    );
  }
}
