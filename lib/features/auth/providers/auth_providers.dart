import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/features/auth/models/auth_state.dart';
import 'package:subtracker/features/auth/models/user_profile.dart';
import 'package:subtracker/features/auth/services/auth_api_service.dart';
import 'package:subtracker/features/auth/services/token_storage_service.dart';

part 'auth_providers.g.dart';

/// Global authentication notifier.
///
/// Manages the full auth lifecycle: initialisation from stored tokens,
/// login, registration, logout and token refresh.
///
/// Uses [keepAlive] so the auth state persists for the app lifetime.
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Start in loading state while we check stored tokens.
    _initializeAuth();
    return const AuthState(status: AuthStatus.loading);
  }

  /// Checks persistent storage for a refresh token and attempts
  /// to restore the session silently.
  Future<void> _initializeAuth() async {
    final storage = ref.read(tokenStorageServiceProvider);
    final refreshToken = await storage.getRefreshToken();

    if (refreshToken == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      await _refreshAccessToken(refreshToken);
    } catch (_) {
      await storage.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Authenticates with email and password.
  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);

    try {
      final authApi = ref.read(authApiServiceProvider);
      final tokens = await authApi.login(email, password);

      final storage = ref.read(tokenStorageServiceProvider);
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: tokens.user,
        accessToken: tokens.accessToken,
      );
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  /// Registers a new user. [inviteCode] is optional for the first user.
  Future<void> register(
    String email,
    String password, [
    String? inviteCode,
  ]) async {
    state = const AuthState(status: AuthStatus.loading);

    try {
      final authApi = ref.read(authApiServiceProvider);
      final tokens = await authApi.register(email, password, inviteCode);

      final storage = ref.read(tokenStorageServiceProvider);
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: tokens.user,
        accessToken: tokens.accessToken,
      );
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  /// Logs out the current user, invalidating the refresh token on the server.
  Future<void> logout() async {
    try {
      final storage = ref.read(tokenStorageServiceProvider);
      final refreshToken = await storage.getRefreshToken();

      if (refreshToken != null) {
        final authApi = ref.read(authApiServiceProvider);
        await authApi.logout(refreshToken);
      }
    } catch (_) {
      // Best-effort — always clear local state regardless of API errors.
    } finally {
      final storage = ref.read(tokenStorageServiceProvider);
      await storage.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Called by the 401 interceptor in [ApiService] and during
  /// initialisation.
  Future<void> refreshToken() async {
    final storage = ref.read(tokenStorageServiceProvider);
    final storedRefreshToken = await storage.getRefreshToken();

    if (storedRefreshToken == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      throw const AuthException('No refresh token available');
    }

    await _refreshAccessToken(storedRefreshToken);
  }

  /// Changes the password of the currently authenticated user.
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final authApi = ref.read(authApiServiceProvider);
    await authApi.changePassword(currentPassword, newPassword);
  }

  /// Internal helper that calls the refresh endpoint and updates state.
  Future<void> _refreshAccessToken(String refreshToken) async {
    final authApi = ref.read(authApiServiceProvider);
    final tokens = await authApi.refreshToken(refreshToken);

    final storage = ref.read(tokenStorageServiceProvider);
    await storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );

    state = AuthState(
      status: AuthStatus.authenticated,
      user: tokens.user,
      accessToken: tokens.accessToken,
    );
  }
}

// ---------------------------------------------------------------------------
// Derived providers
// ---------------------------------------------------------------------------

/// Whether the user is currently authenticated.
@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
}

/// Whether the authenticated user has the Admin role.
@riverpod
bool isAdmin(Ref ref) {
  return ref.watch(authNotifierProvider).isAdmin;
}

/// The current user profile, or `null` if not authenticated.
@riverpod
UserProfile? currentUser(Ref ref) {
  return ref.watch(authNotifierProvider).user;
}

// ---------------------------------------------------------------------------
// Auth-specific exception
// ---------------------------------------------------------------------------

/// Thrown when an authentication operation fails irrecoverably
/// (e.g. refresh token expired).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
