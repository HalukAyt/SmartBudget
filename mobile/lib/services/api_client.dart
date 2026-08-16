import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';

typedef UnauthorizedHandler = Future<void> Function();

enum ApiErrorType {
  validation,
  unauthorized,
  notFound,
  conflict,
  network,
  timeout,
  server,
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.type, this.userMessage, {this.statusCode});

  final ApiErrorType type;
  final String userMessage;
  final int? statusCode;

  @override
  String toString() => userMessage;
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    http.Client? httpClient,
    Duration timeout = ApiConfig.timeout,
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
       _tokenStorage = tokenStorage,
       _httpClient = httpClient ?? http.Client(),
       _timeout = timeout;

  final String _baseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _httpClient;
  final Duration _timeout;

  UnauthorizedHandler? onUnauthorized;

  Future<Object?> get(String path, {bool requiresAuth = true}) =>
      _send('GET', path, requiresAuth: requiresAuth);

  Future<Object?> post(String path, {Object? body, bool requiresAuth = true}) =>
      _send('POST', path, body: body, requiresAuth: requiresAuth);

  Future<Object?> put(String path, {Object? body, bool requiresAuth = true}) =>
      _send('PUT', path, body: body, requiresAuth: requiresAuth);

  Future<Object?> delete(String path, {bool requiresAuth = true}) =>
      _send('DELETE', path, requiresAuth: requiresAuth);

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    required bool requiresAuth,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    if (requiresAuth) {
      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final request = http.Request(method, _buildUri(path))
      ..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.trim().isEmpty) {
          return null;
        }
        return jsonDecode(response.body);
      }

      if (response.statusCode == 401 && requiresAuth) {
        await onUnauthorized?.call();
      }

      throw _mapHttpError(response);
    } on TimeoutException {
      throw const ApiException(
        ApiErrorType.timeout,
        'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
      );
    } on http.ClientException {
      throw const ApiException(
        ApiErrorType.network,
        'İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edin.',
      );
    } on FormatException {
      throw const ApiException(
        ApiErrorType.server,
        'Sunucudan beklenmeyen bir yanıt alındı.',
      );
    }
  }

  Uri _buildUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  ApiException _mapHttpError(http.Response response) {
    final detail = _readProblemDetail(response.body);

    return switch (response.statusCode) {
      400 => ApiException(
        ApiErrorType.validation,
        detail ?? 'Girdiğiniz bilgileri kontrol edin.',
        statusCode: 400,
      ),
      401 => const ApiException(
        ApiErrorType.unauthorized,
        'E-posta veya şifre hatalı.',
        statusCode: 401,
      ),
      404 => const ApiException(
        ApiErrorType.notFound,
        'İstenen kayıt bulunamadı.',
        statusCode: 404,
      ),
      409 => ApiException(
        ApiErrorType.conflict,
        detail ?? 'Bu bilgilerle mevcut bir kayıt bulunuyor.',
        statusCode: 409,
      ),
      >= 500 => const ApiException(
        ApiErrorType.server,
        'Bir sorun oluştu. Lütfen tekrar deneyin.',
        statusCode: 500,
      ),
      _ => const ApiException(
        ApiErrorType.unknown,
        'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
      ),
    };
  }

  String? _readProblemDetail(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }
      }
    } on FormatException {
      return null;
    }

    return null;
  }
}
