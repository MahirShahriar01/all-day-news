import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/site_logo.dart';
import '../../core/widgets/status_views.dart';
import '../../data/providers.dart';
import '../browser/link_opener.dart';

/// The user's own bookmarks, stored on the device. Drag to reorder,
/// swipe to remove.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final ids = ref.watch(favoritesProvider);
    final sites = resolveSites(config, ids);
    final visuals = context.visuals;

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: sites.isEmpty
          ? const StatusView(
              icon: Icons.bookmarks_outlined,
              title: 'No favourites yet',
              message: 'Long-press any channel or website and choose “Add to favourites” to keep it here.',
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: sites.length,
              onReorderItem: (from, to) {
                final order = [for (final s in sites) s.id];
                order.insert(to, order.removeAt(from));
                ref.read(favoritesProvider.notifier).setOrder(order);
              },
              itemBuilder: (context, i) {
                final s = sites[i];
                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(visuals.radius),
                    ),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(favoritesProvider.notifier).toggle(s.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${s.title}'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () => ref.read(favoritesProvider.notifier).toggle(s.id),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Material(
                      color: visuals.glassFill,
                      borderRadius: BorderRadius.circular(visuals.radius),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(visuals.radius)),
                        leading: SiteLogo(title: s.title, logoUrl: s.logoUrl, accentColor: s.accentColor, size: 44),
                        title: Text(s.title),
                        subtitle: Text(s.host, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle_rounded, semanticLabel: 'Reorder'),
                        ),
                        onTap: () => LinkOpener.openSite(context, ref, s),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
