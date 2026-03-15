---
name: gen-test-dart
description: Generate Flutter/Dart tests following the project's testing patterns
user-invocable: true
disable-model-invocation: false
---

# Generate Dart Tests

Generate tests for Flutter/Dart source files following this project's conventions.

## Arguments

The user specifies source files or features to test.

## Steps

1. Read the source file(s) to understand the code
2. Read 1-2 existing test files of the same type (model, provider, widget, service) to match patterns
3. Generate the test file
4. Run `flutter test <new_test_file>` to verify it passes

## Test File Location

Mirror `lib/` structure under `test/`, append `_test.dart`:
- `lib/features/subscriptions/models/subscription.dart` → `test/features/subscriptions/models/subscription_test.dart`

## Conventions

### Structure

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClassName', () {
    test('descriptive behavior name', () {
      // Arrange → Act → Assert
    });
  });
}
```

### Naming

- Descriptive English: `'returns empty list when no matches'`
- Nested `group()` for logical grouping by method/behavior

### Model Tests

- Direct instantiation, no dependencies
- `closeTo(value, tolerance)` for floats
- Common matchers: `equals()`, `isTrue`, `isFalse`, `isEmpty`, `contains()`, `hasLength()`

### Provider Tests

- `ProviderContainer` with `overrides`, `dispose()` in `tearDown`
- Fake async notifiers extending the real class, overriding `build()`:

```dart
class _FakeSubscriptionsNotifier extends SubscriptionsNotifier {
  _FakeSubscriptionsNotifier(this._subscriptions);
  final List<Subscription> _subscriptions;
  @override
  Future<List<Subscription>> build() async => _subscriptions;
}
```

- Override: `provider.overrideWith(() => _FakeNotifier(data))`
- Await async: `await container.read(provider.future)`

### Widget Tests

```dart
testWidgets('description', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [/* overrides */],
      child: const MaterialApp(home: Scaffold(body: YourWidget())),
    ),
  );
  expect(find.text('Expected'), findsOneWidget);
});
```

- State checks: `ProviderScope.containerOf(tester.element(find.byType(Widget)))`

### Service Tests

- `MockClient` from `package:http/testing.dart`, injected into service constructor

### Rules

- Do NOT use Mockito — manual fakes and `MockClient` only
- Each test file is self-contained (no shared utility files)
- AAA pattern: Arrange → Act → Assert
- `flutter_test` matchers only
