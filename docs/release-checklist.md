# Release Checklist

This checklist covers production releases for both Google Play and App Store.

## 1. Pre-Release

- Verify store build uses [lib/main.dart](/Users/ecegecit/development/ptrainer/lib/main.dart), not `lib/main_dev.dart`.
- Update version and build number in [pubspec.yaml](/Users/ecegecit/development/ptrainer/pubspec.yaml).
- Confirm premium dev toggle is not visible in the main environment.
- Run the critical app flows on a real device.

## 2. Android Release

### Build

```bash
flutter build appbundle -t lib/main.dart --release
```

### Output

- Upload the generated AAB from:
- [build/app/outputs/bundle/release/app-release.aab](/Users/ecegecit/development/ptrainer/build/app/outputs/bundle/release/app-release.aab)

### Google Play Console

- Open Play Console.
- Create a new release in `Internal testing` or `Closed testing` first.
- Upload the `.aab` file.
- Add release notes.
- Review and roll out.

## 3. iOS Release

### Build

```bash
flutter build ipa -t lib/main.dart --release
```

### If Export Fails

- Open the archive in Xcode Organizer:

```bash
open /Users/ecegecit/development/ptrainer/build/ios/archive/Runner.xcarchive
```

- Complete export or upload from Xcode.

### App Store Connect

- Upload to TestFlight first.
- Validate metadata, screenshots, privacy policy, and app review details.
- Submit for review after internal testing is complete.

## 4. Dev Environment Builds

Use these only for internal testing or feature verification.

### Android Dev Build

```bash
flutter build appbundle -t lib/main_dev.dart --release
```

### iOS Dev Build

```bash
flutter build ipa -t lib/main_dev.dart --release
```

## 5. Final Verification

- Main build starts with production environment.
- Bundle identifiers are correct.
- Version/build number matches store upload.
- Signing is valid.
- No generated build artifacts are staged in git.