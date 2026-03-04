import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subtracker/core/services/api_service.dart';

void main() {
  group('ApiService API key header', () {
    test('sends X-Api-Key header when apiKey is set', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['X-Api-Key'];
        return http.Response(json.encode([]), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        apiKey: 'my-secret-key',
        client: mockClient,
      );

      await apiService.getList('/test', (json) => json);

      expect(capturedHeader, equals('my-secret-key'));
    });

    test('does not send X-Api-Key header when apiKey is empty', () async {
      bool hasHeader = false;

      final mockClient = MockClient((request) async {
        hasHeader = request.headers.containsKey('X-Api-Key');
        return http.Response(json.encode([]), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
      );

      await apiService.getList('/test', (json) => json);

      expect(hasHeader, isFalse);
    });

    test('sends X-Api-Key header on POST requests', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['X-Api-Key'];
        return http.Response(json.encode({'id': '1'}), 201);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        apiKey: 'my-key',
        client: mockClient,
      );

      await apiService.post<Map<String, dynamic>>('/test', {'name': 'test'});

      expect(capturedHeader, equals('my-key'));
    });

    test('sends X-Api-Key header on PUT requests', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['X-Api-Key'];
        return http.Response('', 204);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        apiKey: 'my-key',
        client: mockClient,
      );

      await apiService.put('/test', {'name': 'test'});

      expect(capturedHeader, equals('my-key'));
    });

    test('sends X-Api-Key header on DELETE requests', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['X-Api-Key'];
        return http.Response('', 204);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        apiKey: 'my-key',
        client: mockClient,
      );

      await apiService.delete('/test');

      expect(capturedHeader, equals('my-key'));
    });
  });

  group('ApiService 401 handling', () {
    test('throws ApiException with auth message on 401 from GET', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        apiKey: 'wrong-key',
        client: mockClient,
      );

      expect(
        () => apiService.get<Map<String, dynamic>>('/test'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having(
                (e) => e.message,
                'message',
                'Authentication failed. Check your API key.',
              ),
        ),
      );
    });

    test('throws ApiException with auth message on 401 from POST', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        apiKey: 'wrong-key',
        client: mockClient,
      );

      expect(
        () => apiService.post<Map<String, dynamic>>('/test', {}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('throws ApiException with auth message on 401 from DELETE', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        apiKey: 'wrong-key',
        client: mockClient,
      );

      expect(
        () => apiService.delete('/test'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
