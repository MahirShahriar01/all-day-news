import 'package:flutter/material.dart';

/// Category icon names selectable in the admin panel
/// (keep in sync with admin/src/lib/icons.ts).
const Map<String, IconData> categoryIcons = {
  'newspaper': Icons.newspaper_rounded,
  'live_tv': Icons.live_tv_rounded,
  'sports_soccer': Icons.sports_soccer_rounded,
  'sports_cricket': Icons.sports_cricket_rounded,
  'sports': Icons.sports_rounded,
  'memory': Icons.memory_rounded,
  'science': Icons.science_rounded,
  'movie': Icons.movie_rounded,
  'music_note': Icons.music_note_rounded,
  'radio': Icons.radio_rounded,
  'podcasts': Icons.podcasts_rounded,
  'videogame_asset': Icons.videogame_asset_rounded,
  'school': Icons.school_rounded,
  'info': Icons.info_rounded,
  'public': Icons.public_rounded,
  'business': Icons.business_rounded,
  'attach_money': Icons.attach_money_rounded,
  'health_and_safety': Icons.health_and_safety_rounded,
  'cloud': Icons.cloud_rounded,
  'flight': Icons.flight_rounded,
  'restaurant': Icons.restaurant_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'gavel': Icons.gavel_rounded,
  'star': Icons.star_rounded,
  'apps': Icons.apps_rounded,
};

IconData iconFor(String name) => categoryIcons[name] ?? Icons.apps_rounded;
