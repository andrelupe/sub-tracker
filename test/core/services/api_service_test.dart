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

    test('retry uses refreshed token (headers re-computed)', () async {
      var currentToken = 'expired-token';
      final capturedTokens = <String?>[];

      final mockClient = MockClient((request) async {
        capturedTokens.add(request.headers['Authorization']);
        if (capturedTokens.length == 1) {
          return http.Response('Unauthorized', 401);
        }
        return http.Response(json.encode([]), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => currentToken,
        refreshToken: () async {
          currentToken = 'fresh-token';
          return true;
        },
      );

      await apiService.getList('/test', (json) => json);

      expect(capturedTokens, hasLength(2));
      expect(capturedTokens[0], 'Bearer expired-token');
      expect(capturedTokens[1], 'Bearer fresh-token');
    });

    test('retry on POST uses refreshed token', () async {
      var currentToken = 'expired-token';
      final capturedTokens = <String?>[];

      final mockClient = MockClient((request) async {
        capturedTokens.add(request.headers['Authorization']);
        if (capturedTokens.length == 1) {
          return http.Response('Unauthorized', 401);
        }
        return http.Response(json.encode({'id': '1'}), 201);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => currentToken,
        refreshToken: () async {
          currentToken = 'fresh-token';
          return true;
        },
      );

      await apiService.post<Map<String, dynamic>>('/test', {'a': 'b'});

      expect(capturedTokens[0], 'Bearer expired-token');
      expect(capturedTokens[1], 'Bearer fresh-token');
    });
  });

  group('ApiService concurrent refresh coalescing', () {
    test('only one refresh runs when multiple 401s arrive simultaneously',
        () async {
      var refreshCount = 0;
      var currentToken = 'expired';

      final mockClient = MockClient((request) async {
        // First two requests (one per endpoint) return 401.
        // After refresh, the retries succeed.
        if (request.headers['Authorization'] == 'Bearer expired') {
          return http.Response('Unauthorized', 401);
        }
        return http.Response(json.encode([]), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => currentToken,
        refreshToken: () async {
          refreshCount++;
          // Simulate async delay of actual refresh
          await Future<void>.delayed(const Duration(milliseconds: 10));
          currentToken = 'fresh';
          return true;
        },
      );

      // Launch two requests concurrently — both will get 401 and
      // trigger refresh, but only one actual refresh should run.
      final results = await Future.wait([
        apiService.getList('/a', (json) => json),
        apiService.getList('/b', (json) => json),
      ]);

      expect(results[0], isEmpty);
      expect(results[1], isEmpty);
      expect(refreshCount, 1, reason: 'only one refresh should have run');
    });

    test('second concurrent caller gets result of first refresh', () async {
      var refreshCount = 0;
      var currentToken = 'old';

      final mockClient = MockClient((request) async {
        if (request.headers['Authorization'] == 'Bearer old') {
          return http.Response('Unauthorized', 401);
        }
        return http.Response(json.encode({'ok': true}), 200);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => currentToken,
        refreshToken: () async {
          refreshCount++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          currentToken = 'new';
          return true;
        },
      );

      final results = await Future.wait([
        apiService.get<Map<String, dynamic>>('/x'),
        apiService.get<Map<String, dynamic>>('/y'),
      ]);

      expect(results[0]['ok'], isTrue);
      expect(results[1]['ok'], isTrue);
      expect(refreshCount, 1);
    });

    test('all concurrent callers fail when refresh fails', () async {
      var refreshCount = 0;

      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost',
        client: mockClient,
        getToken: () async => 'expired',
        refreshToken: () async {
          refreshCount++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return false;
        },
        onAuthFailure: () async {},
      );

      final futures = [
        apiService.get<Map<String, dynamic>>('/a'),
        apiService.get<Map<String, dynamic>>('/b'),
      ];

      for (final future in futures) {
        expect(
          () => future,
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      }

      // Wait for all async operations to complete.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(refreshCount, 1, reason: 'only one refresh should have run');
    });
  });
}
