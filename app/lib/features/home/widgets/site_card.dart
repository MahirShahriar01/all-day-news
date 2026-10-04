import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/color_utils.dart';
import '../../../core/widgets/badge_chip.dart';
import '../../../core/widgets/net_media.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/site_logo.dart';
import '../../../data/models/app_config.dart';
import '../../browser/link_opener.dart';
import 'site_actions.dart';

/// Grid card for one website: logo, title and optional description.
class SiteCard extends ConsumerWidget {
  const SiteCard({super.key, required this.site, this.showDescription = false, this.compact = false});

  final Site site;
  final bool showDescription;
  final bool compact;

  /// Height of a card for a given column count, respecting the user's font size.
  static double extentFor(BuildContext context, int columns, bool showDescription) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final logo = columns >= 4 ? 44.0 : 52.0;
    final s = scale.clamp(1.0, 2.0);
    final title = 2 * 17 * s;
    final description = showDescription ? 4 + 2 * 15 * s : 0;
    return 24 + logo + 10 + title + description + 6;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final visuals = context.visuals;
    final radius = BorderRadius.circular(visuals.radius);
    final imageStyle = visuals.cardStyle == CardStyle.image;
    final accent = parseColor(site.accentColor) ?? theme.colorScheme.primary;
    final fg = imageStyle ? Colors.white : theme.colorScheme.onSurface;

    final decoration = switch (visuals.cardStyle) {
      CardStyle.glass => BoxDecoration(
        color: visuals.glassFill,
        borderRadius: radius,
        border: Border.all(color: visuals.glassBorder),
      ),
      CardStyle.solid => BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      CardStyle.image => BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.55)!],
        ),
      ),
    };

    return Pressable(
      onTap: () => LinkOpener.openSite(context, ref, site),
      onLongPress: () => showSiteActions(context, ref, site),
      semanticLabel: '${site.title}${site.badge.isNotEmpty ? ', ${site.badge}' : ''}. ${site.description}',
      borderRadius: radius,
      child: Container(
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (imageStyle && site.backgroundUrl.isNotEmpty) ...[
              Positioned.fill(child: NetMedia(url: site.backgroundUrl, playVideo: false)),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0xCC000000)],
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.all(compact ? 8 : 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SiteLogo(
                    title: site.title,
                    logoUrl: site.logoUrl,
                    accentColor: site.accentColor,
                    size: compact ? 44 : 52,
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      site.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: fg, height: 1.15),
                    ),
                  ),
                  if (showDescription && site.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        site.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.7), height: 1.2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (site.badge.isNotEmpty) Positioned(top: 8, right: 8, child: BadgeChip(site.badge, compact: true)),
          ],
        ),
      ),
    );
  }
}

/// Sliver grid of [SiteCard]s.
class SiteGrid extends StatelessWidget {
  const SiteGrid({
    super.key,
    required this.sites,
    required this.columns,
    this.showDescriptions = false,
    this.indexOffset = 0,
  });

  final List<Site> sites;
  final int columns;
  final bool showDescriptions;
  final int indexOffset;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Tablets / landscape get more columns automatically.
    final cols = width > 900 ? columns + 3 : (width > 600 ? columns + 1 : columns);
    final showDesc = showDescriptions && cols <= 3;
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: SiteCard.extentFor(context, cols, showDesc),
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => SiteCard(site: sites[i], showDescription: showDesc, compact: cols >= 4),
        childCount: sites.length,
      ),
    );
  }
}
