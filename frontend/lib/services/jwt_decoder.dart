import 'dart:convert';

/// Minimal client-side JWT reader.
///
/// A JWT is `header.payload.signature` (base64url). We only decode the payload
/// to read claims like `sub` and `name`. We do NOT verify the signature here —
/// the server already does that. Never trust these values for security
/// decisions; they're for display only.
class JwtDecoder {
  /// Returns the decoded payload claims, or an empty map if the token is
  /// malformed.
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

  /// Convenience: read a single string claim (e.g. "name", "sub").
  static String? claim(String token, String key) {
    final value = decode(token)[key];
    return value is String ? value : value?.toString();
  }

  static String _decodeBase64(String input) {
    // base64url → base64, then pad to a multiple of 4.
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
