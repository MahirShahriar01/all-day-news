import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/about/about_screen.dart';
import 'features/browser/browser_screen.dart';
import 'features/browser/link_opener.dart';
import 'features/category/category_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/home/home_screen.dart';
import 'features/search/search_screen.dart';
import 'features/shell/main_shell.dart';

/// All app routes. New features add a route (or a shell branch) here.
GoRouter buildRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/search', builder: (_, _) => const SearchScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/about', builder: (_, _) => const AboutScreen())],
        ),
      ],
    ),
    GoRoute(
      path: '/category/:id',
      builder: (_, state) => CategoryScreen(categoryId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1),
    ),
    GoRoute(
      path: '/browser',
      pageBuilder: (_, state) =>
          MaterialPage(fullscreenDialog: true, child: BrowserScreen(args: state.extra! as BrowserArgs)),
      redirect: (_, state) => state.extra is BrowserArgs ? null : '/',
    ),
  ],
);
