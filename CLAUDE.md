# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Flutter Frontend

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

### .NET Backend

```bash
# Run API (from api/src/SubTracker.Api)
dotnet run

# Run tests (from api/)
dotnet test

# Add EF Core migration (from api/src/SubTracker.Api)
dotnet ef migrations add MigrationName
```

## Architecture

This is a **client-server application** with a Flutter frontend and .NET API backend.

### Data Flow

```
Flutter UI → Riverpod AsyncNotifier → HTTP API Service → .NET FastEndpoints → SQLite
```

All data is managed by the API. The Flutter app has **no local storage** — it is a pure frontend client.

### Frontend State Management Pattern

Uses **Riverpod 2.x with code generation** and **async providers** for API integration:

1. **ApiService** (`lib/core/services/api_service.dart`): Generic HTTP client with error handling
2. **SubscriptionApiService** (`lib/features/subscriptions/services/`): Subscription-specific API methods
3. **SubscriptionsNotifier** (AsyncNotifier): Manages subscription state with API calls for all CRUD operations
4. **Derived Providers**: Compute monthly/yearly totals, due soon list, filtered results from async state
5. **Filter/Sort Providers**: Client-side search, category filter, and sorting

**Key pattern**: The `SubscriptionsNotifier` extends `AsyncNotifier<List<Subscription>>`. All mutations (`create`, `updateSubscription`, `delete`, `toggleActive`) are async and call the API, then refresh state via `ref.invalidateSelf()`.

### Backend Architecture

Uses **FastEndpoints** (not controllers) with **Vertical Slice Architecture**:

- Each endpoint is a self-contained class under `Features/`
- Domain model (`Subscription`) uses a rich domain pattern with private setters and factory methods
- `Subscription.Create()` static factory generates IDs, calculates next billing date, sets timestamps
- `DatabaseSeeder` seeds 12 dummy subscriptions in Development mode only

### Environment Configuration

The API base URL is loaded at runtime from a `.env` file using `flutter_dotenv`:

```env
API_BASE_URL=http://localhost:5270/api
```

This is read via `AppConstants.apiBaseUrl` in `lib/core/constants/app_constants.dart`. The `.env` file is declared as a Flutter asset in `pubspec.yaml` and loaded in `main.dart` before app startup.

### Code Generation

The app relies on code generation for Riverpod providers. Files with `@riverpod` annotations require:
- A `.g.dart` companion file (e.g., `subscription_providers.g.dart`)
- Running `build_runner` after changes
- Adding `part 'filename.g.dart';` directive at the top of the file

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
- JSON serialization: `fromJson()` and `toJson()` for API communication
- Fields: `id`, `name`, `description`, `amount`, `currency`, `billingCycle`, `category`, `startDate`, `nextBillingDate`, `isActive`, `url`, `reminderDaysBefore`, `createdAt`, `updatedAt`

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
- "Due Soon" configurable via `reminderDaysBefore` (default: 2 days)
- AsyncValue `.when()` pattern for loading/error/data states in UI

### Error Handling

- **API errors**: `ApiException` and `ValidationException` classes in `api_service.dart`
- **UI errors**: SnackBars for operation failures, retry buttons for load failures
- **Async safety**: `mounted` checks before `setState` or navigation after async operations
- **Form validation**: Flutter's built-in form validation with validators

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
├── models/       # Data models with fromJson/toJson
├── providers/    # AsyncNotifier + derived providers
├── screens/      # Full-screen UI with AsyncValue handling
├── services/     # API service for HTTP calls
└── widgets/      # Reusable components
```

### Adding a New API Endpoint (Backend)

1. Create endpoint class under `Features/YourFeature/`
2. Extend `Endpoint<TRequest, TResponse>` from FastEndpoints
3. Add FluentValidation rules in the `Validator` inner class
4. Register route in `Configure()` method

### Modifying Subscription Logic

1. Update the model in `lib/features/subscriptions/models/subscription.dart`
2. Update `fromJson()`/`toJson()` if fields change
3. Update the backend `Subscription` entity and endpoint DTOs
4. Add EF Core migration if database schema changes
5. If changing computed properties, verify impact on derived providers
6. Update SubscriptionsNotifier if adding new mutations
7. Run both Flutter and .NET tests

## Testing

### Flutter Tests (51 tests)
- Models: Billing calculations, date logic, computed properties
- Providers: Filter/sort logic, search, category filtering
- Extensions: DateTime manipulation

### .NET Tests (8 tests)
- Domain: Subscription creation, update, IsDueSoon, next billing date calculation

Run tests before committing changes:
```bash
flutter test && cd api && dotnet test
```
