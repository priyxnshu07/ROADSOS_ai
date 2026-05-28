import 'package:flutter/material.dart';

class AppColors {
  // PART 1: COLOR SYSTEM
  static const Color primaryRed = Color(0xFFE53935);    // Emergency Red
  static const Color secondaryBlue = Color(0xFF1E88E5); // Professional Blue
  static const Color successGreen = Color(0xFF43A047);  // Safe Green
  static const Color warningOrange = Color(0xFFFFA726); // Caution Yellow
  static const Color criticalRed = Color(0xFFC62828);   // Dark Red
  
  static const Color neutralGray = Color(0xFFF5F5F5);   // Light Gray
  static const Color darkBackground = Color(0xFF121212); 
  static const Color surfaceCard = Color(0xFF1E1E1E);    
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;

  // Aliases for easier use
  static const Color emergencyRed = primaryRed;
  static const Color safetyGreen = successGreen;
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryRed,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryRed,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelText = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.1,
  );
}

class AppDesign {
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusMedium = 12.0;
  static const double standardPadding = 24.0;
}
