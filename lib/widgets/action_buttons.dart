import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum ActionButtonStyle { call, navigate, secondary }

class ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ActionButtonStyle style;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.style = ActionButtonStyle.secondary,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    switch (widget.style) {
      case ActionButtonStyle.call:
        return AppColors.successGreen;
      case ActionButtonStyle.navigate:
        return AppColors.secondaryBlue;
      case ActionButtonStyle.secondary:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    return widget.style == ActionButtonStyle.secondary 
        ? AppColors.primaryRed 
        : Colors.white;
  }

  Border? get _border {
    if (widget.style == ActionButtonStyle.secondary) {
      return Border.all(color: AppColors.primaryRed, width: 2);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(AppDesign.borderRadiusMedium),
            border: _border,
            boxShadow: widget.style == ActionButtonStyle.secondary ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: _textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
