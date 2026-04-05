import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/auth/models/invite_code.dart';

void main() {
  group('InviteCode', () {
    test('fromJson parses unused invite code', () {
      final json = {
        'code': 'ABC123',
        'createdAt': '2026-03-20T10:00:00Z',
        'usedByEmail': null,
        'usedAt': null,
      };

      final invite = InviteCode.fromJson(json);

      expect(invite.code, equals('ABC123'));
      expect(invite.createdAt, equals(DateTime.utc(2026, 3, 20, 10)));
      expect(invite.usedByEmail, isNull);
      expect(invite.usedAt, isNull);
    });

    test('fromJson parses used invite code', () {
      final json = {
        'code': 'XYZ789',
        'createdAt': '2026-03-18T08:30:00Z',
        'usedByEmail': 'newuser@example.com',
        'usedAt': '2026-03-19T14:00:00Z',
      };

      final invite = InviteCode.fromJson(json);

      expect(invite.code, equals('XYZ789'));
      expect(invite.usedByEmail, equals('newuser@example.com'));
      expect(invite.usedAt, equals(DateTime.utc(2026, 3, 19, 14)));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'code': 'DEF456',
        'createdAt': '2026-03-21T12:00:00Z',
      };

      final invite = InviteCode.fromJson(json);

      expect(invite.code, equals('DEF456'));
      expect(invite.usedByEmail, isNull);
      expect(invite.usedAt, isNull);
    });

    test('isUsed returns false for unused code', () {
      final invite = InviteCode(
        code: 'ABC123',
        createdAt: DateTime.utc(2026, 3, 20),
      );

      expect(invite.isUsed, isFalse);
    });

    test('isUsed returns true for used code', () {
      final invite = InviteCode(
        code: 'ABC123',
        createdAt: DateTime.utc(2026, 3, 20),
        usedByEmail: 'user@example.com',
        usedAt: DateTime.utc(2026, 3, 21),
      );

      expect(invite.isUsed, isTrue);
    });

    test('isUsed returns true even without usedAt', () {
      final invite = InviteCode(
        code: 'ABC123',
        createdAt: DateTime.utc(2026, 3, 20),
        usedByEmail: 'user@example.com',
      );

      expect(invite.isUsed, isTrue);
    });

    test('fromJson throws when code is missing', () {
      final json = {
        'createdAt': '2026-03-20T10:00:00Z',
      };

      expect(() => InviteCode.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('fromJson throws when createdAt is missing', () {
      final json = {
        'code': 'ABC123',
      };

      expect(() => InviteCode.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
