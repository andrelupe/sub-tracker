import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/models/auth_state.dart';
import 'package:subtracker/features/auth/models/user_profile.dart';
import 'package:subtracker/features/auth/providers/auth_providers.dart';
import 'package:subtracker/features/auth/services/token_storage_service.dart';
import 'package:subtracker/features/settings/widgets/account_section.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeTokenStorageService extends TokenStorageService {
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> clearTokens() async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _regularUser = UserProfile(
  id: 'user-1',
  email: 'user@example.com',
  role: 'User',
);

const _adminUser = UserProfile(
  id: 'admin-1',
  email: 'admin@example.com',
  role: 'Admin',
);

Widget _buildSubject({required UserProfile user}) {
  final authState = AuthState(
    status: AuthStatus.authenticated,
    user: user,
    accessToken: 'test-token',
  );

  return ProviderScope(
    overrides: [
      tokenStorageServiceProvider.overrideWithValue(_FakeTokenStorageService()),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(authState)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: AccountSection())),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AccountSection', () {
    testWidgets('renders section title "Account"', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      expect(find.text('Account'), findsOneWidget);
    });

    testWidgets('renders user email', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('renders "User" role badge for regular user', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      expect(find.text('User'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('renders "Admin" role badge for admin user', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _adminUser));

      expect(find.text('Admin'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('renders admin email', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _adminUser));

      expect(find.text('admin@example.com'), findsOneWidget);
    });

    testWidgets('renders Change Password button', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      expect(find.text('Change Password'), findsOneWidget);
    });

    testWidgets('renders Logout button with error colour', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('tapping Change Password opens dialog', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
    });

    testWidgets('tapping Logout opens confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // The dialog also contains a Logout button.
      expect(find.widgetWithText(FilledButton, 'Logout'), findsOneWidget);
    });

    testWidgets('renders nothing when user is null', (tester) async {
      const authState = AuthState(status: AuthStatus.unauthenticated);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageServiceProvider
                .overrideWithValue(_FakeTokenStorageService()),
            authNotifierProvider
                .overrideWith(() => _FakeAuthNotifier(authState)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AccountSection()),
          ),
        ),
      );

      // Should render an empty SizedBox.
      expect(find.text('Account'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('is wrapped in a Card', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders email and badge icons', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });
}
