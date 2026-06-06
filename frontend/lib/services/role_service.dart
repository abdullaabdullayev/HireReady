import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/app_models.dart';
import 'token_storage.dart';

/// Backend /api/roles endpoint-indən rolları çəkir.
class RoleService {
  static const _timeout = Duration(seconds: 15);

  static Future<List<JobRole>> getRoles() async {
    try {
      final token = await TokenStorage.accessToken;
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/roles'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => JobRole.fromJson(e as Map<String, dynamic>)).toList();
      }
      // Backend cavab verməsə mock data qaytar (offline/dev rejimi)
      return _fallback;
    } on SocketException {
      return _fallback;
    } catch (_) {
      return _fallback;
    }
  }

  /// Backend işləməyəndə (offline/dev) göstərilən ehtiyat siyahı.
  static final List<JobRole> _fallback = [
    JobRole.fromJson({'id': 'frontend', 'title': 'Frontend Developer', 'category': 'Engineering', 'iconName': 'web_rounded',                 'colorHex': '#4F46E5'}),
    JobRole.fromJson({'id': 'backend',  'title': 'Backend Developer',  'category': 'Engineering', 'iconName': 'dns_rounded',                 'colorHex': '#0EA5E9'}),
    JobRole.fromJson({'id': 'mobile',   'title': 'Mobile Engineer',    'category': 'Engineering', 'iconName': 'phone_iphone_rounded',        'colorHex': '#10B981'}),
    JobRole.fromJson({'id': 'data',     'title': 'Data Scientist',     'category': 'Data & AI',   'iconName': 'insights_rounded',            'colorHex': '#8B5CF6'}),
    JobRole.fromJson({'id': 'pm',       'title': 'Product Manager',    'category': 'Product',     'iconName': 'dashboard_customize_rounded', 'colorHex': '#F59E0B'}),
    JobRole.fromJson({'id': 'design',   'title': 'Product Designer',   'category': 'Design',      'iconName': 'brush_rounded',               'colorHex': '#EC4899'}),
    JobRole.fromJson({'id': 'devops',   'title': 'DevOps Engineer',    'category': 'Engineering', 'iconName': 'settings_suggest_rounded',    'colorHex': '#14B8A6'}),
    JobRole.fromJson({'id': 'qa',       'title': 'QA Engineer',        'category': 'Engineering', 'iconName': 'bug_report_rounded',          'colorHex': '#EF4444'}),
  ];
}
