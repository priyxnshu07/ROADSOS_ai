import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';
import '../widgets/action_buttons.dart';
import 'report_accident_screen.dart';
import 'contacts_screen.dart';
import 'history_screen.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentLocationName = "Detecting Location...";
  final LocationService _locationService = LocationService();
  bool _isLocationError = false;

  @override
  void initState() {
    super.initState();
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isLocationError = false;
      _currentLocationName = "Detecting Location...";
    });
    
    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) setState(() => _currentLocationName = "Resolving Address...");
      
      final name = await _locationService.getAreaName(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentLocationName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationError = true;
          _currentLocationName = "GPS Denied - Tap to Fix";
        });
      }
    }
  }

  Future<void> _handleLocationTap() async {
    if (!_isLocationError) return;

    final status = await Permission.location.request();
    if (status.isGranted) {
      _updateLocation();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required for emergency services.')),
      );
    }
  }

  Future<void> _dialNumber(String number) async {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildHotline(String number, String label, Color color) {
    return GestureDetector(
      onTap: () => _dialNumber(number),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Icons.phone, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(number, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primaryRed),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDesign.standardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // APP HEADING
              const Text(
                "RoadSOS AI",
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: 12),
              // LOCATION BADGE
              GestureDetector(
                onTap: _handleLocationTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isLocationError ? AppColors.primaryRed.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: _isLocationError ? Border.all(color: AppColors.primaryRed) : null,
                    boxShadow: _isLocationError ? [] : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLocationError ? Icons.location_disabled : Icons.location_on, 
                        color: AppColors.primaryRed, 
                        size: 16
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _currentLocationName,
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: _isLocationError ? AppColors.primaryRed : Colors.black54
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // MAIN SOS BUTTON
              SOSButton(
                label: "REPORT ACCIDENT",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportAccidentScreen()),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // EMERGENCY CONTACTS BUTTON
              ActionButton(
                label: "Emergency Contacts",
                icon: Icons.contact_phone_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactsScreen()),
                ),
                style: ActionButtonStyle.secondary,
              ),
              
              const SizedBox(height: 40),
              
              // QUICK DIAL HOTLINES
              const Text("QUICK DIAL HOTLINES", style: TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHotline("102", "AMBULANCE", AppColors.primaryRed),
                  _buildHotline("100", "POLICE", AppColors.secondaryBlue),
                  _buildHotline("101", "FIRE", AppColors.warningOrange),
                ],
              ),
              
              const Spacer(),
              
              // FOOTER
              const Text(
                "Emergency services will be notified immediately upon report.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black38, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
