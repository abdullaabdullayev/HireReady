import 'dart:convert';
import 'dart:io';
import '../models/app_models.dart';
import 'api_client.dart';

class DocumentService {
  static Future<UploadedResource> upload({
    required String filePath,
    required String fileName,
    required String type,
  }) async {
    final res = await ApiClient.upload(
      '/documents',
      fields: {'type': type},
      filePath: filePath,
      fileName: fileName,
    );
    if (res.statusCode == 200) {
      return UploadedResource.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_errorFrom(res.statusCode, res.body));
  }

  static Future<List<UploadedResource>> list() async {
    final res = await ApiClient.get('/documents');
    if (res.statusCode == 200) {
      final arr = jsonDecode(res.body) as List<dynamic>;
      return arr.map((e) => UploadedResource.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_errorFrom(res.statusCode, res.body));
  }

  static Future<void> delete(String id) async {
    final res = await ApiClient.delete('/documents/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errorFrom(res.statusCode, res.body));
    }
  }

  static String _errorFrom(int code, String body) =>
      body.isNotEmpty ? body : 'Request failed ($code)';
}

String friendlyError(Object e) {
  if (e is SessionExpiredException) return e.message;
  if (e is SocketException) return 'Cannot reach the server. Is the backend running?';
  final msg = e.toString().replaceFirst('Exception: ', '');
  return msg;
}
