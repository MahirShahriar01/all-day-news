import 'dart:convert';
import 'dart:io';

import 'package:all_in_one_news/core/network/api_client.dart';
import 'package:all_in_one_news/core/network/api_exception.dart';
import 'package:all_in_one_news/data/local/local_store.dart';
import 'package:all_in_one_news/data/repositories/config_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(File(key).readAsBytesSync());
}

Map<String, dynamic> _config(String name) => {
  'version': 'v-$name',
  'settings': {
    'branding': {'app_name': name},
  },
  'categories': [],
  'sites': [],
  'featured': [],
};

void main() {
  late LocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
  });

  ConfigRepository repo(http.Client client) => ConfigRepository(
    api: ApiClient(httpClient: client, baseUrl: 'https://api.test'),
    store: store,
    bundle: _FileBundle(),
    hasBackend: true,
  );

  test('falls back to bundled config when nothing is cached', () async {
    final r = repo(MockClient((_) async => http.Response('', 500)));
    final snap = await r.loadLocal();
    expect(snap.source, ConfigSource.bundled);
    expect(snap.config.sites, isNotEmpty);
  });

  test('downloads, caches and then sends ETag', () async {
    final seenEtags = <String?>[];
    final client = MockClient((req) async {
      expect(req.url.toString(), 'https://api.test/api/v1/config');
      seenEtags.add(req.headers['If-None-Match']);
      if (req.headers['If-None-Match'] == '"abc"') return http.Response('', 304);
      return http.Response(jsonEncode(_config('Remote')), 200, headers: {'etag': '"abc"'});
    });
    final r = repo(client);

    final first = await r.fetchRemote();
    expect(first!.source, ConfigSource.network);
    expect(first.config.settings.branding.appName, 'Remote');

    final cached = await r.loadLocal();
    expect(cached.source, ConfigSource.cache);
    expect(cached.config.settings.branding.appName, 'Remote');

    expect(await r.fetchRemote(), isNull, reason: '304 means unchanged');
    expect(seenEtags, [null, '"abc"']);
  });

  test('maps server errors to ApiException', () async {
    final r = repo(MockClient((_) async => http.Response('nope', 503)));
    expect(r.fetchRemote(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 503)));
  });

  test('does nothing without a backend', () async {
    final r = ConfigRepository(api: ApiClient(), store: store, bundle: _FileBundle(), hasBackend: false);
    expect(await r.fetchRemote(), isNull);
  });
}
