import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// On-device storage. Nothing stored here ever leaves the device
/// (see the privacy policy and Data Safety answers in the docs).
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _configKey = 'config.cached.v1';
  static const _etagKey = 'config.etag.v1';
  static const _fetchedAtKey = 'config.fetched_at.v1';
  static const _favoritesKey = 'favorites.v1';
  static const _recentsKey = 'recents.v1';
  static const _maxRecents = 20;

  // ---- configuration cache -------------------------------------------------
  Map<String, dynamic>? readCachedConfig() {
    final raw = _prefs.getString(_configKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  String? get cachedEtag => _prefs.getString(_etagKey);

  DateTime? get lastFetchedAt {
    final ms = _prefs.getInt(_fetchedAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> writeCachedConfig(Map<String, dynamic> json, String? etag) async {
    await _prefs.setString(_configKey, jsonEncode(json));
    if (etag != null) await _prefs.setString(_etagKey, etag);
    await markFetched();
  }

  Future<void> markFetched() => _prefs.setInt(_fetchedAtKey, DateTime.now().millisecondsSinceEpoch);

  Future<void> clearCache() async {
    await _prefs.remove(_configKey);
    await _prefs.remove(_etagKey);
    await _prefs.remove(_fetchedAtKey);
  }

  // ---- favourites (user bookmarks) -------------------------------------
  List<int> get favorites => _ids(_favoritesKey);
  Future<void> setFavorites(List<int> ids) => _prefs.setStringList(_favoritesKey, ids.map((e) => '$e').toList());

  // ---- recently opened ------------------------------------------------------
  List<int> get recents => _ids(_recentsKey);
  Future<void> addRecent(int id) {
    final list = [id, ...recents.where((e) => e != id)].take(_maxRecents).toList();
    return _prefs.setStringList(_recentsKey, list.map((e) => '$e').toList());
  }

  Future<void> clearRecents() => _prefs.remove(_recentsKey);

  List<int> _ids(String key) => (_prefs.getStringList(key) ?? const []).map(int.tryParse).nonNulls.toList();
}
