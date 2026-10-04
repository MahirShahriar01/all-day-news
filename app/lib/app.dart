import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/models/app_config.dart';
import 'data/providers.dart';
import 'router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});

class AllInOneNewsApp extends ConsumerWidget {
  const AllInOneNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appConfigProvider)?.settings ?? const AppSettings();
    final theme = settings.theme;
    final mode = AppTheme.themeMode(theme);
    return MaterialApp.router(
      title: settings.branding.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(theme, Brightness.light),
      darkTheme: AppTheme.build(theme, Brightness.dark),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          ),
          // Very large accessibility fonts are honoured but capped so card
          // layouts stay usable.
          child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.6, child: child!),
        );
      },
    );
  }
}
