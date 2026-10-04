import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/site_logo.dart';
import '../../../data/models/app_config.dart';
import '../../../data/providers.dart';
import '../../browser/link_opener.dart';

/// Long-press menu for a website card.
Future<void> showSiteActions(BuildContext context, WidgetRef ref, Site site) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final isFav = ref.watch(favoritesProvider).contains(site.id);
        final browser = ref.watch(appConfigProvider)?.settings.browser ?? const BrowserSettings();
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: SiteLogo(title: site.title, logoUrl: site.logoUrl, accentColor: site.accentColor, size: 44),
                title: Text(site.title, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(site.host),
              ),
              if (site.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(alignment: Alignment.centerLeft, child: Text(site.description)),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  LinkOpener.openSite(context, ref, site);
                },
              ),
              ListTile(
                leading: Icon(isFav ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded),
                title: Text(isFav ? 'Remove from favourites' : 'Add to favourites'),
                onTap: () {
                  ref.read(favoritesProvider.notifier).toggle(site.id);
                  Navigator.pop(sheetContext);
                },
              ),
              if (browser.allowShare)
                ListTile(
                  leading: const Icon(Icons.ios_share_rounded),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    SharePlus.instance.share(ShareParams(uri: Uri.parse(site.url), subject: site.title));
                  },
                ),
              if (browser.allowOpenInExternalBrowser)
                ListTile(
                  leading: const Icon(Icons.open_in_browser_rounded),
                  title: const Text('Open in browser'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    LinkOpener.openExternal(Uri.parse(site.url));
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}
