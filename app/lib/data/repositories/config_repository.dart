import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/config/env.dart';
import '../../core/network/api_client.dart';
import '../local/local_store.dart';
import '../models/app_config.dart';

/// Where the currently displayed configuration came from.
enum ConfigSource { network, cache, bundled }

class ConfigSnapshot {
  const ConfigSnapshot(this.config, this.source, {this.error});

  final AppConfig config;
  final ConfigSource source;

  /// Set when the latest refresh failed and older data is being shown.
  final String? error;

  ConfigSnapshot copyWith({ConfigSource? source, String? error}) =>
      ConfigSnapshot(config, source ?? this.source, error: error);
}

/// Offline-first access to the app configuration.
///
/// 1. [loadLocal] returns instantly with the last downloaded configuration,
///    or the demo configuration bundled in `assets/config/`.
/// 2. [fetchRemote] asks the server for changes (cheap 304 when unchanged).
class ConfigRepository {
  ConfigRepository({required this.api, required this.store, AssetBundle? bundle, bool? hasBackend})
    : _bundle = bundle ?? rootBundle,
      hasBackend = hasBackend ?? Env.hasBackend;

  static const bundledAsset = 'assets/config/fallback_config.json';

  final ApiClient api;
  final LocalStore store;
  final AssetBundle _bundle;

  /// False when the app was built without `API_BASE_URL` (demo mode).
  final bool hasBackend;

  Future<ConfigSnapshot> loadLocal() async {
    final cached = store.readCachedConfig();
    if (cached != null) {
      try {
        return ConfigSnapshot(AppConfig.fromJson(cached), ConfigSource.cache);
      } catch (_) {
        await store.clearCache();
      }
    }
    final raw = await _bundle.loadString(bundledAsset);
    return ConfigSnapshot(AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>), ConfigSource.bundled);
  }

  bool get isStale {
    final last = store.lastFetchedAt;
    return last == null || DateTime.now().difference(last) > Env.refreshInterval;
  }

  /// Returns a new snapshot, or `null` when the server reports no change.
  /// Throws [ApiException] on failure.
  Future<ConfigSnapshot?> fetchRemote({bool force = false}) async {
    if (!hasBackend) return null;
    final etag = force ? null : store.cachedEtag;
    final response = await api.getJson('/config', etag: etag);
    if (response.notModified) {
      await store.markFetched();
      return null;
    }
    final json = response.json!;
    final config = AppConfig.fromJson(json); // validate before caching
    await store.writeCachedConfig(json, response.etag);
    return ConfigSnapshot(config, ConfigSource.network);
  }
}
