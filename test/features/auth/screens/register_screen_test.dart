import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/screens/register_screen.dart';

void main() {
  Widget buildSubject() {
    return const ProviderScope(
      child: MaterialApp(
        home: RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Invite Code'), findsOneWidget);
    });

    testWidgets('renders register button', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Create Account'), findsOneWidget);
      expect(
        find.text('Register to start tracking subscriptions'),
        findsOneWidget,
      );
    });

    testWidgets('renders login link', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(
        find.text('Already have an account? Login'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
      expect(find.text('Please enter an invite code'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bad-email',
      );

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'short',
      );

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'different456',
      );

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
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
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Invite Code'),
        'ABC-123',
      );

      await tester.tap(find.text('Register'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(find.text('Please enter a password'), findsNothing);
      expect(
        find.text('Password must be at least 8 characters'),
        findsNothing,
      );
      expect(find.text('Passwords do not match'), findsNothing);
      expect(find.text('Please enter an invite code'), findsNothing);
    });
  });
}
