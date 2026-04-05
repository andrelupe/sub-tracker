import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/auth/models/auth_state.dart';
import 'package:subtracker/features/auth/models/auth_tokens.dart';
import 'package:subtracker/features/auth/models/invite_code.dart';
import 'package:subtracker/features/auth/models/user_profile.dart';
import 'package:subtracker/features/auth/providers/auth_providers.dart';
import 'package:subtracker/features/auth/services/auth_api_service.dart';
import 'package:subtracker/features/auth/services/token_storage_service.dart';
import 'package:subtracker/features/settings/widgets/admin_section.dart';

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

class _FakeAuthApiService extends AuthApiService {
  _FakeAuthApiService() : super(ApiService(baseUrl: 'http://fake'));

  String? generatedCode;
  List<InviteCode> inviteCodes = [];

  @override
  Future<String> createInviteCode() async {
    return generatedCode ?? 'INVITE-123';
  }

  @override
  Future<List<InviteCode>> listInviteCodes() async {
    return inviteCodes;
  }

  @override
  Future<AuthTokens> login(String email, String password) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthTokens> register(
    String email,
    String password, [
    String? inviteCode,
  ]) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(String refreshToken) async {}

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}

  @override
  Future<String> requestPasswordReset(String email) async {
    return 'RESET-TOKEN-XYZ';
  }
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

Widget _buildSubject({
  required UserProfile user,
  _FakeAuthApiService? authApi,
}) {
  final authState = AuthState(
    status: AuthStatus.authenticated,
    user: user,
    accessToken: 'test-token',
  );

  return ProviderScope(
    overrides: [
      tokenStorageServiceProvider.overrideWithValue(_FakeTokenStorageService()),
      authNotifierProvider.overrideWith(() => _FakeAuthNotifier(authState)),
      authApiServiceProvider
          .overrideWithValue(authApi ?? _FakeAuthApiService()),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: AdminSection())),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AdminSection', () {
    testWidgets('renders nothing for regular user', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _regularUser));
      await tester.pumpAndSettle();

      expect(find.text('Administration'), findsNothing);
      expect(find.text('Invite Codes'), findsNothing);
    });

    testWidgets('renders section title for admin', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _adminUser));
      await tester.pumpAndSettle();

      expect(find.text('Administration'), findsOneWidget);
    });

    testWidgets('renders invite codes subsection for admin', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _adminUser));
      await tester.pumpAndSettle();

      expect(find.text('Invite Codes'), findsOneWidget);
      expect(find.text('Generate Invite Code'), findsOneWidget);
    });

    testWidgets('renders password reset subsection for admin', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _adminUser));
      await tester.pumpAndSettle();

      expect(find.text('Password Reset'), findsOneWidget);
      expect(find.text('Reset User Password'), findsOneWidget);
    });

    testWidgets('shows empty state when no invite codes', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _adminUser));
      await tester.pumpAndSettle();

      expect(find.text('No invite codes yet'), findsOneWidget);
    });

    testWidgets('shows invite codes list', (tester) async {
      final authApi = _FakeAuthApiService()
        ..inviteCodes = [
          InviteCode(
            code: 'ABC123',
            createdAt: DateTime(2024),
          ),
          InviteCode(
            code: 'DEF456',
            createdAt: DateTime(2024),
            usedByEmail: 'used@example.com',
            usedAt: DateTime(2024, 2),
          ),
        ];

      await tester.pumpWidget(
        _buildSubject(user: _adminUser, authApi: authApi),
      );
      await tester.pumpAndSettle();

      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('DEF456'), findsOneWidget);
      expect(find.text('Used'), findsOneWidget);
      expect(find.text('used@example.com'), findsOneWidget);
    });

    testWidgets('generate invite code shows dialog', (tester) async {
      final authApi = _FakeAuthApiService()..generatedCode = 'NEW-CODE-789';

      await tester.pumpWidget(
        _buildSubject(user: _adminUser, authApi: authApi),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate Invite Code'));
      // Use pump() instead of pumpAndSettle() because the generate flow
      // triggers a second async call (_loadInviteCodes) after showing the
      // dialog, which keeps rebuilding.
      await tester.pump();
      await tester.pump();

      expect(find.text('Invite Code Generated'), findsOneWidget);
      expect(find.text('NEW-CODE-789'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('reset user password opens dialog', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _adminUser));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset User Password'));
      await tester.pumpAndSettle();

      expect(find.text('Reset User Password'), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Generate Token'), findsOneWidget);
    });

    testWidgets('is wrapped in a Card', (tester) async {
      await tester.pumpWidget(_buildSubject(user: _adminUser));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
