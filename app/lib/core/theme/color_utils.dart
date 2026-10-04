import 'package:flutter/material.dart';

/// Parses `#RRGGBB` / `#AARRGGBB` colours sent by the API.
Color? parseColor(String? value) {
  if (value == null) return null;
  var hex = value.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(parsed);
}

Color colorOr(String? value, Color fallback) => parseColor(value) ?? fallback;

/// Black or white, whichever reads better on [background].
Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? Colors.white : const Color(0xFF111111);
