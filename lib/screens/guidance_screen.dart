import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/accident_report.dart';
import '../widgets/severity_badge.dart';

class GuidanceScreen extends StatefulWidget {
  final AccidentReport report;
  const GuidanceScreen({super.key, required this.report});

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();
    final steps = widget.report.recommendations ?? [];
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (steps.length * 100)),
    );

    _animations = List.generate(steps.length, (index) {
      final start = index * 0.1;
      final end = start + 0.6;
      return Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.report.recommendations ?? [];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('EMERGENCY GUIDANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesign.standardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SeverityBadge(severity: widget.report.severity ?? Severity.minor),
            const SizedBox(height: 32),
            const Text(
              "IMMEDIATE ACTIONS:",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.1, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (index) {
              return SlideTransition(
                position: _animations[index],
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _controller, curve: Interval(index * 0.1, 1.0)),
                  child: _buildStepCard(index + 1, steps[index]),
                ),
              );
            }),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text("I HAVE COMPLETED THESE STEPS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(int number, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
            child: Center(child: Text("$number", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}
