import 'package:flutter/material.dart';
import '../utils/constants.dart';

class EmergencyCard extends StatelessWidget {
  final String title;
  final String distance;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  const EmergencyCard({
    super.key,
    required this.title,
    required this.distance,
    required this.onCall,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: AppTextStyles.subHeading),
        subtitle: Text(distance, style: AppTextStyles.body),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: onCall,
            ),
            IconButton(
              icon: const Icon(Icons.directions, color: Colors.blue),
              onPressed: onNavigate,
            ),
          ],
        ),
      ),
    );
  }
}
