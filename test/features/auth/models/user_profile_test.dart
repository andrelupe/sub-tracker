import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('fromJson parses admin user', () {
      final json = {
        'id': 'user-1',
        'email': 'admin@example.com',
        'role': 'Admin',
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, equals('user-1'));
      expect(user.email, equals('admin@example.com'));
      expect(user.role, equals('Admin'));
    });

    test('fromJson parses regular user', () {
      final json = {
        'id': 'user-2',
        'email': 'user@example.com',
        'role': 'User',
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, equals('user-2'));
      expect(user.email, equals('user@example.com'));
      expect(user.role, equals('User'));
    });

    test('isAdmin returns true for Admin role', () {
      const user = UserProfile(
        id: 'user-1',
        email: 'admin@example.com',
        role: 'Admin',
      );

      expect(user.isAdmin, isTrue);
    });

    test('isAdmin returns false for User role', () {
      const user = UserProfile(
        id: 'user-2',
        email: 'user@example.com',
        role: 'User',
      );

      expect(user.isAdmin, isFalse);
    });

    test('isAdmin returns false for unknown role', () {
      const user = UserProfile(
        id: 'user-3',
        email: 'other@example.com',
        role: 'Moderator',
      );

      expect(user.isAdmin, isFalse);
    });

    test('isAdmin is case sensitive', () {
      const user = UserProfile(
        id: 'user-4',
        email: 'admin@example.com',
        role: 'admin',
      );

      expect(user.isAdmin, isFalse);
    });

    test('toJson serializes correctly', () {
      const user = UserProfile(
        id: 'user-1',
        email: 'admin@example.com',
        role: 'Admin',
      );

      final json = user.toJson();

      expect(json['id'], equals('user-1'));
      expect(json['email'], equals('admin@example.com'));
      expect(json['role'], equals('Admin'));
    });

    test('fromJson throws when id is missing', () {
      final json = {
        'email': 'admin@example.com',
        'role': 'Admin',
      };

      expect(() => UserProfile.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('fromJson throws when email is missing', () {
      final json = {
        'id': 'user-1',
        'role': 'Admin',
      };

      expect(() => UserProfile.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('fromJson throws when role is missing', () {
      final json = {
        'id': 'user-1',
        'email': 'admin@example.com',
      };

      expect(() => UserProfile.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
