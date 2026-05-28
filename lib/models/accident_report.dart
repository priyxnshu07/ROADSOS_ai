import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';

enum Severity { minor, moderate, critical }

class AccidentReport {
  final XFile? image;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? description;
  final String locationName;
  final double latitude;
  final double longitude;
  final Severity? severity;
  final String? aiSummary;
  final List<String>? recommendations;
  final DateTime timestamp;
  final bool isPendingAI; // Added for Zero-Wait UI

  AccidentReport({
    this.image,
    this.imagePath,
    this.imageBytes,
    this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.severity,
    this.aiSummary,
    this.recommendations,
    DateTime? timestamp,
    this.isPendingAI = false,
  }) : timestamp = timestamp ?? DateTime.now();

  AccidentReport copyWith({
    Severity? severity,
    String? aiSummary,
    List<String>? recommendations,
    bool? isPendingAI,
  }) {
    return AccidentReport(
      image: image,
      imagePath: imagePath ?? image?.path,
      imageBytes: imageBytes,
      description: description,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      severity: severity ?? this.severity,
      aiSummary: aiSummary ?? this.aiSummary,
      recommendations: recommendations ?? this.recommendations,
      timestamp: timestamp,
      isPendingAI: isPendingAI ?? this.isPendingAI,
    );
  }

  Map<String, dynamic> toJson() => {
    'imagePath': image?.path ?? imagePath,
    'description': description,
    'locationName': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'severity': severity?.name,
    'aiSummary': aiSummary,
    'recommendations': recommendations,
    'timestamp': timestamp.toIso8601String(),
    'isPendingAI': isPendingAI,
  };

  factory AccidentReport.fromJson(Map<String, dynamic> json) {
    return AccidentReport(
      imagePath: json['imagePath'],
      description: json['description'],
      locationName: json['locationName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      severity: json['severity'] != null 
          ? Severity.values.firstWhere((e) => e.name == json['severity'], orElse: () => Severity.minor)
          : null,
      aiSummary: json['aiSummary'],
      recommendations: json['recommendations'] != null ? List<String>.from(json['recommendations']) : null,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      isPendingAI: json['isPendingAI'] ?? false,
    );
  }
}
