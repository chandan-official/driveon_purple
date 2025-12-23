import 'package:flutter/material.dart';

class FadeSlideTransition extends StatelessWidget {
  final Widget child;
  final double delay; // Delay in seconds (e.g., 0.1, 0.2)
  final Offset beginOffset;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delay = 0,
    this.beginOffset = const Offset(0, 0.3), // Slides up from bottom by default
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Simple manual delay logic for tween builder
        double delayedValue =
            (value - delay * 1.5).clamp(0.0, 1.0) / (1 - delay * 1.5);
        if (delay * 1.5 >= 1.0) delayedValue = value; // Fallback

        return Opacity(
          opacity: delayedValue.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              beginOffset.dx * (1 - delayedValue),
              beginOffset.dy * 50 * (1 - delayedValue),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
