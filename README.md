# ptrainer

A cross-platform Flutter mobile application targeting iOS and Android.


## Getting Started

This project is a Flutter mobile application that now includes a basic
authentication flow. When the app starts you can **register** (username,
email, password) or **login** with username/password. Passwords are hashed
using SHA-256 before being saved in the local SQLite database (`sqflite`).

To run:

1. Ensure [Flutter SDK](https://flutter.dev) is installed and configured.
2. Run `flutter pub get` to install dependencies (including `crypto`,
   `sqflite`, etc.).
3. Launch the app with `flutter run` on an emulator or physical device.

Once running, the initial screen shows login/register controls. After a
successful login you'll see a home page greeting you and listing all registered
users. A logout icon in the app bar will return you to the login screen.
and shown below the form.

Additional resources:

* [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
* [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environments

The app supports two entry-point based environments:

- `main`: production-like behavior, no dev-only premium toggle
- `dev`: developer behavior, premium toggle is always visible in Settings

Run commands:

```bash
flutter run -t lib/main.dart
flutter run -t lib/main_dev.dart
```

Build commands:

```bash
flutter build apk -t lib/main.dart --release
flutter build apk -t lib/main_dev.dart --release

flutter build ios -t lib/main.dart --release
flutter build ios -t lib/main_dev.dart --release
```

Notes:

- Builds from `lib/main_dev.dart` always expose the premium developer toggle in Settings.
- Builds from `lib/main.dart` never show that toggle.
- If later you want separate bundle identifiers/icons for dev and main, add native Android/iOS flavors on top of these entry points.

## Release Docs

- iOS signing checklist: [docs/ios-signing-checklist.md](/Users/ecegecit/development/ptrainer/docs/ios-signing-checklist.md)
- Full release checklist: [docs/release-checklist.md](/Users/ecegecit/development/ptrainer/docs/release-checklist.md)