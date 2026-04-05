import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/screens/login_screen.dart';

void main() {
  Widget buildSubject() {
    return const ProviderScope(
      child: MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders login button', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('renders app title', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('SubTracker'), findsOneWidget);
      expect(find.text('Sign in to your account'), findsOneWidget);
    });

    testWidgets('renders register and forgot password links', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(
        find.text("Don't have an account? Register"),
        findsOneWidget,
      );
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap Login without entering anything.
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'not-an-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'somepassword',
      );

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('does not show errors for valid input', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(find.text('Please enter your password'), findsNothing);
    });
  });
}
