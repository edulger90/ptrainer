# iOS Signing Checklist

Use this checklist before creating an App Store IPA for P-Trainer.

## 1. Apple Account

- Confirm you have an active Apple Developer Program membership.
- Open Xcode.
- Go to `Xcode > Settings > Accounts`.
- Add the Apple ID that owns or has access to the app.

## 2. Open The Workspace

- Open [ios/Runner.xcworkspace](/Users/ecegecit/development/ptrainer/ios/Runner.xcworkspace) in Xcode.
- Do not use `Runner.xcodeproj` for signing or CocoaPods-based archive flows.

## 3. Runner Signing Setup

- Select the `Runner` project.
- Select the `Runner` target.
- Open `Signing & Capabilities`.
- Set `Team` to your Apple Developer team.
- Enable `Automatically manage signing`.
- Verify bundle identifier is `com.edlgr.ptrainer`.

## 4. Release Configuration

- Check both `Debug` and `Release` signing sections.
- Ensure the selected team is the same in `Release`.
- Make sure Xcode can create or download an `Apple Distribution` certificate.
- Make sure a provisioning profile exists for `com.edlgr.ptrainer`.

## 5. App Store Connect

- Create the app in App Store Connect if it does not exist yet.
- Use the same bundle identifier: `com.edlgr.ptrainer`.
- Fill in app metadata, age rating, privacy details, and screenshots.

## 6. Versioning

- Update the version in [pubspec.yaml](/Users/ecegecit/development/ptrainer/pubspec.yaml).
- Increase the build number for every upload.

## 7. Build And Archive

- Flutter archive command:

```bash
flutter build ipa -t lib/main.dart --release
```

- If export fails, open the generated archive in Xcode Organizer:

```bash
open /Users/ecegecit/development/ptrainer/build/ios/archive/Runner.xcarchive
```

## 8. Upload

- In Organizer, choose `Distribute App`.
- Select `App Store Connect`.
- Upload the archive.
- Wait for processing in App Store Connect.
- Release first to TestFlight, then to App Store.

## Common Errors

- `No Accounts`: Apple ID is not added in Xcode.
- `No signing certificate "iOS Distribution" found`: distribution certificate is missing.
- `No profiles for 'com.edlgr.ptrainer' were found`: provisioning profile is missing or bundle ID does not match.