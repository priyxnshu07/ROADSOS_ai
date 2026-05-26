import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color minorGreen = Color(0xFF43A047);
  static const Color moderateYellow = Color(0xFFFDD835);
  static const Color criticalRed = Color(0xFFD32F2F);
  static const Color backgroundGrey = Color(0xFFF5F5F5);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black54,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );
}
