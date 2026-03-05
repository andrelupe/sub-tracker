import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/settings/providers/settings_providers.dart';
import 'package:subtracker/features/subscriptions/widgets/analytics_banner.dart';

void main() {
  group('AnalyticsBanner', () {
    testWidgets('shows banner when analytics disabled and not dismissed',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
            analyticsBannerDismissedNotifierProvider
                .overrideWith(_NotDismissedBannerNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsBanner()),
          ),
        ),
      );

      expect(find.text('Track your spending trends'), findsOneWidget);
      expect(
        find.text('Enable Analytics in Settings to see charts and insights.'),
        findsOneWidget,
      );
      expect(find.text('Enable'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('shows analytics icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
            analyticsBannerDismissedNotifierProvider
                .overrideWith(_NotDismissedBannerNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsBanner()),
          ),
        ),
      );

      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('hides when analytics is enabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_EnabledAnalyticsNotifier.new),
            analyticsBannerDismissedNotifierProvider
                .overrideWith(_NotDismissedBannerNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsBanner()),
          ),
        ),
      );

      expect(find.text('Track your spending trends'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('hides when banner is dismissed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
            analyticsBannerDismissedNotifierProvider
                .overrideWith(_DismissedBannerNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsBanner()),
          ),
        ),
      );

      expect(find.text('Track your spending trends'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('tapping Enable calls setEnabled on analytics notifier',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
            analyticsBannerDismissedNotifierProvider
                .overrideWith(_NotDismissedBannerNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsBanner()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AnalyticsBanner)),
      );

      expect(container.read(analyticsEnabledNotifierProvider), false);

      await tester.tap(find.text('Enable'));
      await tester.pumpAndSettle();

      // After tapping Enable, analytics should be enabled and banner hidden
      expect(container.read(analyticsEnabledNotifierProvider), true);
      expect(find.text('Track your spending trends'), findsNothing);
    });

    testWidgets('tapping Dismiss calls dismiss on banner notifier',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
            analyticsBannerDismissedNotifierProvider
                .overrideWith(_NotDismissedBannerNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsBanner()),
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AnalyticsBanner)),
      );

      expect(
        container.read(analyticsBannerDismissedNotifierProvider),
        false,
      );

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // After tapping Dismiss, banner should be dismissed and hidden
      expect(
        container.read(analyticsBannerDismissedNotifierProvider),
        true,
      );
      expect(find.text('Track your spending trends'), findsNothing);
    });

    testWidgets('renders inside a Card with primaryContainer color',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsEnabledNotifierProvider
                .overrideWith(_DisabledAnalyticsNotifier.new),
            analyticsBannerDismissedNotifierProvider
                .overrideWith(_NotDismissedBannerNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AnalyticsBanner()),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final context = tester.element(find.byType(AnalyticsBanner));
      final expectedColor = Theme.of(context).colorScheme.primaryContainer;

      expect(card.color, expectedColor);
    });
  });
}

/// Fake notifier that returns analytics disabled (default state).
class _DisabledAnalyticsNotifier extends AnalyticsEnabledNotifier {
  @override
  bool build() => false;

  @override
  Future<void> setEnabled({required bool enabled}) async {
    state = enabled;
  }

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

/// Fake notifier that returns analytics enabled.
class _EnabledAnalyticsNotifier extends AnalyticsEnabledNotifier {
  @override
  bool build() => true;

  @override
  Future<void> setEnabled({required bool enabled}) async {
    state = enabled;
  }

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

/// Fake notifier that returns banner not dismissed.
class _NotDismissedBannerNotifier extends AnalyticsBannerDismissedNotifier {
  @override
  bool build() => false;

  @override
  Future<void> dismiss() async {
    state = true;
  }
}

/// Fake notifier that returns banner already dismissed.
class _DismissedBannerNotifier extends AnalyticsBannerDismissedNotifier {
  @override
  bool build() => true;

  @override
  Future<void> dismiss() async {
    state = true;
  }
}
