import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../models/accident_report.dart';
import '../services/gemini_service.dart';
import 'severity_result_screen.dart';
class ReportAccidentScreen extends StatefulWidget {
  const ReportAccidentScreen({Key? key}) : super(key: key);

  @override
  State<ReportAccidentScreen> createState() => _ReportAccidentScreenState();
}

class _ReportAccidentScreenState extends State<ReportAccidentScreen> {
  Position? _currentPosition;
  bool _isLoading = false;
  XFile? _image;
  Uint8List? _imageBytes;
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get location. Using default.')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _image = pickedFile;
        _imageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load image: $e')),
      );
    }
  }

  void _submitReport() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take or select a photo of the accident.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final geminiService = GeminiService();
      final result = await geminiService.analyzeSeverity(
        imageBytes: _imageBytes!,
        description: _descriptionController.text,
      );

      Severity severity;
      switch (result['severity'].toString().toUpperCase()) {
        case 'CRITICAL':
          severity = Severity.critical;
          break;
        case 'MODERATE':
          severity = Severity.moderate;
          break;
        default:
          severity = Severity.minor;
      }

      final guidance = await geminiService.getEmergencyGuidance(result['severity']);

      final report = AccidentReport(
        image: _image,
        imageBytes: _imageBytes,
        description: _descriptionController.text,
        locationName: _currentPosition != null
            ? "Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}"
            : "Location unavailable",
        latitude: _currentPosition?.latitude ?? 28.6139,
        longitude: _currentPosition?.longitude ?? 77.2090,
        severity: severity,
        aiSummary: result['injuries_likely'] ?? result['summary'],
        recommendations: guidance,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeverityResultScreen(report: report),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing accident: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Accident')),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Analyzing accident with AI...', style: AppTextStyles.subHeading),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Selection
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _imageBytes == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (!kIsWeb)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.camera_alt, size: 50, color: AppColors.primaryRed),
                                      onPressed: () => _pickImage(ImageSource.camera),
                                    ),
                                    const Text('Camera'),
                                  ],
                                ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.photo_library, size: 50, color: Colors.blue),
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                  ),
                                  Text(kIsWeb ? 'Choose Photo' : 'Gallery'),
                                ],
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 200,
                              gaplessPlayback: true,
                            ),
                          ),
                  ),
                  if (_imageBytes != null)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _image = null;
                        _imageBytes = null;
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Change Photo'),
                    ),
                  const SizedBox(height: 24),
                  // Description
                  const Text('Description (Optional)', style: AppTextStyles.subHeading),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Location Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location Detected:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('28.6139° N, 77.2090° E\nConnaught Place, New Delhi'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'SUBMIT REPORT',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
