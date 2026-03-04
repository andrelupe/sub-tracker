import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
import 'package:subtracker/features/analytics/widgets/period_selector.dart';

void main() {
  group('PeriodSelector', () {
    testWidgets('renders all three period segments', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsPeriodProvider.overrideWith(_FakePeriod.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PeriodSelector()),
          ),
        ),
      );

      expect(find.text('3M'), findsOneWidget);
      expect(find.text('6M'), findsOneWidget);
      expect(find.text('12M'), findsOneWidget);
    });

    testWidgets('defaults to 6 months selected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsPeriodProvider.overrideWith(_FakePeriod.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PeriodSelector()),
          ),
        ),
      );

      // The SegmentedButton should have 6M selected by default.
      // We verify this by checking the Semantics label.
      expect(find.bySemanticsLabel(RegExp('6 months')), findsOneWidget);
    });

    testWidgets('tapping 3M changes period to 3', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsPeriodProvider.overrideWith(_FakePeriod.new),
          ],
          child: Builder(
            builder: (context) {
              return const MaterialApp(
                home: Scaffold(body: PeriodSelector()),
              );
            },
          ),
        ),
      );

      container = ProviderScope.containerOf(
        tester.element(find.byType(PeriodSelector)),
      );

      // Verify initial state is 6
      expect(container.read(analyticsPeriodProvider), 6);

      // Tap the 3M segment
      await tester.tap(find.text('3M'));
      await tester.pumpAndSettle();

      expect(container.read(analyticsPeriodProvider), 3);
    });

    testWidgets('tapping 12M changes period to 12', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsPeriodProvider.overrideWith(_FakePeriod.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PeriodSelector()),
          ),
        ),
      );

      container = ProviderScope.containerOf(
        tester.element(find.byType(PeriodSelector)),
      );

      // Tap the 12M segment
      await tester.tap(find.text('12M'));
      await tester.pumpAndSettle();

      expect(container.read(analyticsPeriodProvider), 12);
    });

    testWidgets('switching from 3M to 6M updates provider', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsPeriodProvider
                .overrideWith(() => _FakePeriodWithInitial(3)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PeriodSelector()),
          ),
        ),
      );

      container = ProviderScope.containerOf(
        tester.element(find.byType(PeriodSelector)),
      );

      expect(container.read(analyticsPeriodProvider), 3);

      // Tap the 6M segment
      await tester.tap(find.text('6M'));
      await tester.pumpAndSettle();

      expect(container.read(analyticsPeriodProvider), 6);
    });
  });
}

class _FakePeriod extends AnalyticsPeriod {
  @override
  int build() => 6;
}

class _FakePeriodWithInitial extends AnalyticsPeriod {
  _FakePeriodWithInitial(this._initial);

  final int _initial;

  @override
  int build() => _initial;
}
