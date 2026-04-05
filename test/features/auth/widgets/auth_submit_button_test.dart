import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/widgets/auth_submit_button.dart';

void main() {
  group('AuthSubmitButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSubmitButton(
              onPressed: () {},
              label: 'Login',
            ),
          ),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('renders loading state with loadingLabel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSubmitButton(
              onPressed: () {},
              label: 'Login',
              loadingLabel: 'Signing in...',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.text('Signing in...'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows default loadingLabel when not specified',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSubmitButton(
              onPressed: () {},
              label: 'Submit',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.text('Please wait...'), findsOneWidget);
    });

    testWidgets('is disabled when loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSubmitButton(
              onPressed: () => pressed = true,
              label: 'Login',
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('is enabled when not loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSubmitButton(
              onPressed: () => pressed = true,
              label: 'Login',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('is full width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AuthSubmitButton(
                onPressed: () {},
                label: 'Login',
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, double.infinity);
    });

    testWidgets('has Tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSubmitButton(
              onPressed: () {},
              label: 'Login',
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('has Semantics with button role', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthSubmitButton(
              onPressed: () {},
              label: 'Login',
            ),
          ),
        ),
      );

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthSubmitButton(
              onPressed: null,
              label: 'Login',
            ),
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
