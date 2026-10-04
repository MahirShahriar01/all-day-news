import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_config.dart';
import 'color_utils.dart';

/// Extra design tokens controlled from the admin panel, available through
/// `Theme.of(context).extension<AppVisuals>()!` or `context.visuals`.
@immutable
class AppVisuals extends ThemeExtension<AppVisuals> {
  const AppVisuals({
    required this.gradient,
    required this.accent,
    required this.radius,
    required this.cardStyle,
    required this.animations,
    required this.glassFill,
    required this.glassBorder,
  });

  final LinearGradient gradient;
  final Color accent;
  final double radius;
  final CardStyle cardStyle;
  final bool animations;
  final Color glassFill;
  final Color glassBorder;

  @override
  AppVisuals copyWith({
    LinearGradient? gradient,
    Color? accent,
    double? radius,
    CardStyle? cardStyle,
    bool? animations,
  }) => AppVisuals(
    gradient: gradient ?? this.gradient,
    accent: accent ?? this.accent,
    radius: radius ?? this.radius,
    cardStyle: cardStyle ?? this.cardStyle,
    animations: animations ?? this.animations,
    glassFill: glassFill,
    glassBorder: glassBorder,
  );

  @override
  AppVisuals lerp(ThemeExtension<AppVisuals>? other, double t) {
    if (other is! AppVisuals) return this;
    return AppVisuals(
      gradient: LinearGradient.lerp(gradient, other.gradient, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      radius: radius + (other.radius - radius) * t,
      cardStyle: t < 0.5 ? cardStyle : other.cardStyle,
      animations: t < 0.5 ? animations : other.animations,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

extension AppVisualsContext on BuildContext {
  AppVisuals get visuals => Theme.of(this).extension<AppVisuals>()!;

  /// False when the admin disabled animations or the user enabled
  /// "remove animations" in the phone's accessibility settings.
  bool get animate => visuals.animations && !MediaQuery.disableAnimationsOf(this);
}

class AppTheme {
  const AppTheme._();

  static ThemeMode themeMode(ThemeSettings s) => switch (s.mode) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  static ThemeData build(ThemeSettings s, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final primary = colorOr(s.primaryColor, const Color(0xFF7C4DFF));
    final secondary = colorOr(s.secondaryColor, const Color(0xFF00E5FF));
    final accent = colorOr(s.accentColor, const Color(0xFFFF4081));
    // In light mode the admin's dark background/surface/text colours are not
    // used; a matching light palette is derived from the primary colour.
    final background = dark ? colorOr(s.backgroundColor, const Color(0xFF0A0E1A)) : const Color(0xFFF4F6FC);
    final surface = dark ? colorOr(s.surfaceColor, const Color(0xFF141A2E)) : Colors.white;
    final text = dark ? colorOr(s.textColor, const Color(0xFFF5F7FF)) : const Color(0xFF141A33);
    final radius = s.cornerRadius.clamp(0, 40).toDouble();

    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
      primary: primary,
      onPrimary: onColor(primary),
      secondary: secondary,
      onSecondary: onColor(secondary),
      tertiary: accent,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: Color.alphaBlend(text.withValues(alpha: 0.06), surface),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    final textTheme = base.textTheme
        .apply(bodyColor: text, displayColor: text)
        .copyWith(
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: text,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: text),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: text),
        );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: text,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withValues(alpha: dark ? 0.85 : 0.95),
        indicatorColor: primary.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: text.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: StadiumBorder(side: BorderSide(color: text.withValues(alpha: 0.08))),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [
        AppVisuals(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorOr(s.gradientStart, primary), colorOr(s.gradientEnd, secondary)],
          ),
          accent: accent,
          radius: radius,
          cardStyle: s.cardStyle,
          animations: s.enableAnimations,
          glassFill: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.75),
          glassBorder: dark ? Colors.white.withValues(alpha: 0.09) : Colors.black.withValues(alpha: 0.06),
        ),
      ],
    );
  }
}
