# SubTracker

A Flutter app for tracking subscriptions and recurring payments.

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run on Chrome (use fixed port for data persistence)
flutter run -d chrome --web-port=3000

# Run on macOS (requires Xcode)
flutter run -d macos
```

> **Note:** On web, always use `--web-port=3000` to ensure data persists between sessions. Each port has isolated storage.

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

## Data Persistence

Data is persisted locally using Hive (IndexedDB on web). On web, use a fixed port (`--web-port=3000`) to ensure data persists between sessions.
