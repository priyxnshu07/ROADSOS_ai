import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AnalysisLoading extends StatefulWidget {
  final VoidCallback? onCancel;
  const AnalysisLoading({super.key, this.onCancel});

  @override
  State<AnalysisLoading> createState() => _AnalysisLoadingState();
}

class _AnalysisLoadingState extends State<AnalysisLoading> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        _controllers[i].repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return FadeTransition(
                opacity: _animations[index],
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text(
            "Analyzing accident...",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              child: const Text("Tap to cancel", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 150, height: 16, color: Colors.white10),
          const SizedBox(height: 10),
          Container(width: 100, height: 12, color: Colors.white10),
          const SizedBox(height: 10),
          Container(width: double.infinity, height: 12, color: Colors.white10),
          const Spacer(),
          Row(
            children: [
              Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)))),
            ],
          ),
        ],
      ),
    );
  }
}

class DataLoadingIndicator extends StatefulWidget {
  final String message;
  const DataLoadingIndicator({super.key, required this.message});

  @override
  State<DataLoadingIndicator> createState() => _DataLoadingIndicatorState();
}

class _DataLoadingIndicatorState extends State<DataLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        FadeTransition(
          opacity: _animation,
          child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondaryBlue, shape: BoxShape.circle)),
        ),
      ],
    );
  }
}
