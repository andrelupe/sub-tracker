import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:5270/api';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<T> get<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await _client.get(uri).timeout(_timeout);

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
      final response = await _client.get(uri).timeout(_timeout);

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
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
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
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(_timeout);

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
      final response = await _client.delete(uri).timeout(_timeout);

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
