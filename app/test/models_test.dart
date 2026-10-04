import 'dart:convert';
import 'dart:io';

import 'package:all_in_one_news/core/theme/color_utils.dart';
import 'package:all_in_one_news/core/utils/text_utils.dart';
import 'package:all_in_one_news/data/models/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('parses the bundled demo configuration', () {
      final json = jsonDecode(File('assets/config/fallback_config.json').readAsStringSync()) as Map<String, dynamic>;
      final config = AppConfig.fromJson(json);
      expect(config.categories, isNotEmpty);
      expect(config.sites, isNotEmpty);
      expect(config.featured, isNotEmpty);
      expect(config.featured.every((s) => s.isFeatured), isTrue);
      expect(config.settings.branding.appName, 'All in One News');
    });

    test('tolerates missing and unexpected fields', () {
      final config = AppConfig.fromJson({
        'settings': {
          'theme': {'corner_radius': 'oops', 'card_style': 'unknown'},
          'layout': {'grid_columns': 99},
        },
        'categories': [
          {'id': 1, 'name': 'News', 'extra': true},
        ],
        'sites': [
          {
            'id': 5,
            'title': 'A',
            'url': 'https://a.example',
            'category_id': 1,
            'open_mode': 'in_app',
            'tags': ['x', 3],
          },
          {'id': 6, 'title': 'No URL'},
          'garbage',
        ],
        'featured': [5, 999],
        'future_field': {'anything': 1},
      });
      expect(config.sites.map((s) => s.id), [5]);
      expect(config.featured.map((s) => s.id), [5]);
      expect(config.sites.single.openMode, OpenMode.inApp);
      expect(config.sites.single.tags, ['x']);
      expect(config.settings.theme.cardStyle, CardStyle.glass);
      expect(config.settings.theme.cornerRadius, 20);
      expect(config.settings.layout.gridColumns, 4);
    });

    test('search matches title, host and tags', () {
      final config = AppConfig.fromJson({
        'sites': [
          {
            'id': 1,
            'title': 'Cricket Live',
            'url': 'https://www.cric.example',
            'tags': ['sports'],
          },
          {'id': 2, 'title': 'Weather', 'url': 'https://weather.example'},
        ],
      });
      expect(config.search('cric').map((s) => s.id), [1]);
      expect(config.search('SPORTS').map((s) => s.id), [1]);
      expect(config.search('weather.example').map((s) => s.id), [2]);
      expect(config.search('  '), isEmpty);
    });
  });

  group('helpers', () {
    test('parseColor handles RGB and ARGB', () {
      expect(parseColor('#FF0000'), const Color(0xFFFF0000));
      expect(parseColor('#80112233'), const Color(0x80112233));
      expect(parseColor('red'), isNull);
      expect(parseColor(''), isNull);
    });

    test('initials', () {
      expect(initials('BBC News'), 'BN');
      expect(initials('reuters'), 'RE');
      expect(initials(''), '?');
    });

    test('isVideoUrl', () {
      expect(isVideoUrl('https://x/a.mp4'), isTrue);
      expect(isVideoUrl('https://x/a.MP4?x=1'), isTrue);
      expect(isVideoUrl('https://x/a.gif'), isFalse);
    });
  });
}
