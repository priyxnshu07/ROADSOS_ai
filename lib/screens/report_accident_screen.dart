import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../utils/constants.dart';
import '../models/accident_report.dart';
import '../services/gemini_service.dart';
import '../services/location_service.dart';
import '../services/history_service.dart';
import '../widgets/loading_animations.dart';
import '../widgets/sos_button.dart';
import 'severity_result_screen.dart';
import 'package:geolocator/geolocator.dart';

class ReportAccidentScreen extends StatefulWidget {
  const ReportAccidentScreen({super.key});

  @override
  State<ReportAccidentScreen> createState() => _ReportAccidentScreenState();
}

class _ReportAccidentScreenState extends State<ReportAccidentScreen> {
  XFile? _image;
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isOffline = false;
  bool _isLocationError = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  Position? _currentPosition;
  String _areaName = "Detecting high-precision location...";
  final LocationService _locationService = LocationService();
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (mounted) {
        setState(() {
          _isOffline = result.contains(ConnectivityResult.none);
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (mounted) {
      setState(() {
        _isOffline = connectivityResult.contains(ConnectivityResult.none);
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLocationError = false;
      _areaName = "Detecting high-precision location...";
    });

    try {
      final pos = await _locationService.getCurrentLocation();
      final name = await _locationService.getAreaName(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _areaName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationError = true;
          _areaName = "GPS Denied - Tap to Fix";
        });
      }
    }
  }

  Future<void> _handleLocationTap() async {
    if (!_isLocationError) return;

    final status = await Permission.location.request();
    if (status.isGranted) {
      _fetchCurrentLocation();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required to accurately report the accident.')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Camera access is disabled. Please enable it in settings.'),
              action: SnackBarAction(label: 'SETTINGS', onPressed: () => openAppSettings()),
            ),
          );
        }
        return;
      } else if (!status.isGranted && status != PermissionStatus.provisional) {
        return; // User cancelled
      }
    }

    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  void _submitReport() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('CRITICAL: Accident photo required for analysis.', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
      return;
    }

    // 1. Create a "Pending" universal report instantly
    final pendingReport = AccidentReport(
      image: _image,
      description: null,
      locationName: _areaName,
      latitude: _currentPosition?.latitude ?? 0.0,
      longitude: _currentPosition?.longitude ?? 0.0,
      severity: Severity.critical, // Assume critical for immediate safety
      aiSummary: "Universal trauma protocol active. Please follow immediate safety guidelines while AI analyzes the scene in the background.",
      recommendations: [
        "Ensure the scene is safe from oncoming traffic.",
        "Do not move injured persons unless in immediate danger (e.g., fire).",
        "Call emergency services immediately.",
        "Apply direct pressure to any severe bleeding."
      ],
      isPendingAI: true,
    );

    // 2. Start the AI Task if online
    Future<AccidentReport>? aiFuture;
    if (!_isOffline) {
      aiFuture = _runBackgroundAI(pendingReport);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warningOrange,
          content: Text('OFFLINE: Using universal guidelines.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          duration: Duration(seconds: 4),
        ),
      );
      // Save the offline (failed AI) report directly
      _historyService.saveReport(pendingReport.copyWith(isPendingAI: false));
    }

    // 3. ZERO WAIT: Navigate instantly
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SeverityResultScreen(
            report: pendingReport,
            aiAssessmentFuture: aiFuture,
          ),
        ),
      );
    }
  }

  Future<AccidentReport> _runBackgroundAI(AccidentReport baseReport) async {
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await _image!.readAsBytes();
      } else {
        final compressed = await FlutterImageCompress.compressWithFile(
          _image!.path,
          minWidth: 800,
          minHeight: 600,
          quality: 70,
        );
        imageBytes = compressed ?? await _image!.readAsBytes();
      }
      
      final geminiService = GeminiService();
      final result = await geminiService.analyzeSeverity(
        imageBytes: imageBytes,
        description: "Visual analysis requested.",
      );

      Severity severity;
      switch (result['severity'].toString().toUpperCase()) {
        case 'CRITICAL': severity = Severity.critical; break;
        case 'MODERATE': severity = Severity.moderate; break;
        case 'MINOR': default: severity = Severity.minor; break;
      }

      final List<String> guidance = result['guidance'] != null 
          ? List<String>.from(result['guidance'])
          : ["Ensure the area is safe.", "Call emergency services.", "Wait for professional help."];

      final finalReport = baseReport.copyWith(
        severity: severity,
        aiSummary: result['injuries_likely'] ?? result['summary'],
        recommendations: guidance,
        isPendingAI: false, // Processing complete
      );

      // Save the final report to history
      await _historyService.saveReport(finalReport);
      return finalReport;

    } catch (e) {
      debugPrint("Background AI Failed: $e");
      final failedReport = baseReport.copyWith(
        aiSummary: "AI Assessment failed. Please rely on emergency services and universal trauma guidelines.",
        isPendingAI: false,
      );
      await _historyService.saveReport(failedReport);
      return failedReport;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('REPORT ACCIDENT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.primaryRed,
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text("⚠️ Offline - Limited features. AI unavailable.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDesign.standardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMAGE PICKER
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _image == null ? AppColors.primaryRed.withValues(alpha: 0.3) : Colors.white10, 
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _image == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOptionBtn(Icons.camera_alt_rounded, "CAMERA", () => _pickImage(ImageSource.camera)),
                              Container(width: 2, height: 80, color: Colors.white10), // Divider
                              _buildOptionBtn(Icons.photo_library_rounded, "GALLERY", () => _pickImage(ImageSource.gallery)),
                            ],
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(_image!.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                  onPressed: () => setState(() => _image = null),
                                ),
                              )
                            ]
                          ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // LOCATION AUTO-FILL
                  GestureDetector(
                    onTap: _handleLocationTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: _isLocationError ? AppColors.primaryRed.withValues(alpha: 0.1) : AppColors.secondaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isLocationError ? AppColors.primaryRed : AppColors.secondaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isLocationError ? Icons.location_disabled : Icons.my_location, 
                            color: _isLocationError ? AppColors.primaryRed : AppColors.secondaryBlue, 
                            size: 24
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _areaName,
                              style: TextStyle(
                                color: _isLocationError ? AppColors.primaryRed : AppColors.secondaryBlue, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 14
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // SUBMIT BUTTON
                  SOSButton(
                    label: "INITIALIZE AI ASSESSMENT",
                    isPulsing: false,
                    onTap: _submitReport,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryRed),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
