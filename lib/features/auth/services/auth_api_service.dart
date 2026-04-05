import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/core/providers/api_providers.dart';
import 'package:subtracker/core/services/api_service.dart';
import 'package:subtracker/features/auth/models/auth_tokens.dart';
import 'package:subtracker/features/auth/models/invite_code.dart';
import 'package:subtracker/features/auth/models/user_profile.dart';

/// HTTP client for all authentication-related API endpoints.
class AuthApiService {
  const AuthApiService(this._api);

  final ApiService _api;

  /// Authenticates a user with email and password.
  Future<AuthTokens> login(String email, String password) async {
    return _api.post<AuthTokens>(
      '/auth/login',
      {'email': email, 'password': password},
      fromJson: AuthTokens.fromJson,
    );
  }

  /// Registers a new user. [inviteCode] is optional for the first user.
  Future<AuthTokens> register(
    String email,
    String password, [
    String? inviteCode,
  ]) async {
    return _api.post<AuthTokens>(
      '/auth/register',
      {
        'email': email,
        'password': password,
        if (inviteCode != null) 'inviteCode': inviteCode,
      },
      fromJson: AuthTokens.fromJson,
    );
  }

  /// Refreshes the access token using a valid refresh token.
  Future<AuthTokens> refreshToken(String refreshToken) async {
    return _api.post<AuthTokens>(
      '/auth/refresh',
      {'refreshToken': refreshToken},
      fromJson: AuthTokens.fromJson,
    );
  }

  /// Invalidates the refresh token on the server.
  Future<void> logout(String refreshToken) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/logout',
      {'refreshToken': refreshToken},
    );
  }

  /// Returns the profile of the currently authenticated user.
  Future<UserProfile> getMe() async {
    return _api.get<UserProfile>(
      '/auth/me',
      fromJson: UserProfile.fromJson,
    );
  }

  /// Changes the password of the currently authenticated user.
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Resets a user's password using a reset token (from admin).
  Future<void> resetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/reset-password',
      {
        'email': email,
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  /// Admin: generates a new invite code for user registration.
  Future<String> createInviteCode() async {
    final response = await _api.post<Map<String, dynamic>>(
      '/auth/invite-codes',
      {},
    );
    return response['code'] as String;
  }

  /// Admin: lists all invite codes.
  Future<List<InviteCode>> listInviteCodes() async {
    return _api.getList<InviteCode>(
      '/auth/invite-codes',
      InviteCode.fromJson,
    );
  }

  /// Admin: requests a password reset token for a user.
  Future<void> requestPasswordReset(String email) async {
    await _api.post<Map<String, dynamic>>(
      '/auth/request-password-reset',
      {'email': email},
    );
  }
}

/// Provider for [AuthApiService].
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthApiService(api);
});
