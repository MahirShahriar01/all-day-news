// Models for the configuration document served by `GET /api/v1/config`.
//
// Parsing is deliberately tolerant: unknown keys are ignored and missing keys
// fall back to defaults, so newer servers keep working with older app
// versions and vice versa.

String _str(Object? v, [String fallback = '']) => v is String ? v : fallback;
bool _bool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;
int _int(Object? v, [int fallback = 0]) => v is int ? v : (v is num ? v.toInt() : fallback);
double _double(Object? v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;
Map<String, dynamic> _map(Object? v) => v is Map<String, dynamic> ? v : const {};
List<Object?> _list(Object? v) => v is List ? v : const [];

enum OpenMode {
  appDefault,
  inApp,
  customTab,
  external;

  static OpenMode parse(String value) => switch (value) {
    'in_app' => OpenMode.inApp,
    'custom_tab' => OpenMode.customTab,
    'external' => OpenMode.external,
    _ => OpenMode.appDefault,
  };
}

class BrandingSettings {
  const BrandingSettings({
    this.appName = 'All in One News',
    this.tagline = 'Every channel. One place.',
    this.logoUrl = '',
    this.splashImageUrl = '',
  });

  factory BrandingSettings.fromJson(Map<String, dynamic> j) => BrandingSettings(
    appName: _str(j['app_name'], 'All in One News'),
    tagline: _str(j['tagline']),
    logoUrl: _str(j['logo_url']),
    splashImageUrl: _str(j['splash_image_url']),
  );

  final String appName;
  final String tagline;
  final String logoUrl;
  final String splashImageUrl;
}

enum CardStyle { glass, solid, image }

class ThemeSettings {
  const ThemeSettings({
    this.mode = 'dark',
    this.primaryColor = '#FF7C4DFF',
    this.secondaryColor = '#FF00E5FF',
    this.accentColor = '#FFFF4081',
    this.backgroundColor = '#FF0A0E1A',
    this.surfaceColor = '#FF141A2E',
    this.textColor = '#FFF5F7FF',
    this.gradientStart = '#FF7C4DFF',
    this.gradientEnd = '#FF00E5FF',
    this.cornerRadius = 20,
    this.cardStyle = CardStyle.glass,
    this.enableAnimations = true,
  });

  factory ThemeSettings.fromJson(Map<String, dynamic> j) {
    const d = ThemeSettings();
    return ThemeSettings(
      mode: _str(j['mode'], d.mode),
      primaryColor: _str(j['primary_color'], d.primaryColor),
      secondaryColor: _str(j['secondary_color'], d.secondaryColor),
      accentColor: _str(j['accent_color'], d.accentColor),
      backgroundColor: _str(j['background_color'], d.backgroundColor),
      surfaceColor: _str(j['surface_color'], d.surfaceColor),
      textColor: _str(j['text_color'], d.textColor),
      gradientStart: _str(j['gradient_start'], d.gradientStart),
      gradientEnd: _str(j['gradient_end'], d.gradientEnd),
      cornerRadius: _double(j['corner_radius'], d.cornerRadius),
      cardStyle: CardStyle.values.firstWhere((c) => c.name == j['card_style'], orElse: () => CardStyle.glass),
      enableAnimations: _bool(j['enable_animations'], true),
    );
  }

  final String mode;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String backgroundColor;
  final String surfaceColor;
  final String textColor;
  final String gradientStart;
  final String gradientEnd;
  final double cornerRadius;
  final CardStyle cardStyle;
  final bool enableAnimations;
}

class Announcement {
  const Announcement({this.enabled = false, this.text = '', this.url = ''});

  factory Announcement.fromJson(Map<String, dynamic> j) =>
      Announcement(enabled: _bool(j['enabled']), text: _str(j['text']), url: _str(j['url']));

  final bool enabled;
  final String text;
  final String url;
}

class LayoutSettings {
  const LayoutSettings({
    this.homeBackgroundUrl = '',
    this.homeBackgroundOpacity = 0.35,
    this.showFeatured = true,
    this.featuredTitle = 'Featured',
    this.featuredStyle = 'carousel',
    this.showSearch = true,
    this.showCategoryTabs = true,
    this.gridColumns = 3,
    this.showDescriptions = true,
    this.announcement = const Announcement(),
  });

  factory LayoutSettings.fromJson(Map<String, dynamic> j) => LayoutSettings(
    homeBackgroundUrl: _str(j['home_background_url']),
    homeBackgroundOpacity: _double(j['home_background_opacity'], 0.35).clamp(0, 1),
    showFeatured: _bool(j['show_featured'], true),
    featuredTitle: _str(j['featured_title'], 'Featured'),
    featuredStyle: _str(j['featured_style'], 'carousel'),
    showSearch: _bool(j['show_search'], true),
    showCategoryTabs: _bool(j['show_category_tabs'], true),
    gridColumns: _int(j['grid_columns'], 3).clamp(2, 4),
    showDescriptions: _bool(j['show_descriptions'], true),
    announcement: Announcement.fromJson(_map(j['announcement'])),
  );

  final String homeBackgroundUrl;
  final double homeBackgroundOpacity;
  final bool showFeatured;
  final String featuredTitle;
  final String featuredStyle;
  final bool showSearch;
  final bool showCategoryTabs;
  final int gridColumns;
  final bool showDescriptions;
  final Announcement announcement;
}

class BrowserSettings {
  const BrowserSettings({
    this.defaultOpenMode = OpenMode.customTab,
    this.showToolbar = true,
    this.allowOpenInExternalBrowser = true,
    this.allowShare = true,
  });

  factory BrowserSettings.fromJson(Map<String, dynamic> j) {
    final mode = OpenMode.parse(_str(j['default_open_mode'], 'custom_tab'));
    return BrowserSettings(
      defaultOpenMode: mode == OpenMode.appDefault ? OpenMode.customTab : mode,
      showToolbar: _bool(j['show_toolbar'], true),
      allowOpenInExternalBrowser: _bool(j['allow_open_in_external_browser'], true),
      allowShare: _bool(j['allow_share'], true),
    );
  }

  final OpenMode defaultOpenMode;
  final bool showToolbar;
  final bool allowOpenInExternalBrowser;
  final bool allowShare;
}

class LegalSettings {
  const LegalSettings({
    this.privacyPolicyUrl = '',
    this.termsUrl = '',
    this.contactEmail = '',
    this.publisherName = '',
    this.aboutText = '',
  });

  factory LegalSettings.fromJson(Map<String, dynamic> j) => LegalSettings(
    privacyPolicyUrl: _str(j['privacy_policy_url']),
    termsUrl: _str(j['terms_url']),
    contactEmail: _str(j['contact_email']),
    publisherName: _str(j['publisher_name']),
    aboutText: _str(j['about_text']),
  );

  final String privacyPolicyUrl;
  final String termsUrl;
  final String contactEmail;
  final String publisherName;
  final String aboutText;
}

class AppSettings {
  const AppSettings({
    this.branding = const BrandingSettings(),
    this.theme = const ThemeSettings(),
    this.layout = const LayoutSettings(),
    this.browser = const BrowserSettings(),
    this.legal = const LegalSettings(),
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    branding: BrandingSettings.fromJson(_map(j['branding'])),
    theme: ThemeSettings.fromJson(_map(j['theme'])),
    layout: LayoutSettings.fromJson(_map(j['layout'])),
    browser: BrowserSettings.fromJson(_map(j['browser'])),
    legal: LegalSettings.fromJson(_map(j['legal'])),
  );

  final BrandingSettings branding;
  final ThemeSettings theme;
  final LayoutSettings layout;
  final BrowserSettings browser;
  final LegalSettings legal;
}

class Category {
  const Category({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    this.iconName = '',
    this.iconUrl = '',
    this.backgroundUrl = '',
    this.color = '',
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: _int(j['id']),
    name: _str(j['name']),
    slug: _str(j['slug']),
    description: _str(j['description']),
    iconName: _str(j['icon_name']),
    iconUrl: _str(j['icon_url']),
    backgroundUrl: _str(j['background_url']),
    color: _str(j['color']),
  );

  final int id;
  final String name;
  final String slug;
  final String description;
  final String iconName;
  final String iconUrl;
  final String backgroundUrl;
  final String color;
}

class Site {
  const Site({
    required this.id,
    required this.title,
    required this.url,
    this.categoryId,
    this.description = '',
    this.logoUrl = '',
    this.backgroundUrl = '',
    this.animationUrl = '',
    this.accentColor = '',
    this.badge = '',
    this.tags = const [],
    this.openMode = OpenMode.appDefault,
    this.isFeatured = false,
  });

  factory Site.fromJson(Map<String, dynamic> j) => Site(
    id: _int(j['id']),
    title: _str(j['title']),
    url: _str(j['url']),
    categoryId: j['category_id'] is int ? j['category_id'] as int : null,
    description: _str(j['description']),
    logoUrl: _str(j['logo_url']),
    backgroundUrl: _str(j['background_url']),
    animationUrl: _str(j['animation_url']),
    accentColor: _str(j['accent_color']),
    badge: _str(j['badge']),
    tags: _list(j['tags']).whereType<String>().toList(growable: false),
    openMode: OpenMode.parse(_str(j['open_mode'])),
    isFeatured: _bool(j['is_featured']),
  );

  final int id;
  final String title;
  final String url;
  final int? categoryId;
  final String description;
  final String logoUrl;
  final String backgroundUrl;
  final String animationUrl;
  final String accentColor;
  final String badge;
  final List<String> tags;
  final OpenMode openMode;
  final bool isFeatured;

  String get host => Uri.tryParse(url)?.host.replaceFirst('www.', '') ?? url;

  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        host.contains(q) ||
        tags.any((t) => t.toLowerCase().contains(q));
  }
}

/// The complete configuration: settings plus content.
class AppConfig {
  AppConfig({
    required this.version,
    required this.settings,
    required this.categories,
    required this.sites,
    required List<int> featuredIds,
  }) : _siteById = {for (final s in sites) s.id: s},
       featured = featuredIds.map((id) => sites.where((s) => s.id == id).firstOrNull).nonNulls.toList(growable: false);

  factory AppConfig.fromJson(Map<String, dynamic> j) {
    final sites = _list(j['sites']).whereType<Map<String, dynamic>>().map(Site.fromJson).where((s) => s.url.isNotEmpty);
    return AppConfig(
      version: _str(j['version']),
      settings: AppSettings.fromJson(_map(j['settings'])),
      categories: _list(j['categories'])
          .whereType<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList(growable: false),
      sites: sites.toList(growable: false),
      featuredIds: _list(j['featured']).whereType<int>().toList(growable: false),
    );
  }

  final String version;
  final AppSettings settings;
  final List<Category> categories;
  final List<Site> sites;
  final List<Site> featured;
  final Map<int, Site> _siteById;

  Site? siteById(int id) => _siteById[id];

  List<Site> sitesIn(int categoryId) => sites.where((s) => s.categoryId == categoryId).toList(growable: false);

  Category? categoryById(int? id) => id == null ? null : categories.where((c) => c.id == id).firstOrNull;

  List<Site> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    return sites.where((s) => s.matches(q)).toList(growable: false);
  }
}
