import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/color_utils.dart';

/// Small label such as "LIVE" or "NEW". "LIVE" gets a pulsing dot.
class BadgeChip extends StatelessWidget {
  const BadgeChip(this.text, {super.key, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = context.visuals.accent;
    final isLive = text.toUpperCase() == 'LIVE';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[_LiveDot(color: onColor(accent)), const SizedBox(width: 4)],
          Text(
            text,
            style: TextStyle(
              color: onColor(accent),
              fontSize: compact ? 9 : 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
            textScaler: TextScaler.noScaling,
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});
  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.animate) {
      _c.repeat(reverse: true);
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
    child: Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}
