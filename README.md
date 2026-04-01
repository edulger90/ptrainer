# ptrainer

P-Trainer is the ultimate mobile solution designed specifically for personal trainers and fitness coaches who want to manage their clients, track progress, and streamline their daily workflow—all from a single, easy-to-use app.

With P-Trainer, you can:
• Effortlessly organize your weekly training schedule and view all your client sessions at a glance.
• Add, edit, and track detailed body measurements for each client, helping you monitor their progress and keep them motivated.
• Maintain comprehensive client profiles, including contact information, training history, and personalized notes.
• Record attendance, completed lessons, and session reasons (such as illness or holidays) to ensure accurate tracking and reporting.
• Assign and manage training periods, set goals, and visualize each client’s journey with clear progress indicators.
• Enjoy a modern, intuitive interface with support for multiple languages, including English, Turkish, Dutch, and Spanish.
• Secure your data with local storage and privacy-focused design—your client information stays safe and confidential.
• Easily export or share client progress and reports as needed.

Whether you work with a handful of clients or manage a large roster, P-Trainer adapts to your needs. The app is perfect for personal trainers, fitness coaches, and gym instructors who want to save time on admin tasks and focus more on what matters: helping clients achieve their goals.

Key Features:

Weekly and daily schedule management
Client database with detailed profiles
Body measurement tracking and history
Progress visualization and lesson completion stats
Attendance and session reason logging
Multi-language support
Secure, private, and easy to use
Take your coaching business to the next level with P-Trainer. Download now and experience the smarter way to manage your clients and grow your fitness career!

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