import 'package:flutter/material.dart';
import '../models/accident_report.dart';
import '../utils/constants.dart';

class SeverityBadge extends StatelessWidget {
  final Severity severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (severity) {
      case Severity.minor:
        color = AppColors.minorGreen;
        text = 'MINOR';
        break;
      case Severity.moderate:
        color = AppColors.moderateYellow;
        text = 'MODERATE';
        break;
      case Severity.critical:
        color = AppColors.criticalRed;
        text = 'CRITICAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
