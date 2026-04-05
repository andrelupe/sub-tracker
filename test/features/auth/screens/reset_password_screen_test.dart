import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/auth/screens/reset_password_screen.dart';
import 'package:subtracker/features/auth/services/auth_api_service.dart';

void main() {
  Widget buildSubject({AuthApiService? authApi}) {
    return ProviderScope(
      overrides: [
        if (authApi != null) authApiServiceProvider.overrideWithValue(authApi),
      ],
      child: const MaterialApp(
        home: ResetPasswordScreen(),
      ),
    );
  }

  group('ResetPasswordScreen', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Reset Token'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });

    testWidgets('renders reset button', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Reset Password'), findsWidgets);
    });

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(buildSubject());

      // The heading "Reset Password" appears in both title and button.
      expect(find.text('Reset Password'), findsWidgets);
      expect(
        find.text('Enter the reset token from your admin'),
        findsOneWidget,
      );
    });

    testWidgets('renders back to login link', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Back to login'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap the button (first widget with that text that is tappable).
      await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter the reset token'), findsOneWidget);
      expect(find.text('Please enter a new password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'not-valid',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'short',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        'different456',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('does not show errors for valid input', (tester) async {
      // Use a fake that succeeds to avoid real API calls.
      final fakeApi = _FakeAuthApiService();
      await tester.pumpWidget(buildSubject(authApi: fakeApi));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Reset Token'),
        'abc-token-123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        'newpassword1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        'newpassword1',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Reset Password'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
      expect(find.text('Please enter the reset token'), findsNothing);
      expect(find.text('Please enter a new password'), findsNothing);
      expect(
        find.text('Password must be at least 8 characters'),
        findsNothing,
      );
      expect(find.text('Passwords do not match'), findsNothing);
    });
  });
}

/// Minimal fake that only overrides [resetPassword] to avoid real HTTP.
class _FakeAuthApiService extends AuthApiService {
  _FakeAuthApiService() : super(ApiService(baseUrl: 'http://fake'));

  @override
  Future<void> resetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    // No-op for testing.
  }
}
