import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../state/app_state.dart';
import 'jwt_decoder.dart';
import 'token_storage.dart';

class AuthService {
  static const _base = ApiConfig.baseUrl;
  static const _timeout = Duration(seconds: 15);

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/auth/register'),
            headers: _jsonHeaders,
            body: jsonEncode({'name': name, 'email': email, 'password': password}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        await TokenStorage.saveName(name);
        return null;
      }
      return res.body.isNotEmpty ? res.body : 'Registration failed (${res.statusCode})';
    } on SocketException {
      return _networkError;
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/auth/login'),
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        await TokenStorage.save(
          accessToken,
          (data['refreshToken'] as String?) ?? '',
        );
        final name = JwtDecoder.claim(accessToken, 'name') ??
            (data['name'] as String?) ??
            await TokenStorage.userName;
        if (name != null && name.isNotEmpty) {
          await TokenStorage.saveName(name);
          AppState.instance.setUserName(name);
        }
        return null;
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        return 'Invalid email or password';
      }
      return res.body.isNotEmpty ? res.body : 'Login failed (${res.statusCode})';
    } on SocketException {
      return _networkError;
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  static Future<void> logout() async {
    final refresh = await TokenStorage.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('$_base/auth/logout'),
              headers: _jsonHeaders,
              body: jsonEncode({'refreshToken': refresh}),
            )
            .timeout(_timeout);
      } catch (_) {
      }
    }
    await TokenStorage.clear();
  }

  static const _networkError =
      'Cannot reach the server. Make sure the backend is running.';
}
