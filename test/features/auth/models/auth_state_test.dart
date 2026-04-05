import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/models/auth_state.dart';
import 'package:subtracker/features/auth/models/user_profile.dart';

void main() {
  group('AuthStatus', () {
    test('has loading, authenticated, and unauthenticated values', () {
      expect(AuthStatus.values, hasLength(3));
      expect(AuthStatus.values, contains(AuthStatus.loading));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
    });
  });

  group('AuthState', () {
    const adminUser = UserProfile(
      id: 'user-1',
      email: 'admin@example.com',
      role: 'Admin',
    );

    const regularUser = UserProfile(
      id: 'user-2',
      email: 'user@example.com',
      role: 'User',
    );

    test('loading state is not authenticated', () {
      const state = AuthState(status: AuthStatus.loading);

      expect(state.isAuthenticated, isFalse);
      expect(state.isAdmin, isFalse);
      expect(state.user, isNull);
      expect(state.accessToken, isNull);
    });

    test('unauthenticated state is not authenticated', () {
      const state = AuthState(status: AuthStatus.unauthenticated);

      expect(state.isAuthenticated, isFalse);
      expect(state.isAdmin, isFalse);
    });

    test('authenticated state with admin user', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        user: adminUser,
        accessToken: 'jwt-token',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.isAdmin, isTrue);
      expect(state.user, equals(adminUser));
      expect(state.accessToken, equals('jwt-token'));
    });

    test('authenticated state with regular user is not admin', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        user: regularUser,
        accessToken: 'jwt-token',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.isAdmin, isFalse);
    });

    test('authenticated state without user is not admin', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        accessToken: 'jwt-token',
      );

      expect(state.isAuthenticated, isTrue);
      expect(state.isAdmin, isFalse);
      expect(state.user, isNull);
    });

    test('copyWith replaces fields', () {
      const original = AuthState(
        status: AuthStatus.unauthenticated,
      );

      final updated = original.copyWith(
        status: AuthStatus.authenticated,
        user: adminUser,
        accessToken: 'new-token',
      );

      expect(updated.status, equals(AuthStatus.authenticated));
      expect(updated.user, equals(adminUser));
      expect(updated.accessToken, equals('new-token'));
    });

    test('copyWith preserves fields when not specified', () {
      const original = AuthState(
        status: AuthStatus.authenticated,
        user: adminUser,
        accessToken: 'token',
      );

      final updated = original.copyWith();

      expect(updated.status, equals(original.status));
      expect(updated.user, equals(original.user));
      expect(updated.accessToken, equals(original.accessToken));
    });
  });
}
