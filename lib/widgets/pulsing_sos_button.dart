import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PulsingSOSButton extends StatefulWidget {
  final VoidCallback onTap;
  const PulsingSOSButton({super.key, required this.onTap});

  @override
  State<PulsingSOSButton> createState() => _PulsingSOSButtonState();
}

class _PulsingSOSButtonState extends State<PulsingSOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.emergencyRed,
            boxShadow: [
              BoxShadow(
                color: AppColors.emergencyRed.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
            border: Border.all(color: Colors.white24, width: 8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.report_problem_rounded, size: 60, color: Colors.white),
              SizedBox(height: 10),
              Text(
                "REPORT\nACCIDENT",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
