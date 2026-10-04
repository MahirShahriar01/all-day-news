import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/app_config.dart';
import '../../data/providers.dart';

/// Arguments for the embedded browser route.
class BrowserArgs {
  const BrowserArgs({required this.url, required this.title, this.siteId});

  final String url;
  final String title;
  final int? siteId;
}

/// Opens websites the way the administrator configured:
///   * custom_tab → Chrome Custom Tab (Android) / SFSafariViewController (iOS)
///   * in_app     → the app's own WebView screen ([BrowserScreen])
///   * external   → the default browser or the site's own app
class LinkOpener {
  const LinkOpener._();

  static Future<void> openSite(BuildContext context, WidgetRef ref, Site site) async {
    ref.read(recentsProvider.notifier).add(site.id);
    final settings = ref.read(appConfigProvider)?.settings.browser ?? const BrowserSettings();
    final mode = site.openMode == OpenMode.appDefault ? settings.defaultOpenMode : site.openMode;
    await openUrl(context, site.url, title: site.title, mode: mode, siteId: site.id);
  }

  static Future<void> openUrl(
    BuildContext context,
    String url, {
    String title = '',
    OpenMode mode = OpenMode.customTab,
    int? siteId,
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      _fail(context);
      return;
    }
    // Clear-text (http) pages are blocked inside the app's WebView for
    // security; let the system browser handle them instead.
    if (mode == OpenMode.inApp && uri.isScheme('https')) {
      await context.push(
        '/browser',
        extra: BrowserArgs(url: uri.toString(), title: title, siteId: siteId),
      );
      return;
    }
    var ok = false;
    try {
      if (mode != OpenMode.external) ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (!ok) ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) _fail(context);
  }

  /// For links that should always leave the app (mailto:, tel:, store links).
  static Future<bool> openExternal(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static void _fail(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This link could not be opened.')));
  }
}
