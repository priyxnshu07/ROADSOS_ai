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
import '../utils/constants.dart';
import '../widgets/emergency_card.dart';

class EmergencyMapScreen extends StatefulWidget {
  const EmergencyMapScreen({super.key});

  @override
  State<EmergencyMapScreen> createState() => _EmergencyMapScreenState();
}

class _EmergencyMapScreenState extends State<EmergencyMapScreen> {
  gmaps.GoogleMapController? _mapController;
  final MapController _webMapController = MapController();
  Position? _currentPosition;
  Set<gmaps.Marker> _googleMarkers = {};
  List<Marker> _webMarkers = [];
  List<EmergencyLocation> _nearbyServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services disabled');
      }

      final position = await Geolocator.getCurrentPosition();
      print('🔍 Current position: ${position.latitude}, ${position.longitude}');
      await _loadServicesAt(position);
    } catch (e) {
      if (!mounted) return;
      // Handle the error appropriately, e.g., show a snackbar or log.
    }
  }

  Future<void> _loadServicesAt(Position position) async {
    final emergencyService = EmergencyService();
    final hospitals =
        await emergencyService.findNearbyHospitals(position.latitude, position.longitude);
    final police =
        await emergencyService.findNearbyPolice(position.latitude, position.longitude);
    final allServices = [...hospitals, ...police];

    if (kIsWeb) {
      final markers = <Marker>[
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 40,
          height: 40,
          child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
        ),
        ...allServices.map((loc) {
          return Marker(
            point: LatLng(loc.lat, loc.lng),
            width: 36,
            height: 36,
            child: Icon(
              loc.type == 'hospital' ? Icons.local_hospital : Icons.local_police,
              color: loc.type == 'hospital' ? Colors.blue : Colors.indigo,
              size: 36,
            ),
          );
        }),
      ];

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _nearbyServices = allServices;
            _webMarkers = markers;
            _isLoading = false;
          });
          // Move map after first frame to ensure FlutterMap widget exists
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _webMapController.move(
              LatLng(position.latitude, position.longitude),
              14,
            );
          });
        }
      return;
    }

    final markers = allServices.map((loc) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(loc.name),
        position: gmaps.LatLng(loc.lat, loc.lng),
        infoWindow: gmaps.InfoWindow(title: loc.name, snippet: loc.address),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          loc.type == 'hospital' ? gmaps.BitmapDescriptor.hueAzure : gmaps.BitmapDescriptor.hueBlue,
        ),
      );
    }).toSet();

    markers.add(
      gmaps.Marker(
        markerId: const gmaps.MarkerId('user_loc'),
        position: gmaps.LatLng(position.latitude, position.longitude),
        infoWindow: const gmaps.InfoWindow(title: 'Your Location'),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
      ),
    );

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _nearbyServices = allServices;
        _googleMarkers = markers;
        _isLoading = false;
      });
    }
  }

  Future<void> _onCall(String name) async {
    final Uri url = Uri.parse('tel:102');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _onNavigate(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (kIsWeb) {
      await launchUrl(googleMapsUrl, webOnlyWindowName: '_blank');
      return;
    }

    final Uri url = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final appleUrl = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl);
      }
    }
  }

  Widget _buildMapLayer() {
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    if (kIsWeb) {
      return FlutterMap(
        mapController: _webMapController,
        options: MapOptions(
          initialCenter: LatLng(lat, lng),
          initialZoom: 14,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.roadsos.roadsos_ai',
          ),
          MarkerLayer(markers: _webMarkers),
        ],
      );
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(lat, lng),
        zoom: 14,
      ),
      markers: _googleMarkers,
      myLocationEnabled: true,
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Services')),
      body: _isLoading || _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildMapLayer(),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: () => _onCall('SOS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sos, color: Colors.white, size: 30),
                        SizedBox(width: 8),
                        Text(
                          'SEND SOS ALERT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.1,
                  maxChildSize: 0.6,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _nearbyServices.isEmpty
                            ? 3
                            : _nearbyServices.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Center(
                              child: Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                          if (index == 1) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text('NEARBY SERVICES', style: AppTextStyles.subHeading),
                            );
                          }
                          if (_nearbyServices.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No nearby services found. Try again in a moment.',
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          final service = _nearbyServices[index - 2];
                          return EmergencyCard(
                            title: service.name,
                            distance: service.address,
                            onCall: () => _onCall(service.name),
                            onNavigate: () => _onNavigate(service.lat, service.lng),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
