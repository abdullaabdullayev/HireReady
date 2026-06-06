import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_storage.dart';

/// Thrown when the session can't be recovered (refresh failed/expired).
/// The UI should send the user back to login.
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Session expired. Please log in again.']);
  @override
  String toString() => message;
}

/// Central authenticated HTTP client.
///
/// Attaches the Bearer access token to every request. If the server replies
/// 401/403, it transparently calls /api/auth/refresh, stores the new access
/// token, and retries the original request once. The rest of the app never has
/// to think about token expiry.
class ApiClient {
  static const _base = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 60);

  // Ensures concurrent 401s trigger only ONE refresh, not many.
  static Future<bool>? _refreshing;

  /// Called once when refresh fails for good (e.g. refresh token expired).
  /// The app sets this in main() to clear tokens and route to login.
  static Future<void> Function()? onSessionExpired;

  static bool _expiredFired = false;

  static void _fireExpired() {
    if (_expiredFired) return; // only once until next successful refresh
    _expiredFired = true;
    onSessionExpired?.call();
  }

  // ---- Public helpers (mirror http.* but auth-aware + auto-refresh) ----

  static Future<http.Response> get(String path) =>
      _send(() async => http.get(_uri(path), headers: await _headers()).timeout(_timeout));

  static Future<http.Response> delete(String path) =>
      _send(() async => http.delete(_uri(path), headers: await _headers()).timeout(_timeout));

  static Future<http.Response> postJson(String path, Object body) =>
      _send(() async => http
          .post(_uri(path), headers: await _headers(json: true), body: jsonEncode(body))
          .timeout(_timeout));

  /// Multipart file upload. The file part is rebuilt from [filePath] on each
  /// attempt (multipart streams are single-use), so retry-after-refresh works.
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

  // ---- Core: run, and on 401/403 refresh once + retry ----

  static Future<http.Response> _send(Future<http.Response> Function() run) async {
    var res = await run();
    if (_isAuthError(res.statusCode)) {
      final ok = await _refreshToken();
      if (!ok) { _fireExpired(); throw SessionExpiredException(); }
      res = await run(); // retry once with the new token
      if (_isAuthError(res.statusCode)) { _fireExpired(); throw SessionExpiredException(); }
    }
    return res;
  }

  // ---- Token refresh (shared, single-flight) ----

  static Future<bool> _refreshToken() {
    // If a refresh is already in progress, await the same future.
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
          _expiredFired = false; // allow future expiry handling
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ---- helpers ----

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
