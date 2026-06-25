import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/token_storage.dart';
import '../services/jwt_decoder.dart';
import '../services/role_service.dart';
import '../services/session_service.dart';
import '../services/analytics_service.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  String userName = 'there';

  void setUserName(String name) {
    userName = name.trim().isEmpty ? 'there' : name.trim();
    notifyListeners();
  }

  Future<bool> loadSession() async {
    final token = await TokenStorage.accessToken;
    if (token == null || token.isEmpty) return false;

    final name = JwtDecoder.claim(token, 'name') ?? await TokenStorage.userName;
    if (name != null && name.isNotEmpty) {
      userName = name.trim();
      notifyListeners();
    }
    await loadRoles();
    return true;
  }

  List<JobRole> roles = [];
  bool rolesLoading = false;

  Future<void> loadRoles() async {
    if (roles.isNotEmpty) return;
    rolesLoading = true;
    notifyListeners();
    roles = await RoleService.getRoles();
    rolesLoading = false;
    notifyListeners();
  }

  JobRole? selectedRole;
  ExperienceLevel level = ExperienceLevel.mid;
  QuestionSource source = QuestionSource.system;
  bool useCustomRequirements = false;
  final Set<String> focusAreas = {'Behavioral', 'Technical'};

  UploadedResource? resume;

  final List<UploadedResource> referenceMaterials = [];

  final List<UploadedResource> questionFiles = [];

  List<Question> _sessionQuestions = [];
  final List<AnswerRecord> answers = [];

  List<Question> get sessionQuestions => _sessionQuestions;

  int sessionsCompleted = 0;
  int questionsAnswered = 0;
  int dayStreak = 0;

  Analytics analytics = Analytics.empty();
  bool analyticsLoading = false;

  Future<void> loadAnalytics() async {
    analyticsLoading = true;
    notifyListeners();
    try {
      analytics = await AnalyticsService.get();
      sessionsCompleted = analytics.sessions;
      questionsAnswered = analytics.questions;
      dayStreak = analytics.dayStreak;
    } catch (_) {
    } finally {
      analyticsLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    selectedRole = null;
    level = ExperienceLevel.mid;
    source = QuestionSource.system;
    resume = null;
    referenceMaterials.clear();
    useCustomRequirements = false;
    focusAreas
      ..clear()
      ..addAll({'Behavioral', 'Technical'});
    questionFiles.clear();
    _sessionQuestions = [];
    answers.clear();
    notifyListeners();
  }

  void toggleFocus(String area) {
    if (focusAreas.contains(area)) {
      focusAreas.remove(area);
    } else {
      focusAreas.add(area);
    }
    notifyListeners();
  }

  void setResume(UploadedResource r) {
    resume = r;
    notifyListeners();
  }

  void removeResume() {
    resume = null;
    notifyListeners();
  }

  void addReferenceMaterial(UploadedResource r) {
    if (!referenceMaterials.any((e) => e.name == r.name)) referenceMaterials.add(r);
    notifyListeners();
  }

  void removeReferenceMaterial(UploadedResource r) {
    referenceMaterials.remove(r);
    notifyListeners();
  }

  void addQuestionFile(UploadedResource file) {
    if (!questionFiles.any((e) => e.id == file.id)) questionFiles.add(file);
    notifyListeners();
  }

  void removeQuestionFile(UploadedResource file) {
    questionFiles.remove(file);
    notifyListeners();
  }

  String? sessionId;
  bool hasActiveSession = false;

  Future<void> loadActiveSession() async {
    try {
      final active = await SessionService.active();
      if (active == null || active.questions.isEmpty) {
        hasActiveSession = false;
      } else {
        sessionId = active.id;
        _sessionQuestions = active.questions;
        answers.clear();
        for (final a in active.answers) {
          Question? q;
          for (final question in active.questions) {
            if (question.id == a.questionId) {
              q = question;
              break;
            }
          }
          if (q == null) continue;
          answers.add(AnswerRecord(
            id: a.id,
            question: q,
            textAnswer: a.textAnswer,
            selectedOption: a.selectedOption,
            answeredByVoice: a.answeredByVoice,
            score: a.score,
            isCorrect: a.correct,
            feedback: a.feedback,
            markedForReview: a.markedForReview,
          ));
        }
        hasActiveSession = answers.length < _sessionQuestions.length;
      }
    } catch (_) {
      hasActiveSession = false;
    }
    notifyListeners();
  }

  /// Index of the first question that has not been answered yet.
  int get resumeIndex {
    final answered = answers.map((a) => a.question.id).toSet();
    for (var i = 0; i < _sessionQuestions.length; i++) {
      if (!answered.contains(_sessionQuestions[i].id)) return i;
    }
    return _sessionQuestions.isEmpty ? 0 : _sessionQuestions.length - 1;
  }

  Future<void> startSession() async {
    UploadedResource? questionsFile;
    for (final f in questionFiles) {
      if (f.extractionStatus == 'DONE' && f.id != null) {
        questionsFile = f;
        break;
      }
    }
    source = questionsFile != null ? QuestionSource.customFile : QuestionSource.system;

    final created = await SessionService.create(
      roleId: selectedRole?.id,
      level: level.name.toUpperCase(),
      focusAreas: focusAreas.toList(),
      questionsFileId: questionsFile?.id,
      resumeFileId: resume?.id,
      referenceFileIds:
          referenceMaterials.map((e) => e.id).whereType<String>().toList(),
    );
    sessionId = created.id;
    _sessionQuestions = created.questions;
    answers.clear();
    hasActiveSession = true;
    notifyListeners();
  }

  Future<AnswerRecord> submitAnswer({
    required Question question,
    String? text,
    int? selectedOption,
    bool byVoice = false,
  }) async {
    final eval = await SessionService.submitAnswer(
      sessionId: sessionId!,
      questionId: question.id,
      text: text,
      selectedOption: selectedOption,
      answeredByVoice: byVoice,
    );
    final record = AnswerRecord(
      id: eval.answerId,
      question: question,
      textAnswer: text,
      selectedOption: selectedOption,
      answeredByVoice: byVoice,
      score: eval.score,
      isCorrect: eval.correct,
      feedback: eval.feedback,
    );
    answers.add(record);
    notifyListeners();
    return record;
  }

  Future<void> toggleReview(AnswerRecord record, bool marked) async {
    record.markedForReview = marked;
    notifyListeners();
    if (sessionId != null && record.id != null) {
      try {
        await SessionService.markForReview(
            sessionId: sessionId!, answerId: record.id!, marked: marked);
      } catch (_) {}
    }
  }

  Future<void> finishSession() async {
    if (sessionId != null) {
      try {
        await SessionService.complete(sessionId!);
      } catch (_) {}
    }
    hasActiveSession = false;
    await loadAnalytics();
  }

  int get correctCount => answers.where((a) => a.isCorrect).length;

  double get averageScore => answers.isEmpty
      ? 0
      : answers.map((a) => a.score).reduce((a, b) => a + b) / answers.length;

  List<AnswerRecord> get reviewList =>
      answers.where((a) => a.markedForReview || !a.isCorrect).toList();
}
