import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../data/mock_data.dart';

/// Single in-memory store for the whole app. No backend / persistence —
/// everything resets when the app restarts.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  // --- Profile (mock) ---
  String userName = 'Abdulla';

  // --- Session configuration being built ---
  JobRole? selectedRole;
  ExperienceLevel level = ExperienceLevel.mid;
  QuestionSource source = QuestionSource.defaultBank;
  final List<UploadedResource> resources = [];
  bool useCustomRequirements = false;
  final Set<String> focusAreas = {'Behavioral', 'Technical'};

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
    source = QuestionSource.defaultBank;
    resources.clear();
    useCustomRequirements = false;
    focusAreas
      ..clear()
      ..addAll({'Behavioral', 'Technical'});
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

  void addResource(UploadedResource r) {
    resources.add(r);
    notifyListeners();
  }

  /// Build the question list for the run based on chosen source.
  void buildSession() {
    final bank = source == QuestionSource.resume ? MockData.resumeBank : MockData.defaultBank;
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
