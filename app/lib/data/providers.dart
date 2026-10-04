import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import 'local/local_store.dart';
import 'models/app_config.dart';
import 'repositories/config_repository.dart';

/// Overridden in `main.dart` once SharedPreferences is ready.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider not initialised'),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});

final configRepositoryProvider = Provider<ConfigRepository>(
  (ref) => ConfigRepository(api: ref.watch(apiClientProvider), store: ref.watch(localStoreProvider)),
);

/// The configuration shown by the whole app. Loads local data first and then
/// refreshes from the server; refreshes again when the app returns to the
/// foreground and the data is older than [Env.refreshInterval].
class ConfigController extends AsyncNotifier<ConfigSnapshot> {
  AppLifecycleListener? _lifecycle;

  ConfigRepository get _repo => ref.read(configRepositoryProvider);

  @override
  Future<ConfigSnapshot> build() async {
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_repo.isStale) refresh();
      },
    );
    ref.onDispose(() => _lifecycle?.dispose());

    final local = await _repo.loadLocal();
    if (_repo.hasBackend) Future.microtask(refresh);
    return local;
  }

  /// Pull-to-refresh / automatic refresh. Never throws: on failure the current
  /// data stays on screen with [ConfigSnapshot.error] set.
  Future<void> refresh({bool force = false}) async {
    final current = state.hasValue ? state.requireValue : null;
    try {
      final fresh = await _repo.fetchRemote(force: force);
      if (fresh != null) {
        state = AsyncData(fresh);
      } else if (current != null && current.error != null) {
        state = AsyncData(current.copyWith(error: null));
      }
    } on ApiException catch (e) {
      if (current != null) state = AsyncData(current.copyWith(error: e.message));
    }
  }
}

final configProvider = AsyncNotifierProvider<ConfigController, ConfigSnapshot>(ConfigController.new);

/// Convenience: the current [AppConfig] or null while the very first load runs.
final appConfigProvider = Provider<AppConfig?>((ref) {
  final value = ref.watch(configProvider);
  return value.hasValue ? value.requireValue.config : null;
});

/// User favourites (bookmarks), stored on the device only.
class FavoritesController extends Notifier<List<int>> {
  @override
  List<int> build() => ref.read(localStoreProvider).favorites;

  bool isFavorite(int id) => state.contains(id);

  void toggle(int id) {
    state = state.contains(id) ? state.where((e) => e != id).toList() : [...state, id];
    ref.read(localStoreProvider).setFavorites(state);
  }

  /// Persist a new order. Ids no longer in the configuration are kept at the end.
  void setOrder(List<int> visibleOrder) {
    final rest = state.where((id) => !visibleOrder.contains(id));
    state = [...visibleOrder, ...rest];
    ref.read(localStoreProvider).setFavorites(state);
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, List<int>>(FavoritesController.new);

/// Recently opened websites, most recent first.
class RecentsController extends Notifier<List<int>> {
  @override
  List<int> build() => ref.read(localStoreProvider).recents;

  void add(int id) {
    state = [id, ...state.where((e) => e != id)].take(20).toList();
    ref.read(localStoreProvider).addRecent(id);
  }

  void clear() {
    state = const [];
    ref.read(localStoreProvider).clearRecents();
  }
}

final recentsProvider = NotifierProvider<RecentsController, List<int>>(RecentsController.new);

/// Resolve stored ids into sites that still exist in the configuration.
List<Site> resolveSites(AppConfig? config, List<int> ids) =>
    config == null ? const [] : ids.map(config.siteById).nonNulls.toList(growable: false);
