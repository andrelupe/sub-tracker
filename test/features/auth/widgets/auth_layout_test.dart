import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/widgets/auth_layout.dart';

void main() {
  group('AuthLayout', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            child: Text('Test Content'),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('wraps content in Scaffold', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            child: Text('Content'),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('constrains content to max 400px width', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            child: Text('Content'),
          ),
        ),
      );

      final constrainedBoxes =
          tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      expect(
        constrainedBoxes.any((box) => box.constraints.maxWidth == 400),
        isTrue,
      );
    });

    testWidgets('uses SingleChildScrollView for scrolling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            child: Text('Content'),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('centers content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            child: Text('Content'),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('shows Card on desktop width', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            child: Text('Desktop Content'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Desktop Content'), findsOneWidget);
    });

    testWidgets('does not show Card on mobile width', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            child: Text('Mobile Content'),
          ),
        ),
      );

      expect(find.byType(Card), findsNothing);
      expect(find.text('Mobile Content'), findsOneWidget);
    });

    testWidgets('does not show Card on tablet width', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthLayout(
            child: Text('Tablet Content'),
          ),
        ),
      );

      expect(find.byType(Card), findsNothing);
      expect(find.text('Tablet Content'), findsOneWidget);
    });
  });
}
