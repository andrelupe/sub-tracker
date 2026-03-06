import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/settings/providers/settings_providers.dart';
import 'package:subtracker/features/settings/widgets/analytics_toggle.dart';

void main() {
  group('AnalyticsToggle', () {
    testWidgets('renders section title "Features"', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsToggle()),
          ),
        ),
      );

      expect(find.text('Features'), findsOneWidget);
    });

    testWidgets('renders toggle with title and subtitle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsToggle()),
          ),
        ),
      );

      expect(find.text('Analytics'), findsOneWidget);
      expect(
        find.text('Show spending charts and statistics'),
        findsOneWidget,
      );
    });

    testWidgets('shows analytics icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsToggle()),
          ),
        ),
      );

      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('switch is off when analytics is disabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsToggle()),
          ),
        ),
      );

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );

      expect(switchTile.value, false);
    });

    testWidgets('switch is on when analytics is enabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_EnabledAnalyticsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsToggle()),
          ),
        ),
      );

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );

      expect(switchTile.value, true);
    });

    testWidgets('tapping toggle changes state from disabled to enabled',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsToggle()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AnalyticsToggle)),
      );

      expect(container.read(analyticsEnabledNotifierProvider), false);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(container.read(analyticsEnabledNotifierProvider), true);
    });

    testWidgets('tapping toggle changes state from enabled to disabled',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_EnabledAnalyticsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsToggle()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AnalyticsToggle)),
      );

      expect(container.read(analyticsEnabledNotifierProvider), true);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(container.read(analyticsEnabledNotifierProvider), false);
    });

    testWidgets('is wrapped in a Card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsToggle()),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}

/// Fake notifier that returns analytics disabled.
class _DisabledAnalyticsNotifier extends AnalyticsEnabledNotifier {
  @override
  bool build() => false;

  @override
  Future<void> toggle() async {
    state = !state;
  }

  @override
  Future<void> setEnabled({required bool enabled}) async {
    state = enabled;
  }
}

/// Fake notifier that returns analytics enabled.
class _EnabledAnalyticsNotifier extends AnalyticsEnabledNotifier {
  @override
  bool build() => true;

  @override
  Future<void> toggle() async {
    state = !state;
  }

  @override
  Future<void> setEnabled({required bool enabled}) async {
    state = enabled;
  }
}
