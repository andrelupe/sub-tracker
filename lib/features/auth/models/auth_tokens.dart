import 'package:subtracker/features/auth/models/user_profile.dart';

/// Tokens returned by the authentication API after login or registration.
///
/// Contains the JWT [accessToken], the [refreshToken] for renewal,
/// [expiresIn] (seconds until access token expires), and the [user] profile.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserProfile user;
}
