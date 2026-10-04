import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/color_utils.dart';
import '../../core/utils/icon_registry.dart';
import '../../core/widgets/badge_chip.dart';
import '../../core/widgets/site_logo.dart';
import '../../core/widgets/status_views.dart';
import '../../data/models/app_config.dart';
import '../../data/providers.dart';
import '../browser/link_opener.dart';
import '../home/widgets/site_actions.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final results = config?.search(_query) ?? const <Site>[];
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search channels and websites',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _controller.clear();
                            _query = '';
                          }),
                        ),
                ),
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? _Suggestions(categories: config?.categories ?? const [])
                  : results.isEmpty
                  ? StatusView(
                      icon: Icons.search_off_rounded,
                      title: 'No results for “${_query.trim()}”',
                      message: 'Try a different word.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final s = results[i];
                        final category = config?.categoryById(s.categoryId);
                        return Material(
                          color: context.visuals.glassFill,
                          borderRadius: BorderRadius.circular(context.visuals.radius),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.visuals.radius)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: SiteLogo(title: s.title, logoUrl: s.logoUrl, accentColor: s.accentColor, size: 44),
                            title: Row(
                              children: [
                                Flexible(child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                if (s.badge.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  BadgeChip(s.badge, compact: true),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              [if (category != null) category.name, s.host].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: const Icon(Icons.north_east_rounded, size: 18),
                            onTap: () => LinkOpener.openSite(context, ref, s),
                            onLongPress: () => showSiteActions(context, ref, s),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Browse categories', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in categories)
              ActionChip(
                avatar: Icon(iconFor(c.iconName), size: 18, color: parseColor(c.color)),
                label: Text(c.name),
                onPressed: () => context.push('/category/${c.id}'),
              ),
          ],
        ),
      ],
    );
  }
}
