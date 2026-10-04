import 'dart:async';

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

/// Large hero card used by the featured carousel and grid.
class FeaturedCard extends ConsumerWidget {
  const FeaturedCard({super.key, required this.site, this.large = true});

  final Site site;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visuals = context.visuals;
    final theme = Theme.of(context);
    final accent = parseColor(site.accentColor);
    final radius = BorderRadius.circular(visuals.radius + 4);
    final media = site.animationUrl.isNotEmpty ? site.animationUrl : site.backgroundUrl;
    final gradient = accent == null
        ? visuals.gradient
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, visuals.gradient.colors.last],
          );

    return Pressable(
      onTap: () => LinkOpener.openSite(context, ref, site),
      onLongPress: () => showSiteActions(context, ref, site),
      semanticLabel: 'Featured: ${site.title}. ${site.description}',
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: (accent ?? theme.colorScheme.primary).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.isNotEmpty) NetMedia(url: media, playVideo: context.animate),
            if (media.isEmpty)
              Positioned(
                right: -30,
                bottom: -40,
                child: Opacity(
                  opacity: 0.18,
                  child: SiteLogo(title: site.title, logoUrl: '', accentColor: '#00000000', size: large ? 190 : 110),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x22000000), Color(0xCC000000)],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
            if (site.badge.isNotEmpty) Positioned(top: 14, left: 14, child: BadgeChip(site.badge)),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SiteLogo(
                    title: site.title,
                    logoUrl: site.logoUrl,
                    accentColor: site.accentColor,
                    size: large ? 48 : 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          site.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: (large ? theme.textTheme.titleLarge : theme.textTheme.titleSmall)?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (large && site.description.isNotEmpty)
                          Text(
                            site.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Auto-advancing carousel of featured websites.
class FeaturedCarousel extends StatefulWidget {
  const FeaturedCarousel({super.key, required this.sites});

  final List<Site> sites;

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  final _controller = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (context.animate && widget.sites.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!_controller.hasClients) return;
        final next = (_page + 1) % widget.sites.length;
        _controller.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = (width * 0.5).clamp(170.0, 280.0);
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.sites.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                var scale = 1.0;
                if (_controller.hasClients && _controller.position.haveDimensions && context.animate) {
                  final delta = ((_controller.page ?? 0) - i).abs();
                  scale = (1 - delta * 0.06).clamp(0.9, 1.0);
                }
                return Transform.scale(scale: scale, child: child);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: FeaturedCard(site: widget.sites[i]),
              ),
            ),
          ),
        ),
        if (widget.sites.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.sites.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Two-column grid alternative for the featured section.
class FeaturedGrid extends StatelessWidget {
  const FeaturedGrid({super.key, required this.sites});

  final List<Site> sites;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width > 600 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: sites.length,
      itemBuilder: (_, i) => FeaturedCard(site: sites[i], large: false),
    );
  }
}
