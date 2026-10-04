import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'api_exception.dart';

/// Result of a conditional GET.
class ApiResponse {
  const ApiResponse({required this.notModified, this.json, this.etag});

  final bool notModified;
  final Map<String, dynamic>? json;
  final String? etag;
}

/// Minimal JSON client for the public, read-only API.
///
/// Only HTTPS endpoints should be used in production (Android blocks
/// clear-text traffic and iOS App Transport Security requires TLS).
class ApiClient {
  /// [baseUrl] overrides `API_BASE_URL` (used by tests).
  ApiClient({http.Client? httpClient, this.baseUrl}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String? baseUrl;

  Uri _uri(String path) {
    final base = baseUrl;
    if (base == null) return Env.apiUri(path);
    return Uri.parse('${base.endsWith('/') ? base.substring(0, base.length - 1) : base}/api/v1$path');
  }

  Future<ApiResponse> getJson(String path, {String? etag}) async {
    final uri = _uri(path);
    try {
      final response = await _http
          .get(uri, headers: {HttpHeaders.acceptHeader: 'application/json', HttpHeaders.ifNoneMatchHeader: ?etag})
          .timeout(Env.requestTimeout);
      if (response.statusCode == 304) {
        return ApiResponse(notModified: true, etag: etag);
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map<String, dynamic>) {
          throw const ApiException('Unexpected response from server', statusCode: 200);
        }
        return ApiResponse(notModified: false, json: decoded, etag: response.headers['etag']);
      }
      throw ApiException('Server error (${response.statusCode})', statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('The server took too long to respond');
    } on SocketException {
      throw const ApiException('No internet connection');
    } on http.ClientException {
      throw const ApiException('Could not connect to the server');
    } on FormatException {
      throw const ApiException('Received invalid data from the server', statusCode: 200);
    }
  }

  void close() => _http.close();
}
