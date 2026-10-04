# All in One News: Flutter app (Android & iOS)

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator + local backend
flutter run                                                    # bundled demo content
flutter analyze && flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://news.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://news.example.com
flutter build ipa --release --dart-define=API_BASE_URL=https://news.example.com   # macOS
```

* Code structure: [../docs/01-architecture.md](../docs/01-architecture.md#15-mobile-app-app)
* Build & signing: [../BUILD_INSTRUCTIONS.md](../BUILD_INSTRUCTIONS.md)
* Store release: [Google Play](../docs/10-play-store-release.md) · [App Store](../docs/11-app-store-release.md)
