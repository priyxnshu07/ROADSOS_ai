import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SOSButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPulsing;

  const SOSButton({
    super.key,
    this.label = "BROADCAST SOS ALERT",
    required this.onTap,
    this.isPulsing = true,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
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
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ScaleTransition(
          scale: widget.isPulsing ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(AppDesign.borderRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withValues(alpha: 0.4),
                  blurRadius: _isPressed ? 4 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: AppTextStyles.buttonText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
