import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/accident_report.dart';

class SeverityBadge extends StatefulWidget {
  final Severity severity;
  const SeverityBadge({super.key, required this.severity});

  @override
  State<SeverityBadge> createState() => _SeverityBadgeState();
}

class _SeverityBadgeState extends State<SeverityBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.severity == Severity.critical) {
      _controller.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.severity) {
      case Severity.critical: return AppColors.criticalRed;
      case Severity.moderate: return AppColors.warningOrange;
      case Severity.minor: return AppColors.successGreen;
    }
  }

  String get _label {
    switch (widget.severity) {
      case Severity.critical: return "CRITICAL";
      case Severity.moderate: return "MODERATE";
      case Severity.minor: return "MINOR";
    }
  }

  String get _subtitle {
    switch (widget.severity) {
      case Severity.critical: return "CALL AMBULANCE IMMEDIATELY";
      case Severity.moderate: return "Medical attention recommended";
      case Severity.minor: return "Low risk, first aid sufficient";
    }
  }

  IconData get _icon {
    switch (widget.severity) {
      case Severity.critical: return Icons.report_gmailerrorred_rounded;
      case Severity.moderate: return Icons.error_outline_rounded;
      case Severity.minor: return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.severity == Severity.critical ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: _color, size: 48),
            const SizedBox(height: 12),
            Text(
              _label,
              style: TextStyle(
                color: _color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _color.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
