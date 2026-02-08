# AGENTS.md

Guidelines for AI coding agents working in this Flutter + .NET subscription tracking app.

## Build, Lint, and Test Commands

### Flutter Frontend

```bash
# Install dependencies
flutter pub get

# Run code generation (required after modifying @riverpod annotations)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run -d chrome          # Web (Chrome)
flutter run -d macos           # macOS desktop
flutter run                    # Default device/emulator

# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/file_test.dart

# Run tests matching a name pattern
flutter test --name "pattern"

# Run tests in a specific directory
flutter test test/features/subscriptions/

# Analyze code (linting)
flutter analyze

# Format code
dart format .
```

### .NET Backend

```bash
# Run API (from api/src/SubTracker.Api)
dotnet run                     # Starts on http://localhost:5270

# Run tests (from api/)
dotnet test

# Build
dotnet build

# Add EF Core migration (from api/src/SubTracker.Api)
dotnet ef migrations add MigrationName

# Docker
cd api && docker-compose up -d
```

## Architecture Overview

**Client-server application** with Flutter frontend consuming a .NET REST API.

### Data Flow

```
Flutter UI → Riverpod AsyncNotifier → HTTP API Service → .NET FastEndpoints → SQLite
```

### Frontend Structure

**Vertical Slice Architecture** - Features are self-contained modules:
```
lib/
├── core/                    # Shared utilities
│   ├── constants/           # App constants + env config
│   ├── extensions/          # DateTime extension methods
│   ├── providers/           # API service Riverpod providers
│   ├── router/              # GoRouter configuration
│   ├── services/            # Generic HTTP API client
│   └── theme/               # Material 3 theming
└── features/
    └── subscriptions/       # Feature module
        ├── models/          # Data models (Subscription, BillingCycle, Category)
        ├── providers/       # Async Riverpod state management
        ├── screens/         # Full-screen widgets
        ├── services/        # Subscription API service
        └── widgets/         # Reusable components
```

### Backend Structure

```
api/
├── src/SubTracker.Api/
│   ├── Common/              # Shared abstractions (IDateTimeProvider, INotificationService)
│   ├── Database/            # EF Core DbContext + DatabaseSeeder
│   ├── Features/
│   │   ├── Subscriptions/   # CRUD endpoints + Domain + DTOs
│   │   └── Notifications/   # Pushover + Background Jobs
│   ├── Migrations/          # EF Core migrations
│   └── Program.cs
└── tests/SubTracker.Api.Tests/
```

**State Management**: Riverpod 2.x with code generation (`@riverpod` annotations) using AsyncNotifier for API integration.

**Data Storage**: SQLite via Entity Framework Core. No local storage in Flutter — all data flows through the API.

**Environment Configuration**: API base URL loaded from `.env` file at runtime via `flutter_dotenv`.

## Code Style Guidelines

### Imports

- Use package imports exclusively: `import 'package:subtracker/...'`
- No relative imports (avoid `import '../...'`)
- Order: Flutter SDK, external packages, internal packages
- One import per line

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/core/router/app_router.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
```

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Files | snake_case | `subscription_list_tile.dart` |
| Generated files | `<source>.g.dart` | `subscription_providers.g.dart` |
| Test files | `<source>_test.dart` | `subscription_test.dart` |
| Classes/Enums | PascalCase | `SubscriptionCategory` |
| Widgets | PascalCase + purpose suffix | `HomeScreen`, `SubscriptionListTile` |
| Private classes | _PascalCase | `_EmptyState`, `_SummaryItem` |
| Functions/Methods | camelCase | `calculateTotal()` |
| Private methods | _camelCase | `_selectDate()`, `_save()` |
| Variables | camelCase | `nextBillingDate` |
| Private fields | _camelCase | `_subscriptions`, `_controller` |
| Controllers | suffix with Controller | `_nameController` |
| Providers | suffix with Provider | `subscriptionsListProvider` |
| Notifiers | suffix with Notifier | `SubscriptionNotifier` |
| Boolean getters | prefix with `is` | `isActive`, `isDueSoon` |

### Type Annotations

- All class fields must have explicit types
- Method return types must be explicit
- Local variables use `final` or `var` with type inference
- Nullable types marked with `?`: `String? description`
- Use null-aware operators: `existing?.copyWith()`, `value ?? ''`

```dart
// Class fields - explicit types
final String id;
final String? description;
final double amount;

// Method signatures - explicit return types
double get monthlyAmount => billingCycle.monthlyEquivalent(amount);
DateTime addMonths(int months) { ... }

// Local variables - type inference
final api = ref.read(subscriptionApiServiceProvider);
```

### Formatting

- Uses `very_good_analysis` linting (strict rules)
- No line length limit enforced
- Single quotes for strings: `'text'`
- Prefer `const` constructors
- Prefer `final` for local variables
- Trailing commas for multi-line parameter lists

### Widget Patterns

- Use `ConsumerWidget` for Riverpod widgets
- Use `ConsumerStatefulWidget` for stateful widgets with Riverpod
- Use `super.key` constructor syntax: `const MyWidget({super.key})`
- Create private widgets for screen-specific components
- Use `AsyncValue.when()` for handling loading/error/data states

```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsNotifierProvider);
    
    return subscriptionsAsync.when(
      data: (subscriptions) => ListView(...),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

### Error Handling

- Use Flutter's form validation for user input
- Use null safety guards with conditional checks
- Check `mounted` before `setState` after async operations
- Use confirmation dialogs for destructive actions
- Show SnackBars for API error feedback
- Use try/catch with `ApiException` for HTTP errors

```dart
// Async API call with error handling
Future<void> _save() async {
  setState(() => _isLoading = true);
  try {
    await notifier.create(...);
    if (mounted) context.pop();
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### Riverpod Patterns

- Use `ref.watch()` for reactive state in build methods
- Use `ref.read()` for one-time reads in callbacks
- Use `AsyncNotifier` for providers that interact with the API
- Call `ref.invalidateSelf()` after mutations to refresh state
- Add `part 'filename.g.dart';` directive for code generation

```dart
// Watching async state
final subscriptionsAsync = ref.watch(subscriptionsNotifierProvider);

// Mutations in callbacks (async)
onPressed: () async {
  await ref.read(subscriptionsNotifierProvider.notifier).delete(id);
}
```

### Model Classes

- Immutable with all `final` fields
- Include `copyWith()` method for updates
- Include `fromJson()` / `toJson()` for API serialization
- Use computed getters for derived properties
- Use enums with enhanced features (properties and methods)

## Testing

Tests mirror the `lib/` directory structure in `test/`.

```dart
void main() {
  group('ClassName', () {
    late Type variable;
    
    setUp(() {
      // Initialize test fixtures
    });
    
    test('behavior description', () {
      expect(result, expectedValue);
    });
  });
}
```

Common matchers: `equals()`, `closeTo(value, delta)`, `isTrue`, `isFalse`

**Run both test suites before committing:**
```bash
flutter test && cd api && dotnet test
```

## UI Constants

- Border radius: 12px
- Content padding: 16px
- Section spacing: 24px
- Primary color: Indigo (#6366F1)
- "Due Soon" indicator: Red (configurable via `reminderDaysBefore`, default: 2 days)

## Code Generation Workflow

After modifying files with `@riverpod` annotations:
1. Ensure `part 'filename.g.dart';` directive exists
2. Run `dart run build_runner build --delete-conflicting-outputs`
3. Verify generated `.g.dart` file is created/updated

## Environment Setup

1. Copy `.env.example` to `.env`
2. Adjust `API_BASE_URL` if the backend runs on a different port/host
3. The `.env` file is declared as a Flutter asset and loaded at runtime
