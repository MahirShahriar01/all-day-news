import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/color_utils.dart';
import '../../core/utils/icon_registry.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/fade_in.dart';
import '../../core/widgets/net_media.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/site_logo.dart';
import '../../core/widgets/status_views.dart';
import '../../data/models/app_config.dart';
import '../../data/providers.dart';
import '../../data/repositories/config_repository.dart';
import '../browser/link_opener.dart';
import 'widgets/featured.dart';
import 'widgets/home_sections.dart';
import 'widgets/site_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(configProvider);
    return switch (snapshot) {
      AsyncValue(hasValue: true) => _buildContent(context, snapshot.requireValue),
      AsyncValue(error: final Object _) => StatusView(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load content',
        message: 'Please check your connection and try again.',
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(configProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildContent(BuildContext context, ConfigSnapshot snap) {
    final config = snap.config;
    final layout = config.settings.layout;
    final categories = config.categories.where((c) => config.sitesIn(c.id).isNotEmpty).toList();
    final selected = categories.where((c) => c.id == _selectedCategory).firstOrNull;
    final recents = resolveSites(config, ref.watch(recentsProvider)).take(10).toList();

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: _Header(config: config, snapshot: snap),
      ),
      if (layout.announcement.enabled && layout.announcement.text.isNotEmpty)
        SliverToBoxAdapter(
          child: FadeIn(index: 1, child: AnnouncementBanner(announcement: layout.announcement)),
        ),
      if (layout.showSearch)
        SliverToBoxAdapter(
          child: FadeIn(index: 2, child: _SearchButton(onTap: () => context.go('/search'))),
        ),
      if (layout.showFeatured && config.featured.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(title: layout.featuredTitle, icon: Icons.star_rounded, color: context.visuals.accent),
        ),
        SliverToBoxAdapter(
          child: FadeIn(
            index: 3,
            child: layout.featuredStyle == 'grid'
                ? FeaturedGrid(sites: config.featured)
                : FeaturedCarousel(sites: config.featured),
          ),
        ),
      ],
      if (recents.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: SectionHeader(title: 'Recently opened', icon: Icons.history_rounded),
        ),
        SliverToBoxAdapter(child: _RecentStrip(sites: recents)),
      ],
      if (layout.showCategoryTabs && categories.isNotEmpty)
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabsHeader(
            height: 60 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
            child: CategoryTabs(
              categories: categories,
              selectedId: selected?.id,
              onSelected: (id) => setState(() => _selectedCategory = id),
            ),
          ),
        ),
    ];

    if (config.sites.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: StatusView(
            icon: Icons.travel_explore_rounded,
            title: 'Nothing here yet',
            message: 'New channels and websites will appear here soon.',
          ),
        ),
      );
    } else if (selected != null) {
      slivers
        ..add(SliverToBoxAdapter(child: CategoryBanner(category: selected)))
        ..add(const SliverToBoxAdapter(child: SizedBox(height: 14)))
        ..add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SiteGrid(
              sites: config.sitesIn(selected.id),
              columns: layout.gridColumns,
              showDescriptions: layout.showDescriptions,
            ),
          ),
        );
    } else {
      for (final c in categories) {
        final sites = config.sitesIn(c.id);
        final limit = layout.gridColumns * 2;
        slivers
          ..add(
            SliverToBoxAdapter(
              child: SectionHeader(
                title: c.name,
                icon: iconFor(c.iconName),
                color: parseColor(c.color),
                onSeeAll: sites.length > limit ? () => context.push('/category/${c.id}') : null,
              ),
            ),
          )
          ..add(
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SiteGrid(
                sites: sites.take(limit).toList(),
                columns: layout.gridColumns,
                showDescriptions: layout.showDescriptions,
              ),
            ),
          );
      }
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));

    return AppBackground(
      imageUrl: layout.homeBackgroundUrl,
      imageOpacity: layout.homeBackgroundOpacity,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(configProvider.notifier).refresh(force: true),
          child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: slivers),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.config, required this.snapshot});

  final AppConfig config;
  final ConfigSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = config.settings.branding;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: context.visuals.gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: branding.logoUrl.isEmpty
                  ? const Icon(Icons.blur_on_rounded, color: Colors.white, size: 28)
                  : NetMedia(
                      url: branding.logoUrl,
                      fallback: const Icon(Icons.blur_on_rounded, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    branding.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                ),
                if (branding.tagline.isNotEmpty)
                  Text(
                    branding.tagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
          if (snapshot.error != null)
            IconButton(
              tooltip: 'Offline: showing saved content',
              icon: Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error),
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${snapshot.error}. Showing saved content; pull down to retry.'))),
            ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = context.visuals;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Pressable(
        onTap: onTap,
        semanticLabel: 'Search websites',
        borderRadius: BorderRadius.circular(visuals.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: visuals.glassFill,
            borderRadius: BorderRadius.circular(visuals.radius),
            border: Border.all(color: visuals.glassBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search channels and websites',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentStrip extends ConsumerWidget {
  const _RecentStrip({required this.sites});

  final List<Site> sites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SizedBox(
      height: 84 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: sites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final s = sites[i];
          return SizedBox(
            width: 64,
            child: Pressable(
              onTap: () => LinkOpener.openSite(context, ref, s),
              semanticLabel: s.title,
              child: Column(
                children: [
                  SiteLogo(title: s.title, logoUrl: s.logoUrl, accentColor: s.accentColor, size: 52),
                  const SizedBox(height: 6),
                  Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: bg.withValues(alpha: overlapsContent || shrinkOffset > 0 ? 0.8 : 0),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsHeader oldDelegate) => oldDelegate.child != child || oldDelegate.height != height;
}
