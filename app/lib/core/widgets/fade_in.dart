import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Staggered fade + slide entrance. Disabled when animations are off.
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (!context.animate) return child;
    final delay = (index.clamp(0, 12) * 40);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay),
      curve: Interval(delay / (380 + delay), 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
