import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/auth/models/auth_state.dart';
import 'package:subtracker/features/auth/models/auth_tokens.dart';
import 'package:subtracker/features/auth/models/user_profile.dart';
import 'package:subtracker/features/auth/providers/auth_providers.dart';
import 'package:subtracker/features/auth/services/auth_api_service.dart';
import 'package:subtracker/features/auth/services/token_storage_service.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// In-memory fake for [TokenStorageService].
class FakeTokenStorageService extends TokenStorageService {
  FakeTokenStorageService({String? accessToken, String? refreshToken})
      : _accessToken = accessToken,
        _refreshToken = refreshToken;

  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

/// Fake for [AuthApiService] that returns configurable results.
class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService() : super(ApiService(baseUrl: 'http://fake'));

  AuthTokens? loginResult;
  AuthTokens? registerResult;
  AuthTokens? refreshResult;
  bool logoutCalled = false;
  bool changePasswordCalled = false;

  Exception? loginError;
  Exception? registerError;
  Exception? refreshError;

  @override
  Future<AuthTokens> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<AuthTokens> register(
    String email,
    String password, [
    String? inviteCode,
  ]) async {
    if (registerError != null) throw registerError!;
    return registerResult!;
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    if (refreshError != null) throw refreshError!;
    return refreshResult!;
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalled = true;
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    changePasswordCalled = true;
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

const _testUser = UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  role: 'User',
);

const _adminUser = UserProfile(
  id: 'admin-1',
  email: 'admin@example.com',
  role: 'Admin',
);

AuthTokens _makeTokens({
  String accessToken = 'access-123',
  String refreshToken = 'refresh-456',
  UserProfile user = _testUser,
}) {
  return AuthTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: 3600,
    user: user,
  );
}

/// Creates a [ProviderContainer] with the given fakes overriding real
/// providers.
ProviderContainer _createContainer({
  required FakeAuthApiService authApi,
  required FakeTokenStorageService storage,
}) {
  return ProviderContainer(
    overrides: [
      authApiServiceProvider.overrideWithValue(authApi),
      tokenStorageServiceProvider.overrideWithValue(storage),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthNotifier', () {
    group('initialisation', () {
      test('sets unauthenticated when no stored tokens', () async {
        final authApi = FakeAuthApiService();
        final storage = FakeTokenStorageService();
        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        // First read triggers build() which starts as loading.
        final initialState = container.read(authNotifierProvider);
        expect(initialState.status, AuthStatus.loading);

        // Let _initializeAuth complete.
        await Future<void>.delayed(Duration.zero);

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(state.user, isNull);
        expect(state.accessToken, isNull);

        container.dispose();
      });

      test('sets authenticated when stored tokens and refresh succeeds',
          () async {
        final authApi = FakeAuthApiService()..refreshResult = _makeTokens();
        final storage = FakeTokenStorageService(
          accessToken: 'old-access',
          refreshToken: 'valid-refresh',
        );

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.authenticated);
        expect(state.user?.email, 'test@example.com');
        expect(state.accessToken, 'access-123');

        container.dispose();
      });

      test('sets unauthenticated when stored tokens but refresh fails',
          () async {
        final authApi = FakeAuthApiService()
          ..refreshError = const ApiException('Expired', 401);
        final storage = FakeTokenStorageService(
          accessToken: 'old-access',
          refreshToken: 'expired-refresh',
        );

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);

        // Tokens should be cleared.
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);

        container.dispose();
      });
    });

    group('login', () {
      test('transitions to authenticated on success', () async {
        final tokens = _makeTokens();
        final authApi = FakeAuthApiService()..loginResult = tokens;
        final storage = FakeTokenStorageService();

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        // Wait for init.
        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(authNotifierProvider).status,
          AuthStatus.unauthenticated,
        );

        // Login.
        await container
            .read(authNotifierProvider.notifier)
            .login('test@example.com', 'password123');

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.authenticated);
        expect(state.user?.email, 'test@example.com');
        expect(state.accessToken, 'access-123');

        // Tokens persisted.
        expect(await storage.getAccessToken(), 'access-123');
        expect(await storage.getRefreshToken(), 'refresh-456');

        container.dispose();
      });

      test('transitions to unauthenticated on failure and rethrows', () async {
        final authApi = FakeAuthApiService()
          ..loginError = const ApiException('Invalid credentials', 401);
        final storage = FakeTokenStorageService();

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        expect(
          () => container
              .read(authNotifierProvider.notifier)
              .login('bad@example.com', 'wrong'),
          throwsA(isA<ApiException>()),
        );

        await Future<void>.delayed(Duration.zero);

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);

        container.dispose();
      });
    });

    group('register', () {
      test('transitions to authenticated on success', () async {
        final tokens = _makeTokens(
          user: _adminUser,
          accessToken: 'admin-access',
          refreshToken: 'admin-refresh',
        );
        final authApi = FakeAuthApiService()..registerResult = tokens;
        final storage = FakeTokenStorageService();

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        await container
            .read(authNotifierProvider.notifier)
            .register('admin@example.com', 'password123');

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.authenticated);
        expect(state.user?.isAdmin, isTrue);
        expect(state.accessToken, 'admin-access');

        container.dispose();
      });

      test('transitions to unauthenticated on failure and rethrows', () async {
        final authApi = FakeAuthApiService()
          ..registerError = const ApiException('Invalid invite code', 400);
        final storage = FakeTokenStorageService();

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        expect(
          () => container
              .read(authNotifierProvider.notifier)
              .register('new@example.com', 'pass', 'bad-code'),
          throwsA(isA<ApiException>()),
        );

        await Future<void>.delayed(Duration.zero);

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);

        container.dispose();
      });
    });

    group('logout', () {
      test('transitions to unauthenticated and clears tokens', () async {
        final tokens = _makeTokens();
        final authApi = FakeAuthApiService()..loginResult = tokens;
        final storage = FakeTokenStorageService();

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        // Login first.
        await container
            .read(authNotifierProvider.notifier)
            .login('test@example.com', 'pass');
        expect(
          container.read(authNotifierProvider).status,
          AuthStatus.authenticated,
        );

        // Logout.
        await container.read(authNotifierProvider.notifier).logout();

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(state.user, isNull);
        expect(state.accessToken, isNull);
        expect(authApi.logoutCalled, isTrue);

        // Tokens cleared.
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);

        container.dispose();
      });
    });

    group('refreshToken', () {
      test('updates access token on success', () async {
        final initialTokens = _makeTokens();
        final refreshedTokens = _makeTokens(
          accessToken: 'new-access-token',
          refreshToken: 'new-refresh-token',
        );

        final authApi = FakeAuthApiService()
          ..loginResult = initialTokens
          ..refreshResult = refreshedTokens;
        final storage = FakeTokenStorageService();

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        // Login first.
        await container
            .read(authNotifierProvider.notifier)
            .login('test@example.com', 'pass');

        // Refresh.
        await container.read(authNotifierProvider.notifier).refreshToken();

        final state = container.read(authNotifierProvider);
        expect(state.status, AuthStatus.authenticated);
        expect(state.accessToken, 'new-access-token');

        // Storage updated.
        expect(await storage.getAccessToken(), 'new-access-token');
        expect(await storage.getRefreshToken(), 'new-refresh-token');

        container.dispose();
      });

      test('throws AuthException when no refresh token stored', () async {
        final authApi = FakeAuthApiService();
        final storage = FakeTokenStorageService();

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        expect(
          () => container.read(authNotifierProvider.notifier).refreshToken(),
          throwsA(isA<AuthException>()),
        );

        container.dispose();
      });
    });

    group('changePassword', () {
      test('calls API service', () async {
        final tokens = _makeTokens();
        final authApi = FakeAuthApiService()..loginResult = tokens;
        final storage = FakeTokenStorageService();

        final container = _createContainer(
          authApi: authApi,
          storage: storage,
        );

        container.read(authNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        await container
            .read(authNotifierProvider.notifier)
            .login('test@example.com', 'pass');

        await container
            .read(authNotifierProvider.notifier)
            .changePassword('oldPass', 'newPass');

        expect(authApi.changePasswordCalled, isTrue);

        container.dispose();
      });
    });
  });

  group('Derived providers', () {
    test('isAuthenticated reflects auth state', () async {
      final authApi = FakeAuthApiService();
      final storage = FakeTokenStorageService();

      final container = _createContainer(
        authApi: authApi,
        storage: storage,
      );

      container.read(authNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), isFalse);

      // Login.
      authApi.loginResult = _makeTokens();
      await container
          .read(authNotifierProvider.notifier)
          .login('test@example.com', 'pass');

      expect(container.read(isAuthenticatedProvider), isTrue);

      container.dispose();
    });

    test('isAdmin reflects user role', () async {
      final tokens = _makeTokens(user: _adminUser);
      final authApi = FakeAuthApiService()..loginResult = tokens;
      final storage = FakeTokenStorageService();

      final container = _createContainer(
        authApi: authApi,
        storage: storage,
      );

      container.read(authNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAdminProvider), isFalse);

      await container
          .read(authNotifierProvider.notifier)
          .login('admin@example.com', 'pass');

      expect(container.read(isAdminProvider), isTrue);

      container.dispose();
    });

    test('currentUser returns user profile when authenticated', () async {
      final tokens = _makeTokens();
      final authApi = FakeAuthApiService()..loginResult = tokens;
      final storage = FakeTokenStorageService();

      final container = _createContainer(
        authApi: authApi,
        storage: storage,
      );

      container.read(authNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentUserProvider), isNull);

      await container
          .read(authNotifierProvider.notifier)
          .login('test@example.com', 'pass');

      final user = container.read(currentUserProvider);
      expect(user, isNotNull);
      expect(user?.email, 'test@example.com');

      container.dispose();
    });
  });
}
