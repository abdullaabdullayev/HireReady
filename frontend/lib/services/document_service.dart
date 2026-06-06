import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/app_models.dart';
import 'token_storage.dart';

/// Talks to the backend /api/documents endpoints (file upload/list/delete).
class DocumentService {
  static const _timeout = Duration(seconds: 60); // uploads can be slow

  /// Uploads a file with its type (RESUME | REFERENCE | QUESTIONS).
  /// Returns the created UploadedResource, or throws with a message.
  static Future<UploadedResource> upload({
    required String filePath,
    required String fileName,
    required String type, // RESUME | REFERENCE | QUESTIONS
  }) async {
    final token = await TokenStorage.accessToken;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/documents'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['type'] = type;
    request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));

    final streamed = await request.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      return UploadedResource.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_errorFrom(res));
  }

  /// All documents for the current user.
  static Future<List<UploadedResource>> list() async {
    final token = await TokenStorage.accessToken;
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/documents'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final arr = jsonDecode(res.body) as List<dynamic>;
      return arr.map((e) => UploadedResource.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_errorFrom(res));
  }

  /// Delete by id.
  static Future<void> delete(String id) async {
    final token = await TokenStorage.accessToken;
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/documents/$id'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    ).timeout(_timeout);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errorFrom(res));
    }
  }

  static String _errorFrom(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) return 'Session expired. Please log in again.';
    return res.body.isNotEmpty ? res.body : 'Upload failed (${res.statusCode})';
  }
}

/// Convenience: wraps network errors into friendly text.
String friendlyError(Object e) {
  if (e is SocketException) return 'Cannot reach the server. Is the backend running?';
  final msg = e.toString().replaceFirst('Exception: ', '');
  return msg;
}
