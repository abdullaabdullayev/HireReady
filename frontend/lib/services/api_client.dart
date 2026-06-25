import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_storage.dart';

class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Session expired. Please log in again.']);
  @override
  String toString() => message;
}

class ApiClient {
  static const _base = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 60);

  static Future<bool>? _refreshing;

  static Future<void> Function()? onSessionExpired;

  static bool _expiredFired = false;

  static void _fireExpired() {
    if (_expiredFired) return;
    _expiredFired = true;
    onSessionExpired?.call();
  }

  static Future<http.Response> get(String path) =>
      _send(() async => http.get(_uri(path), headers: await _headers()).timeout(_timeout));

  static Future<http.Response> delete(String path) =>
      _send(() async => http.delete(_uri(path), headers: await _headers()).timeout(_timeout));

  static Future<http.Response> patch(String path, [Object? body]) =>
      _send(() async => http
          .patch(_uri(path),
              headers: await _headers(json: body != null),
              body: body == null ? null : jsonEncode(body))
          .timeout(_timeout));

  static Future<http.Response> postJson(String path, Object body) =>
      _send(() async => http
          .post(_uri(path), headers: await _headers(json: true), body: jsonEncode(body))
          .timeout(_timeout));

  static Future<http.Response> upload(
    String path, {
    required Map<String, String> fields,
    required String filePath,
    required String fileName,
  }) async {
    Future<http.Response> attempt() async {
      final req = http.MultipartRequest('POST', _uri(path));
      req.headers.addAll(await _headers());
      req.fields.addAll(fields);
      req.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      final streamed = await req.send().timeout(_timeout);
      return http.Response.fromStream(streamed);
    }

    var res = await attempt();
    if (_isAuthError(res.statusCode)) {
      final ok = await _refreshToken();
      if (!ok) { _fireExpired(); throw SessionExpiredException(); }
      res = await attempt();
      if (_isAuthError(res.statusCode)) { _fireExpired(); throw SessionExpiredException(); }
    }
    return res;
  }

  static Future<http.Response> _send(Future<http.Response> Function() run) async {
    var res = await run();
    if (_isAuthError(res.statusCode)) {
      final ok = await _refreshToken();
      if (!ok) { _fireExpired(); throw SessionExpiredException(); }
      res = await run();
      if (_isAuthError(res.statusCode)) { _fireExpired(); throw SessionExpiredException(); }
    }
    return res;
  }

  static Future<bool> _refreshToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  static Future<bool> _doRefresh() async {
    final refresh = await TokenStorage.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await http
          .post(_uri('/auth/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refreshToken': refresh}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        if (newAccess != null && newAccess.isNotEmpty) {
          await TokenStorage.saveAccess(newAccess);
          _expiredFired = false;
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Uri _uri(String path) => Uri.parse('$_base$path');

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await TokenStorage.accessToken;
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static bool _isAuthError(int code) => code == 401 || code == 403;
}
