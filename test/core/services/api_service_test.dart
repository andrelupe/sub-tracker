import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:subtracker/core/services/api_service.dart';

void main() {
  group('ApiService Bearer token header', () {
    test('sends Authorization header when token is available', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['Authorization'];
        return http.Response(json.encode([]), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'my-jwt-token',
      );

      await apiService.getList('/test', (json) => json);

      expect(capturedHeader, equals('Bearer my-jwt-token'));
    });

    test('does not send Authorization header when token is null', () async {
      var hasHeader = false;

      final mockClient = MockClient((request) async {
        hasHeader = request.headers.containsKey('Authorization');
        return http.Response(json.encode([]), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => null,
      );

      await apiService.getList('/test', (json) => json);

      expect(hasHeader, isFalse);
    });

    test('does not send Authorization header when no getToken callback',
        () async {
      var hasHeader = false;

      final mockClient = MockClient((request) async {
        hasHeader = request.headers.containsKey('Authorization');
        return http.Response(json.encode([]), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
      );

      await apiService.getList('/test', (json) => json);

      expect(hasHeader, isFalse);
    });

    test('sends Authorization header on POST requests', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['Authorization'];
        return http.Response(json.encode({'id': '1'}), 201);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'my-jwt-token',
      );

      await apiService.post<Map<String, dynamic>>('/test', {'name': 'test'});

      expect(capturedHeader, equals('Bearer my-jwt-token'));
    });

    test('sends Authorization header on PUT requests', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['Authorization'];
        return http.Response('', 204);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'my-jwt-token',
      );

      await apiService.put('/test', {'name': 'test'});

      expect(capturedHeader, equals('Bearer my-jwt-token'));
    });

    test('sends Authorization header on DELETE requests', () async {
      String? capturedHeader;

      final mockClient = MockClient((request) async {
        capturedHeader = request.headers['Authorization'];
        return http.Response('', 204);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'my-jwt-token',
      );

      await apiService.delete('/test');

      expect(capturedHeader, equals('Bearer my-jwt-token'));
    });
  });

  group('ApiService 401 handling', () {
    test('throws ApiException on 401 from GET without refresh callback',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'expired-token',
      );

      expect(
        () => apiService.get<Map<String, dynamic>>('/test'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('retries request after successful token refresh', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Unauthorized', 401);
        }
        // Second request with refreshed token
        return http.Response(json.encode([]), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'refreshed-token',
        refreshToken: () async => true,
      );

      final result = await apiService.getList('/test', (json) => json);

      expect(result, isEmpty);
      expect(requestCount, 2);
    });

    test('calls onAuthFailure and throws when refresh fails', () async {
      var authFailureCalled = false;

      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'expired-token',
        refreshToken: () async => false,
        onAuthFailure: () async {
          authFailureCalled = true;
        },
      );

      expect(
        () => apiService.get<Map<String, dynamic>>('/test'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      // Wait for the async onAuthFailure to complete
      await Future<void>.delayed(Duration.zero);
      expect(authFailureCalled, isTrue);
    });

    test('throws ApiException on 401 from POST without refresh', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'expired-token',
      );

      expect(
        () => apiService.post<Map<String, dynamic>>('/test', {}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('throws ApiException on 401 from DELETE without refresh', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'expired-token',
      );

      expect(
        () => apiService.delete('/test'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('retries POST after successful refresh', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Unauthorized', 401);
        }
        return http.Response(json.encode({'id': '1'}), 201);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'new-token',
        refreshToken: () async => true,
      );

      final result = await apiService.post<Map<String, dynamic>>(
        '/test',
        {'name': 'test'},
      );

      expect(result['id'], equals('1'));
      expect(requestCount, 2);
    });

    test('retries PUT after successful refresh', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Unauthorized', 401);
        }
        return http.Response('', 204);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'new-token',
        refreshToken: () async => true,
      );

      await apiService.put('/test', {'name': 'test'});

      expect(requestCount, 2);
    });

    test('retries DELETE after successful refresh', () async {
      var requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Unauthorized', 401);
        }
        return http.Response('', 204);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'new-token',
        refreshToken: () async => true,
      );

      await apiService.delete('/test');

      expect(requestCount, 2);
    });
  });
}
