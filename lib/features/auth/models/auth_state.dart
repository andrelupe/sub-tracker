import 'package:subtracker/features/auth/models/user_profile.dart';

/// Represents the current authentication status.
enum AuthStatus {
  /// Initial state while checking stored tokens.
  loading,

  /// User is authenticated with a valid session.
  authenticated,

  /// No active session.
  unauthenticated,
}

/// Immutable authentication state.
///
/// Holds the current [status], the authenticated [user] profile,
/// and the current [accessToken] for API requests.
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.accessToken,
  });

  final AuthStatus status;
  final UserProfile? user;
  final String? accessToken;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Whether the authenticated user has the Admin role.
  bool get isAdmin => user?.isAdmin ?? false;

  /// Creates a copy with the given fields replaced.
  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? accessToken,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
    );
  }
}
