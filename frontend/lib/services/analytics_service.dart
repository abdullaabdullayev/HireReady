import 'dart:convert';
import 'api_client.dart';

class Analytics {
  final int sessions;
  final int questions;
  final int avgScore;
  final int dayStreak;
  final List<DayActivity> weekly;
  final List<SkillScore> skills;

  Analytics({
    required this.sessions,
    required this.questions,
    required this.avgScore,
    required this.dayStreak,
    required this.weekly,
    required this.skills,
  });

  factory Analytics.fromJson(Map<String, dynamic> j) => Analytics(
        sessions: (j['sessions'] as num?)?.toInt() ?? 0,
        questions: (j['questions'] as num?)?.toInt() ?? 0,
        avgScore: (j['avgScore'] as num?)?.toInt() ?? 0,
        dayStreak: (j['dayStreak'] as num?)?.toInt() ?? 0,
        weekly: ((j['weekly'] as List?) ?? const [])
            .map((e) => DayActivity.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: ((j['skills'] as List?) ?? const [])
            .map((e) => SkillScore.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static Analytics empty() =>
      Analytics(sessions: 0, questions: 0, avgScore: 0, dayStreak: 0, weekly: [], skills: []);
}

class DayActivity {
  final String day;
  final int count;
  DayActivity(this.day, this.count);
  factory DayActivity.fromJson(Map<String, dynamic> j) =>
      DayActivity((j['day'] as String?) ?? '', (j['count'] as num?)?.toInt() ?? 0);
}

class SkillScore {
  final String name;
  final int percent;
  SkillScore(this.name, this.percent);
  factory SkillScore.fromJson(Map<String, dynamic> j) =>
      SkillScore((j['name'] as String?) ?? '', (j['percent'] as num?)?.toInt() ?? 0);
}

class AnalyticsService {
  static Future<Analytics> get() async {
    final res = await ApiClient.get('/analytics');
    if (res.statusCode == 200) {
      return Analytics.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Analytics failed (${res.statusCode})');
  }
}
