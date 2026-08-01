# Khandan Telegraph — Flutter Mobile App

Mobile app for **Khandan Telegraph** news platform (Kurdish news).

## Overview

- **Package ID**: `com.khandan.telegraph`
- **Languages**: Kurdish (ckb) and English
- **Backend**: Laravel REST API at `https://khandantelegraph.news/api/v1`
- **Push**: Firebase Cloud Messaging (fallback to in-app notification polling)

## Features

- Breaking news & featured articles slider
- Article listing by category / author, search
- Article detail with comments
- In-app notifications (30s polling + FCM)
- Force-update screen driven by server `minimum_app_version` setting
- Offline / no-internet handling
- RTL support for Kurdish

## Build

```bash
# Android APK (release, signed via android/key.properties)
flutter build apk --release

# Android App Bundle (AAB)
flutter build appbundle --release

# iOS (needs Apple signing setup)
flutter build ipa
```

Outputs:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## Release notes

- Update `version` in `pubspec.yaml` (e.g. `1.0.0+10`)
- `android/app/build.gradle.kts` reads `versionCode`/`versionName` from pubspec automatically
- Publish the APK to `https://khandantelegraph.news/downloads/khandan.apk`
- Update `minimum_app_version` in the admin panel (`/panel-khandan` → System → App Update)

## Localization

Generated via `flutter gen-l10n` from `l10n.yaml`.
