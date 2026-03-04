import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const Duration _timeout = Duration(seconds: 10);
  static const String _apiKeyHeader = 'X-Api-Key';
  static const String _authFailedMessage =
      'Authentication failed. Check your API key.';

  final String _baseUrl;
  final http.Client _client;
  final String _apiKey;

  ApiService({
    required String baseUrl,
    String apiKey = '',
    http.Client? client,
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _client = client ?? http.Client();

  /// Builds the default headers for all requests.
  /// Includes the API key header when configured.
  Map<String, String> _headers({String? contentType}) {
    final headers = <String, String>{};
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    if (_apiKey.isNotEmpty) {
      headers[_apiKeyHeader] = _apiKey;
    }
    return headers;
  }

  /// Checks the response for a 401 status and throws an [ApiException].
  void _check401(http.Response response) {
    if (response.statusCode == 401) {
      throw const ApiException(_authFailedMessage, 401);
    }
  }

  Future<T> get<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response =
          await _client.get(uri, headers: _headers()).timeout(_timeout);

      _check401(response);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (fromJson != null) {
          return fromJson(decoded as Map<String, dynamic>);
        }
        return decoded as T;
      } else if (response.statusCode == 404) {
        throw ApiException('Resource not found', 404);
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
      final response =
          await _client.get(uri, headers: _headers()).timeout(_timeout);

      _check401(response);

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> data = decoded as List<dynamic>;
        return data.cast<Map<String, dynamic>>().map(fromJson).toList();
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
      final response = await _client
          .post(
            uri,
            headers: _headers(contentType: 'application/json'),
            body: json.encode(data),
          )
          .timeout(_timeout);

      _check401(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = json.decode(response.body);
        if (fromJson != null) {
          return fromJson(decoded as Map<String, dynamic>);
        }
        return decoded as T;
      } else if (response.statusCode == 400) {
        final dynamic decoded = json.decode(response.body);
        throw ValidationException(decoded as Map<String, dynamic>);
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
      final response = await _client
          .put(
            uri,
            headers: _headers(contentType: 'application/json'),
            body: json.encode(data),
          )
          .timeout(_timeout);

      _check401(response);

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw ApiException('Resource not found', 404);
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
      final response =
          await _client.delete(uri, headers: _headers()).timeout(_timeout);

      _check401(response);

      if (response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw ApiException('Resource not found', 404);
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
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ValidationException implements Exception {
  final Map<String, dynamic> errors;

  const ValidationException(this.errors);

  @override
  String toString() => 'ValidationException: $errors';
}
