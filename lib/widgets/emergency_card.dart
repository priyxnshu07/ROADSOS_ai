import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'action_buttons.dart';

class EmergencyCard extends StatelessWidget {
  final String title;
  final String address;
  final double? distance;
  final String? phoneNumber;
  final VoidCallback onCall;
  final VoidCallback onNavigate;

  const EmergencyCard({
    super.key,
    required this.title,
    required this.address,
    this.distance,
    this.phoneNumber,
    required this.onCall,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_hospital,
                color: (title.toLowerCase().contains('critical') || title.toLowerCase().contains('emergency'))
                    ? AppColors.primaryRed
                    : AppColors.secondaryBlue,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.black45, size: 14),
              const SizedBox(width: 4),
              Text(
                '${distance?.toStringAsFixed(1) ?? "?.?"} km away',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Address: $address',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (phoneNumber != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onCall,
              child: Row(
                children: [
                  const Icon(Icons.phone, color: AppColors.secondaryBlue, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Phone: $phoneNumber',
                    style: const TextStyle(
                      color: AppColors.secondaryBlue,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: "CALL",
                  icon: Icons.phone,
                  onTap: onCall,
                  style: ActionButtonStyle.call,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  label: "NAVIGATE",
                  icon: Icons.directions,
                  onTap: onNavigate,
                  style: ActionButtonStyle.navigate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
