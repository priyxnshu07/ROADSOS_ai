import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GuidanceStep extends StatelessWidget {
  final String instruction;
  final bool isCompleted;

  const GuidanceStep({
    super.key,
    required this.instruction,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                instruction,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
