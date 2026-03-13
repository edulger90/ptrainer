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
