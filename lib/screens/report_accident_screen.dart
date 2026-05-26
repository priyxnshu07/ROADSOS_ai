import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../utils/constants.dart';
import '../models/accident_report.dart';
import '../services/gemini_service.dart';
import 'severity_result_screen.dart';

class ReportAccidentScreen extends StatefulWidget {
  const ReportAccidentScreen({super.key});

  @override
  State<ReportAccidentScreen> createState() => _ReportAccidentScreenState();
}

class _ReportAccidentScreenState extends State<ReportAccidentScreen> {
  XFile? _image;
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
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
        const SnackBar(content: Text('Please take or select a photo of the accident.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final geminiService = GeminiService();
      final bytes = await _image!.readAsBytes();
      
      final result = await geminiService.analyzeSeverity(
        imageBytes: bytes,
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
        case 'MINOR':
        default:
          severity = Severity.minor;
          break;
      }

      // Fetch AI guidance based on severity
      final guidance = await geminiService.getEmergencyGuidance(result['severity']);

      final report = AccidentReport(
        image: _image,
        description: _descriptionController.text,
        locationName: "New Delhi, Connaught Place",
        latitude: 28.6139,
        longitude: 77.2090,
        severity: severity,
        aiSummary: result['injuries_likely'] ?? result['summary'],
        recommendations: guidance,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeverityResultScreen(report: report),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
                    child: _image == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
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
                                  const Text('Gallery'),
                                ],
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(_image!.path, fit: BoxFit.cover),
                          ),
                  ),
                  if (_image != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _image = null),
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
