import 'dart:convert';
import '../models/app_models.dart';
import 'api_client.dart';

class CreatedSession {
  final String id;
  final List<Question> questions;
  CreatedSession({required this.id, required this.questions});
}

class SessionAnswer {
  final String id;
  final String questionId;
  final String? textAnswer;
  final int? selectedOption;
  final bool answeredByVoice;
  final int score;
  final bool correct;
  final String feedback;
  final bool markedForReview;

  SessionAnswer({
    required this.id,
    required this.questionId,
    this.textAnswer,
    this.selectedOption,
    required this.answeredByVoice,
    required this.score,
    required this.correct,
    required this.feedback,
    required this.markedForReview,
  });

  factory SessionAnswer.fromJson(Map<String, dynamic> j) => SessionAnswer(
        id: j['id'] as String,
        questionId: j['questionId'] as String,
        textAnswer: j['textAnswer'] as String?,
        selectedOption: (j['selectedOption'] as num?)?.toInt(),
        answeredByVoice: (j['answeredByVoice'] as bool?) ?? false,
        score: (j['score'] as num?)?.toInt() ?? 0,
        correct: (j['correct'] as bool?) ?? false,
        feedback: (j['feedback'] as String?) ?? '',
        markedForReview: (j['markedForReview'] as bool?) ?? false,
      );
}

class ActiveSession {
  final String id;
  final List<Question> questions;
  final List<SessionAnswer> answers;
  ActiveSession({required this.id, required this.questions, required this.answers});
}

class Evaluation {
  final String answerId;
  final int score;
  final bool correct;
  final String feedback;
  final String modelAnswer;
  final List<String> keyPoints;

  Evaluation({
    required this.answerId,
    required this.score,
    required this.correct,
    required this.feedback,
    required this.modelAnswer,
    required this.keyPoints,
  });

  factory Evaluation.fromJson(Map<String, dynamic> j) => Evaluation(
        answerId: j['answerId'] as String,
        score: (j['score'] as num).toInt(),
        correct: j['correct'] as bool,
        feedback: (j['feedback'] as String?) ?? '',
        modelAnswer: (j['modelAnswer'] as String?) ?? '',
        keyPoints: ((j['keyPoints'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
}

class SessionSummary {
  final int averageScore;
  final int correct;
  final int total;
  SessionSummary({required this.averageScore, required this.correct, required this.total});

  factory SessionSummary.fromJson(Map<String, dynamic> j) => SessionSummary(
        averageScore: (j['averageScore'] as num?)?.toInt() ?? 0,
        correct: (j['correct'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

class SessionService {
  static Future<CreatedSession> create({
    required String? roleId,
    required String level,
    required List<String> focusAreas,
    String? questionsFileId,
    String? resumeFileId,
    List<String> referenceFileIds = const [],
  }) async {
    final res = await ApiClient.postJson('/sessions', {
      'roleId': roleId,
      'level': level,
      'focusAreas': focusAreas,
      if (questionsFileId != null) 'questionsFileId': questionsFileId,
      if (resumeFileId != null) 'resumeFileId': resumeFileId,
      if (referenceFileIds.isNotEmpty) 'referenceFileIds': referenceFileIds,
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final qs = ((data['questions'] as List?) ?? const [])
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
      return CreatedSession(id: data['id'] as String, questions: qs);
    }
    throw Exception(_err(res.statusCode, res.body));
  }

  static Future<ActiveSession?> active() async {
    final res = await ApiClient.get('/sessions/active');
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final qs = ((data['questions'] as List?) ?? const [])
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
      final ans = ((data['answers'] as List?) ?? const [])
          .map((e) => SessionAnswer.fromJson(e as Map<String, dynamic>))
          .toList();
      return ActiveSession(id: data['id'] as String, questions: qs, answers: ans);
    }
    throw Exception(_err(res.statusCode, res.body));
  }

  static Future<Evaluation> submitAnswer({
    required String sessionId,
    required String questionId,
    String? text,
    int? selectedOption,
    bool answeredByVoice = false,
  }) async {
    final res = await ApiClient.postJson('/sessions/$sessionId/answers', {
      'questionId': questionId,
      'text': text,
      'selectedOption': selectedOption,
      'answeredByVoice': answeredByVoice,
    });
    if (res.statusCode == 200) {
      return Evaluation.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_err(res.statusCode, res.body));
  }

  static Future<void> markForReview({
    required String sessionId,
    required String answerId,
    required bool marked,
  }) async {
    await ApiClient.patch('/sessions/$sessionId/answers/$answerId?marked=$marked');
  }

  static Future<SessionSummary> complete(String sessionId) async {
    final res = await ApiClient.postJson('/sessions/$sessionId/complete', {});
    if (res.statusCode == 200) {
      return SessionSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_err(res.statusCode, res.body));
  }

  static String _err(int code, String body) => body.isNotEmpty ? body : 'Request failed ($code)';
}
