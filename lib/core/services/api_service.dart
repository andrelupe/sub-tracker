import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Callback to retrieve the current access token from storage.
typedef GetTokenCallback = Future<String?> Function();

/// Callback to attempt a token refresh. Returns `true` if successful.
typedef RefreshTokenCallback = Future<bool> Function();

/// Callback invoked when authentication fails irrecoverably (e.g. refresh
/// token expired). Typically triggers a logout.
typedef OnAuthFailureCallback = Future<void> Function();

class ApiService {
  ApiService({
    required String baseUrl,
    http.Client? client,
    GetTokenCallback? getToken,
    RefreshTokenCallback? refreshToken,
    OnAuthFailureCallback? onAuthFailure,
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client(),
        _getToken = getToken,
        _refreshToken = refreshToken,
        _onAuthFailure = onAuthFailure;

  static const Duration _timeout = Duration(seconds: 10);

  final String _baseUrl;
  final http.Client _client;

  /// Callback that returns the current access token (may be `null`).
  final GetTokenCallback? _getToken;

  /// Callback that attempts to refresh the access token.
  final RefreshTokenCallback? _refreshToken;

  /// Callback invoked when a 401 cannot be recovered.
  final OnAuthFailureCallback? _onAuthFailure;

  /// Guards concurrent refresh attempts so only one runs at a time.
  Completer<bool>? _refreshInProgress;

  // ---------------------------------------------------------------------------
  // Headers
  // ---------------------------------------------------------------------------

  /// Builds the default headers including the Bearer token when available.
  Future<Map<String, String>> _headers({String? contentType}) async {
    final headers = <String, String>{};
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }

    final token = await _getToken?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ---------------------------------------------------------------------------
  // 401 interceptor
  // ---------------------------------------------------------------------------

  /// Performs a single token refresh, coalescing concurrent callers so that
  /// only one actual refresh happens at a time.
  Future<bool> _refreshOnce() async {
    if (_refreshInProgress != null) {
      return _refreshInProgress!.future;
    }

    _refreshInProgress = Completer<bool>();
    try {
      final result = await _refreshToken!();
      _refreshInProgress!.complete(result);
      return result;
    } catch (_) {
      _refreshInProgress!.complete(false);
      return false;
    } finally {
      _refreshInProgress = null;
    }
  }

  /// Executes [request]. On a 401 response, attempts a token refresh and
  /// retries once. If the refresh fails, calls [_onAuthFailure] and throws.
  ///
  /// **Important**: [request] must re-compute headers on each invocation so
  /// that the retry picks up the refreshed token.
  Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();

    if (response.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _refreshOnce();

      if (refreshed) {
        // Retry the original request — the closure re-reads the token from
        // storage via _headers(), so it will use the new access token.
        response = await request();
      } else {
        await _onAuthFailure?.call();
        throw const ApiException(
          'Session expired. Please log in again.',
          401,
        );
      }
    }

    return response;
  }

  // ---------------------------------------------------------------------------
  // HTTP methods
  // ---------------------------------------------------------------------------

  Future<T> get<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      final response = await _withAuthRetry(
        () async {
          final headers = await _headers();
          return _client.get(uri, headers: headers).timeout(_timeout);
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (fromJson != null) {
          return fromJson(decoded as Map<String, dynamic>);
        }
        return decoded as T;
      } else if (response.statusCode == 401) {
        throw const ApiException(
          'Authentication failed.',
          401,
        );
      } else if (response.statusCode == 404) {
        throw const ApiException('Resource not found', 404);
      } else {
        throw ApiException(
          'Failed to load data: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<List<T>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      final response = await _withAuthRetry(
        () async {
          final headers = await _headers();
          return _client.get(uri, headers: headers).timeout(_timeout);
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final data = decoded as List<dynamic>;
        return data.cast<Map<String, dynamic>>().map(fromJson).toList();
      } else if (response.statusCode == 401) {
        throw const ApiException('Authentication failed.', 401);
      } else {
        throw ApiException(
          'Failed to load data: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<T> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final body = json.encode(data);

      final response = await _withAuthRetry(
        () async {
          final headers = await _headers(contentType: 'application/json');
          return _client.post(uri, headers: headers, body: body).timeout(
                _timeout,
              );
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = json.decode(response.body);
        if (fromJson != null) {
          return fromJson(decoded as Map<String, dynamic>);
        }
        return decoded as T;
      } else if (response.statusCode == 400) {
        final dynamic decoded = json.decode(response.body);
        throw ValidationException(decoded as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw const ApiException('Authentication failed.', 401);
      } else {
        throw ApiException(
          'Failed to create resource: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<void> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final body = json.encode(data);

      final response = await _withAuthRetry(
        () async {
          final headers = await _headers(contentType: 'application/json');
          return _client.put(uri, headers: headers, body: body).timeout(
                _timeout,
              );
        },
      );

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw const ApiException('Authentication failed.', 401);
      } else if (response.statusCode == 404) {
        throw const ApiException('Resource not found', 404);
      } else if (response.statusCode == 400) {
        final dynamic decoded = json.decode(response.body);
        throw ValidationException(decoded as Map<String, dynamic>);
      } else {
        throw ApiException(
          'Failed to update resource: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      final response = await _withAuthRetry(
        () async {
          final headers = await _headers();
          return _client.delete(uri, headers: headers).timeout(_timeout);
        },
      );

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw const ApiException('Authentication failed.', 401);
      } else if (response.statusCode == 404) {
        throw const ApiException('Resource not found', 404);
      } else {
        throw ApiException(
          'Failed to delete resource: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e', 0);
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ValidationException implements Exception {
  const ValidationException(this.errors);

  final Map<String, dynamic> errors;

  @override
  String toString() => 'ValidationException: $errors';
}
