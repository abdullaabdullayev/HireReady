import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../data/mock_data.dart';
import '../services/token_storage.dart';
import '../services/jwt_decoder.dart';
import '../services/role_service.dart';

/// Single in-memory store for the whole app. No backend / persistence —
/// everything resets when the app restarts.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  // --- Profile ---
  String userName = 'there';

  /// Update the signed-in user's display name and refresh listeners.
  void setUserName(String name) {
    userName = name.trim().isEmpty ? 'there' : name.trim();
    notifyListeners();
  }

  /// Restore the session at app startup: if a stored access token exists,
  /// decode its `name` claim into [userName]. Returns true if the user is
  /// already logged in (so the splash can skip the Welcome screen).
  Future<bool> loadSession() async {
    final token = await TokenStorage.accessToken;
    if (token == null || token.isEmpty) return false;

    final name = JwtDecoder.claim(token, 'name') ?? await TokenStorage.userName;
    if (name != null && name.isNotEmpty) {
      userName = name.trim();
      notifyListeners();
    }
    // Rolları da login zamanı yüklə (dashboard hazır olsun)
    await loadRoles();
    return true;
  }

  // --- Roles (backend-dən yüklənir) ---
  List<JobRole> roles = [];
  bool rolesLoading = false;

  Future<void> loadRoles() async {
    if (roles.isNotEmpty) return;   // artıq yüklənibsə təkrar çəkmə
    rolesLoading = true;
    notifyListeners();
    roles = await RoleService.getRoles();
    rolesLoading = false;
    notifyListeners();
  }

  // --- Session configuration being built ---
  JobRole? selectedRole;
  ExperienceLevel level = ExperienceLevel.mid;
  QuestionSource source = QuestionSource.system;
  bool useCustomRequirements = false;
  final Set<String> focusAreas = {'Behavioral', 'Technical'};

  /// Resume uploaded in "Set requirements" (optional) — used by the AI to
  /// tailor questions/feedback (mock).
  UploadedResource? resume;

  /// Reference books/resources uploaded under custom requirements (optional) —
  /// the AI uses them to check answers and generate questions (mock).
  final List<UploadedResource> referenceMaterials = [];

  /// Custom questions file(s) uploaded in "Question source". When chosen, the
  /// session is built from the questions extracted from them (mock).
  final List<UploadedResource> questionFiles = [];
  List<Question> customQuestions = [];

  // --- Active practice run ---
  List<Question> _sessionQuestions = [];
  final List<AnswerRecord> answers = [];

  List<Question> get sessionQuestions => _sessionQuestions;

  // --- Lifetime stats (mock starting values to make analytics look alive) ---
  int sessionsCompleted = 7;
  int questionsAnswered = 58;
  int dayStreak = 4;

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
    customQuestions = [];
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

  /// Add a questions file already uploaded to the backend. The backend reports
  /// whether it could read the file (extractionStatus). The actual extracted
  /// questions will come from the Session API later; until then we fall back to
  /// the mock bank so the practice loop still works.
  void addQuestionFile(UploadedResource file) {
    if (!questionFiles.any((e) => e.id == file.id)) questionFiles.add(file);
    if (file.extractionStatus == 'DONE') {
      customQuestions = List<Question>.from(MockData.customFileBank);
    } else {
      customQuestions = [];
    }
    notifyListeners();
  }

  void removeQuestionFile(UploadedResource file) {
    questionFiles.remove(file);
    if (questionFiles.isEmpty) customQuestions = [];
    notifyListeners();
  }

  /// Build the question list for the run. When the user chose to upload a
  /// custom questions file, use the questions extracted from it; otherwise use
  /// the system question bank.
  void buildSession() {
    final List<Question> bank;
    if (source == QuestionSource.customFile && customQuestions.isNotEmpty) {
      bank = customQuestions;
    } else {
      bank = MockData.defaultBank;
    }
    _sessionQuestions = List<Question>.from(bank);
    answers.clear();
    notifyListeners();
  }

  /// Mock "AI" grading. Produces a believable score + written feedback so the
  /// evaluation screen feels real without any server call.
  AnswerRecord evaluate({
    required Question question,
    String? text,
    int? selectedOption,
    bool byVoice = false,
  }) {
    int score;
    bool correct;
    String feedback;

    if (question.hasOptions) {
      correct = selectedOption == question.correctIndex;
      score = correct ? 100 : 0;
      feedback = correct
          ? 'Correct. ${question.modelAnswer}'
          : 'Not quite. ${question.modelAnswer}';
    } else {
      final answer = (text ?? '').trim();
      final words = answer.isEmpty ? 0 : answer.split(RegExp(r'\s+')).length;
      final lower = answer.toLowerCase();

      // Reward length + how many key points are touched.
      final hits = question.keyPoints.where((k) {
        final kw = k.toLowerCase().split(' ').firstWhere((w) => w.length > 3, orElse: () => k.toLowerCase());
        return lower.contains(kw);
      }).length;

      final lengthScore = (min(words, 80) / 80 * 60).round();
      final pointScore = question.keyPoints.isEmpty
          ? 30
          : (hits / question.keyPoints.length * 40).round();
      score = (lengthScore + pointScore).clamp(0, 100);
      correct = score >= 60;

      final missed = question.keyPoints
          .where((k) {
            final kw = k.toLowerCase().split(' ').firstWhere((w) => w.length > 3, orElse: () => k.toLowerCase());
            return !lower.contains(kw);
          })
          .toList();

      if (words < 8) {
        feedback = 'Your answer is quite short. Add more detail and structure. '
            'Aim to cover: ${question.keyPoints.join(", ")}.';
      } else if (missed.isEmpty) {
        feedback = 'Strong, well-rounded answer that touches all the key areas. '
            'Tighten it with a concrete metric to make it memorable.';
      } else {
        feedback = 'Good start. To strengthen it, also address: ${missed.join(", ")}.';
      }
    }

    final record = AnswerRecord(
      question: question,
      textAnswer: text,
      selectedOption: selectedOption,
      answeredByVoice: byVoice,
      score: score,
      isCorrect: correct,
      feedback: feedback,
    );
    answers.add(record);
    notifyListeners();
    return record;
  }

  void finishSession() {
    sessionsCompleted++;
    questionsAnswered += answers.length;
    notifyListeners();
  }

  // --- Derived metrics for the results / analytics screens ---
  int get correctCount => answers.where((a) => a.isCorrect).length;

  double get averageScore => answers.isEmpty
      ? 0
      : answers.map((a) => a.score).reduce((a, b) => a + b) / answers.length;

  List<AnswerRecord> get reviewList =>
      answers.where((a) => a.markedForReview || !a.isCorrect).toList();
}
