# SubTracker

A Flutter app for tracking subscriptions and recurring payments.

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run on Chrome
flutter run -d chrome

# Run on macOS (requires Xcode)
flutter run -d macos
```

## Features

- Track subscriptions with name, amount, and billing cycle
- View monthly and yearly spending totals
- See subscriptions due soon
- Swipe to pause or delete subscriptions

## Architecture

Simple Vertical Slices with Riverpod for state management.

```
lib/
├── core/
│   ├── extensions/
│   ├── router/
│   └── theme/
├── features/
│   └── subscriptions/
│       ├── models/
│       ├── providers/
│       ├── screens/
│       └── widgets/
└── main.dart
```

## Note

Data is stored in memory and will be lost when the app closes. For persistent storage, you'll need to add a database (e.g., Drift, Hive, SharedPreferences).
