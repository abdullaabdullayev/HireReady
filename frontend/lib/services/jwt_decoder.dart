import 'dart:convert';

class JwtDecoder {
  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = _decodeBase64(parts[1]);
      final map = jsonDecode(payload);
      return map is Map<String, dynamic> ? map : {};
    } catch (_) {
      return {};
    }
  }

  static String? claim(String token, String key) {
    final value = decode(token)[key];
    return value is String ? value : value?.toString();
  }

  static String _decodeBase64(String input) {
    var output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
    }
    return utf8.decode(base64.decode(output));
  }
}
