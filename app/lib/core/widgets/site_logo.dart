import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../utils/text_utils.dart';
import 'net_media.dart';

/// A website's logo, or a coloured monogram when no logo is configured.
class SiteLogo extends StatelessWidget {
  const SiteLogo({super.key, required this.title, required this.logoUrl, this.accentColor = '', this.size = 52});

  final String title;
  final String logoUrl;
  final String accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visuals = context.visuals;
    final accent = parseColor(accentColor);
    final radius = (visuals.radius * 0.65).clamp(6.0, size / 2);
    final monogram = DecoratedBox(
      decoration: BoxDecoration(
        gradient: accent == null
            ? visuals.gradient
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, Color.lerp(accent, Colors.black, 0.35)!],
              ),
      ),
      child: Center(
        child: Text(
          initials(title),
          style: TextStyle(
            color: onColor(accent ?? Theme.of(context).colorScheme.primary),
            fontWeight: FontWeight.w800,
            fontSize: size * 0.36,
          ),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: logoUrl.isEmpty
              ? monogram
              : ColoredBox(
                  color: Colors.white,
                  child: NetMedia(url: logoUrl, fit: BoxFit.contain, fallback: monogram),
                ),
        ),
      ),
    );
  }
}
