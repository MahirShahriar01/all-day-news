import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_background.dart';
import '../../core/widgets/status_views.dart';
import '../../data/providers.dart';
import '../home/widgets/home_sections.dart';
import '../home/widgets/site_card.dart';

/// All websites of one category.
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final int categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final category = config?.categoryById(categoryId);
    if (config == null || category == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const StatusView(icon: Icons.folder_off_rounded, title: 'This category is no longer available'),
      );
    }
    final layout = config.settings.layout;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(category.name)),
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: CategoryBanner(category: category)),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SiteGrid(
                  sites: config.sitesIn(category.id),
                  columns: layout.gridColumns,
                  showDescriptions: layout.showDescriptions,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}
