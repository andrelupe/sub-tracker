import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/models/auth_tokens.dart';
import 'package:subtracker/features/auth/models/user_profile.dart';

void main() {
  group('AuthTokens', () {
    test('fromJson parses valid response', () {
      final json = {
        'accessToken': 'eyJhbGciOiJIUzI1NiJ9.access',
        'refreshToken': 'eyJhbGciOiJIUzI1NiJ9.refresh',
        'expiresIn': 900,
        'user': {
          'id': 'user-1',
          'email': 'admin@example.com',
          'role': 'Admin',
        },
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, equals('eyJhbGciOiJIUzI1NiJ9.access'));
      expect(tokens.refreshToken, equals('eyJhbGciOiJIUzI1NiJ9.refresh'));
      expect(tokens.expiresIn, equals(900));
      expect(tokens.user.id, equals('user-1'));
      expect(tokens.user.email, equals('admin@example.com'));
      expect(tokens.user.role, equals('Admin'));
    });

    test('fromJson parses user with User role', () {
      final json = {
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'expiresIn': 3600,
        'user': {
          'id': 'user-2',
          'email': 'user@example.com',
          'role': 'User',
        },
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.user.isAdmin, isFalse);
      expect(tokens.expiresIn, equals(3600));
    });

    test('fromJson throws when accessToken is missing', () {
      final json = {
        'refreshToken': 'refresh-token',
        'expiresIn': 900,
        'user': {
          'id': 'user-1',
          'email': 'admin@example.com',
          'role': 'Admin',
        },
      };

      expect(() => AuthTokens.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('fromJson throws when user is missing', () {
      final json = {
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'expiresIn': 900,
      };

      expect(() => AuthTokens.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('fromJson throws when expiresIn is missing', () {
      final json = {
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'user': {
          'id': 'user-1',
          'email': 'admin@example.com',
          'role': 'Admin',
        },
      };

      expect(() => AuthTokens.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('constructor creates instance with correct values', () {
      const tokens = AuthTokens(
        accessToken: 'at',
        refreshToken: 'rt',
        expiresIn: 600,
        user: UserProfile(
          id: 'user-1',
          email: 'admin@example.com',
          role: 'Admin',
        ),
      );

      expect(tokens.accessToken, equals('at'));
      expect(tokens.refreshToken, equals('rt'));
      expect(tokens.expiresIn, equals(600));
      expect(tokens.user.isAdmin, isTrue);
    });
  });
}
