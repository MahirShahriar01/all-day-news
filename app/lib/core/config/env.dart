/// Build-time configuration, supplied with `--dart-define` (or
/// `--dart-define-from-file=env/production.json`). Nothing secret belongs
/// here: everything compiled into an app can be extracted from it.
class Env {
  const Env._();

  /// Base URL of the All in One News API, e.g. `https://news.example.com`.
  /// When empty the app runs on the bundled demo content only.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// `development`, `staging` or `production`.
  static const String flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'production');

  static const Duration requestTimeout = Duration(seconds: 15);

  /// How long a downloaded configuration is considered fresh before the app
  /// silently checks for changes again (e.g. when returning from background).
  static const Duration refreshInterval = Duration(minutes: 5);

  static bool get hasBackend => apiBaseUrl.isNotEmpty;

  static Uri apiUri(String path) {
    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    return Uri.parse('$base/api/v1$path');
  }
}
