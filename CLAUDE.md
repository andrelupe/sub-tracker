# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

```bash
# Install dependencies
flutter pub get

# Generate Riverpod providers (run after modifying @riverpod annotated code)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run -d chrome          # Web (Chrome)
flutter run -d macos           # macOS desktop
flutter run                    # Connected device/emulator

# Run tests
flutter test                   # All tests
flutter test test/path/to/specific_test.dart  # Single test file

# Analyze code
flutter analyze
```

## Architecture

This is a Flutter app using **Vertical Slice Architecture** with feature-based organization. Each feature is self-contained with its own models, providers, screens, and widgets.

### State Management Pattern

Uses **Riverpod 2.x with code generation** for state management. The key pattern is:

1. **SubscriptionStore**: In-memory data store (single source of truth) that broadcasts changes via StreamController
2. **Data Providers**: Expose store data reactively (subscriptionsListProvider, activeSubscriptionsProvider)
3. **Computed Providers**: Derive state from data (monthlyTotalProvider, dueSoonSubscriptionsProvider)
4. **Notifier Provider**: SubscriptionNotifier handles all mutations (create, update, delete, toggle)

**Important**: After modifying store data, call `ref.invalidateSelf()` to notify all watchers. Providers use AutoDispose for automatic cleanup.

### Code Generation

The app relies heavily on code generation for Riverpod providers. Files with `@riverpod` annotations require:
- A `.g.dart` companion file (e.g., `subscription_providers.g.dart`)
- Running `build_runner` after changes
- Adding `part 'filename.g.dart';` directive at the top of the file

### Data Storage

**Critical**: Data is stored **in-memory only** and will be lost when the app closes. There is no persistence layer yet. Any feature requiring data persistence will need to add a database solution (Drift, Hive, or SharedPreferences).

### Navigation

Uses **GoRouter** with type-safe routing:
- Routes defined in `lib/core/router/app_router.dart`
- Route constants in `AppRoutes` class
- Navigate with `context.push()`, return with `context.pop()`
- Edit routes use path parameters: `/subscription/edit/:id`

### Key Models

**Subscription Model** (`lib/features/subscriptions/models/subscription.dart`):
- Immutable with `copyWith()` for updates
- Computed properties: `monthlyAmount`, `yearlyAmount`, `daysUntilNextBilling`, `isDueSoon`
- Uses UUID v4 for IDs
- Active/inactive state for pausing subscriptions

**BillingCycle Enum**: Contains logic for calculating next billing dates and normalizing amounts to monthly/yearly equivalents.

**SubscriptionCategory Enum**: 10 predefined categories, each with an associated icon and color.

### Date Handling

**DateTimeX Extension** (`lib/core/extensions/datetime_extensions.dart`) provides:
- `addMonths(int)` / `addYears(int)` with proper overflow handling
- `formatted` for consistent date display (dd MMM yyyy)
- `daysFromNow` for calculating days until a date
- `isToday` for date comparison

Use these extensions for all date calculations to maintain consistency across the app.

### UI Patterns

- Material Design 3 with Google Inter font
- Theme defined in `lib/core/theme/app_theme.dart`
- Primary color: Indigo (#6366F1)
- 12px border radius throughout
- Category colors are semantic (defined in enum)
- "Due Soon" is highlighted in red (subscriptions due within 7 days)

### Form Handling

**SubscriptionFormScreen** supports both create and edit modes:
- Edit mode: Pre-populated with existing subscription data, shows delete and active toggle
- Create mode: Empty form with sensible defaults
- Amount input accepts both `.` and `,` as decimal separators
- Date picker for start date selection
- Form validation: name required, amount > 0

## Common Patterns

### Adding a New Provider

1. Add `@riverpod` annotation to function/class
2. Add `part 'filename.g.dart';` directive if not present
3. Run `dart run build_runner build --delete-conflicting-outputs`
4. Use generated provider in UI with `ref.watch(yourProvider)`

### Adding a New Feature

Follow the vertical slice pattern:
```
lib/features/your_feature/
├── models/       # Data models
├── providers/    # State management
├── screens/      # Full-screen UI
└── widgets/      # Reusable components
```

### Modifying Subscription Logic

1. Update the model in `lib/features/subscriptions/models/subscription.dart`
2. If changing computed properties, verify impact on providers
3. Update SubscriptionNotifier if adding new mutations
4. Run tests to ensure billing calculations remain correct
5. Re-generate code if needed

## Testing

Test files exist for:
- Models: Billing calculations, date logic, computed properties
- Extensions: DateTime manipulation

Run tests before committing changes to verify billing logic and date calculations.
