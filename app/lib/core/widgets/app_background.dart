import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'net_media.dart';

/// Futuristic backdrop: soft gradient glows plus the optional admin-defined
/// background image or GIF.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.imageUrl = '', this.imageOpacity = 0.35});

  final Widget child;
  final String imageUrl;
  final double imageOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.visuals.gradient.colors;
    final dark = theme.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: theme.scaffoldBackgroundColor),
        Positioned(
          top: -160,
          right: -120,
          child: _Glow(color: colors.first, opacity: dark ? 0.28 : 0.14),
        ),
        Positioned(
          bottom: -200,
          left: -160,
          child: _Glow(color: colors.last, opacity: dark ? 0.18 : 0.10),
        ),
        if (imageUrl.isNotEmpty)
          Positioned.fill(
            child: Opacity(
              opacity: imageOpacity,
              child: ExcludeSemantics(child: NetMedia(url: imageUrl)),
            ),
          ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 420,
      height: 420,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}
