import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../widgets/emergency_card.dart';
import '../services/emergency_service.dart';
import '../models/emergency_location.dart';

class EmergencyMapScreen extends StatefulWidget {
  const EmergencyMapScreen({super.key});

  @override
  State<EmergencyMapScreen> createState() => _EmergencyMapScreenState();
}

class _EmergencyMapScreenState extends State<EmergencyMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  List<EmergencyLocation> _nearbyServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyData();
  }

  Future<void> _loadEmergencyData() async {
    try {
      // 1. Get User Location
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      // 2. Fetch Nearby Services
      final emergencyService = EmergencyService();
      final hospitals = await emergencyService.findNearbyHospitals(position.latitude, position.longitude);
      final police = await emergencyService.findNearbyPolice(position.latitude, position.longitude);

      final allServices = [...hospitals, ...police];
      
      // 3. Create Markers
      final markers = allServices.map((loc) {
        return Marker(
          markerId: MarkerId(loc.name),
          position: LatLng(loc.lat, loc.lng),
          infoWindow: InfoWindow(title: loc.name, snippet: loc.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            loc.type == 'hospital' ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueBlue
          ),
        );
      }).toSet();

      // Add user marker
      markers.add(Marker(
        markerId: const MarkerId('user_loc'),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));

      if (mounted) {
        setState(() {
          _nearbyServices = allServices;
          _markers = markers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading emergency services: $e')),
        );
      }
    }
  }

  void _onCall(String name) async {
    // Placeholder for actual emergency numbers or place phone numbers
    final Uri url = Uri.parse('tel:102');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _onNavigate(double lat, double lng) async {
    final Uri url = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Fallback for iOS
      final appleUrl = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Services')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  onMapCreated: (controller) => _mapController = controller,
                ),
                
                // SOS ALERT Fixed Button
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
                        Text('SEND SOS ALERT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Sheet List
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
                        itemCount: _nearbyServices.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Center(
                              child: Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                          if (index == 1) {
                            return const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text('NEARBY SERVICES', style: AppTextStyles.subHeading),
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
