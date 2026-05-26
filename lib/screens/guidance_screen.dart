import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/accident_report.dart';
import '../widgets/guidance_step.dart';

class GuidanceScreen extends StatelessWidget {
  final Severity severity;
  final List<String>? manualRecommendations;

  const GuidanceScreen({super.key, required this.severity, this.manualRecommendations});

  List<String> _getGuidanceSteps() {
    if (manualRecommendations != null && manualRecommendations!.isNotEmpty) {
      return manualRecommendations!;
    }
    switch (severity) {
      case Severity.critical:
        return [
          "DO NOT move the injured person unless there is an immediate danger (like fire).",
          "Check if they are breathing and have a pulse.",
          "Call an ambulance immediately: 102 (Ambulance) / 108 (Emergency).",
          "If they are bleeding, apply firm, direct pressure with a clean cloth.",
          "Keep them warm and comfortable until help arrives.",
        ];
      case Severity.moderate:
        return [
          "Move to a safe area away from traffic.",
          "Turn on hazard lights and place a warning triangle if available.",
          "Check all passengers for hidden injuries or shock.",
          "Exchange information with other parties involved.",
          "Contact your insurance company and report the accident.",
        ];
      case Severity.minor:
        return [
          "Move vehicles out of the way of traffic if possible.",
          "Take photos of the damage for insurance purposes.",
          "Exchange contact and insurance information.",
          "Check for any minor fluid leaks from the vehicle.",
          "Visit a mechanic soon to ensure there is no hidden damage.",
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getGuidanceSteps();

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(title: const Text('First Aid & Guidance')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${severity.name.toUpperCase()} ACCIDENT GUIDANCE',
              style: AppTextStyles.heading.copyWith(
                color: severity == Severity.critical ? AppColors.criticalRed : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return GuidanceStep(instruction: steps[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('BACK TO RESULTS', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
