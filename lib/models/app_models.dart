import 'package:flutter/material.dart';

/// Difficulty / seniority level for a practice session.
enum ExperienceLevel { junior, mid, senior }

extension ExperienceLevelX on ExperienceLevel {
  String get label => switch (this) {
        ExperienceLevel.junior => 'Junior',
        ExperienceLevel.mid => 'Mid-level',
        ExperienceLevel.senior => 'Senior',
      };

  String get subtitle => switch (this) {
        ExperienceLevel.junior => '0–2 years • fundamentals',
        ExperienceLevel.mid => '2–5 years • applied depth',
        ExperienceLevel.senior => '5+ years • system & leadership',
      };
}

/// Where the questions for a session come from.
enum QuestionSource { resume, defaultBank }

/// A job role the user can practice for.
class JobRole {
  final String id;
  final String title;
  final String category;
  final IconData icon;
  final Color color;

  const JobRole({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
  });
}

/// A single interview question. "Non-variant" questions have no [options]
/// and are answered with free text or voice.
class Question {
  final String id;
  final String prompt;
  final String category; // e.g. Behavioral, Technical, System Design
  final List<String> options; // empty => open / non-variant question
  final int? correctIndex; // for option questions
  final String modelAnswer; // reference answer used by the mock "AI"
  final List<String> keyPoints; // graded against the answer

  const Question({
    required this.id,
    required this.prompt,
    required this.category,
    this.options = const [],
    this.correctIndex,
    required this.modelAnswer,
    this.keyPoints = const [],
  });

  bool get hasOptions => options.isNotEmpty;
}

/// The user's answer + the mock AI evaluation for one question.
class AnswerRecord {
  final Question question;
  final String? textAnswer;
  final int? selectedOption;
  final bool answeredByVoice;
  final int score; // 0..100
  final bool isCorrect;
  final String feedback;
  bool markedForReview;

  AnswerRecord({
    required this.question,
    this.textAnswer,
    this.selectedOption,
    this.answeredByVoice = false,
    required this.score,
    required this.isCorrect,
    required this.feedback,
    this.markedForReview = false,
  });
}

/// One uploaded resource (resume, job description, notes).
class UploadedResource {
  final String name;
  final String type; // PDF, DOCX, TXT
  final String size;

  const UploadedResource({required this.name, required this.type, required this.size});
}
