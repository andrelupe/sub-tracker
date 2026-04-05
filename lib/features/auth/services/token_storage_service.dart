import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists authentication tokens using SharedPreferences.
///
/// SharedPreferences is used instead of flutter_secure_storage because
/// the latter has known issues on Web. For a self-hosted PWA this is
/// an acceptable trade-off.
class TokenStorageService {
  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';

  /// Saves both tokens to persistent storage.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Returns the stored access token, or `null` if not present.
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Returns the stored refresh token, or `null` if not present.
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Removes both tokens from storage.
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}

/// Provider for [TokenStorageService].
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});
