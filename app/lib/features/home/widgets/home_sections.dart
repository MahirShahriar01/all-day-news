import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/color_utils.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../core/widgets/net_media.dart';
import '../../../data/models/app_config.dart';
import '../../browser/link_opener.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.icon, this.color, this.onSeeAll});

  final String title;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Semantics(header: true, child: Text(title, style: theme.textTheme.titleMedium)),
          ),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

/// Horizontally scrolling category chips ("All" first).
class CategoryTabs extends StatelessWidget {
  const CategoryTabs({super.key, required this.categories, required this.selectedId, required this.onSelected});

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final visuals = context.visuals;
    final theme = Theme.of(context);
    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      IconData? icon,
      Color? color,
    }) {
      final fg = selected ? Colors.white : theme.colorScheme.onSurface;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: selected
                      ? (color == null
                            ? visuals.gradient
                            : LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.25)!]))
                      : null,
                  color: selected ? null : visuals.glassFill,
                  border: Border.all(color: selected ? Colors.transparent : visuals.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 6)],
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          chip(
            label: 'All',
            icon: Icons.auto_awesome_rounded,
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final c in categories)
            chip(
              label: c.name,
              icon: iconFor(c.iconName),
              color: parseColor(c.color),
              selected: selectedId == c.id,
              onTap: () => onSelected(c.id),
            ),
        ],
      ),
    );
  }
}

/// Header banner for a category (uses its background image if set).
class CategoryBanner extends StatelessWidget {
  const CategoryBanner({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    if (category.backgroundUrl.isEmpty && category.description.isEmpty) return const SizedBox.shrink();
    final visuals = context.visuals;
    final color = parseColor(category.color) ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(visuals.radius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.35)]),
          ),
          child: Stack(
            children: [
              if (category.backgroundUrl.isNotEmpty) Positioned.fill(child: NetMedia(url: category.backgroundUrl)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.1)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(iconFor(category.iconName), color: Colors.white, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                          ),
                          if (category.description.isNotEmpty)
                            Text(
                              category.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
      ),
    );
  }
}

class AnnouncementBanner extends ConsumerWidget {
  const AnnouncementBanner({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visuals = context.visuals;
    final hasLink = announcement.url.startsWith('http');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(visuals.radius),
          onTap: hasLink ? () => LinkOpener.openUrl(context, announcement.url) : null,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(gradient: visuals.gradient, borderRadius: BorderRadius.circular(visuals.radius)),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    announcement.text,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                if (hasLink) const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
