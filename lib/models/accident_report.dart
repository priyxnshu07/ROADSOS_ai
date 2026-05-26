import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

enum Severity { minor, moderate, critical }

class AccidentReport {
  final XFile? image;
  final Uint8List? imageBytes;
  final String? description;
  final String locationName;
  final double latitude;
  final double longitude;
  final Severity? severity;
  final String? aiSummary;
  final List<String>? recommendations;

  AccidentReport({
    this.image,
    this.imageBytes,
    this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.severity,
    this.aiSummary,
    this.recommendations,
  });

  AccidentReport copyWith({
    Severity? severity,
    String? aiSummary,
    List<String>? recommendations,
  }) {
    return AccidentReport(
      image: image,
      imageBytes: imageBytes,
      description: description,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      severity: severity ?? this.severity,
      aiSummary: aiSummary ?? this.aiSummary,
      recommendations: recommendations ?? this.recommendations,
    );
  }
}
