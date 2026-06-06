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
enum QuestionSource { system, customFile }

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

  /// Backend-dən gələn JSON-dan JobRole yarat.
  /// iconName → IconData, colorHex → Color çevirməsi burada olur.
  factory JobRole.fromJson(Map<String, dynamic> json) {
    return JobRole(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      icon: _iconMap[json['iconName']] ?? Icons.work_rounded,
      color: _colorFromHex(json['colorHex'] as String),
    );
  }

  /// iconName String → Flutter IconData
  static const Map<String, IconData> _iconMap = {
    'web_rounded':                  Icons.web_rounded,
    'dns_rounded':                  Icons.dns_rounded,
    'phone_iphone_rounded':         Icons.phone_iphone_rounded,
    'insights_rounded':             Icons.insights_rounded,
    'dashboard_customize_rounded':  Icons.dashboard_customize_rounded,
    'brush_rounded':                Icons.brush_rounded,
    'settings_suggest_rounded':     Icons.settings_suggest_rounded,
    'bug_report_rounded':           Icons.bug_report_rounded,
  };

  /// "#4F46E5" → Color(0xFF4F46E5)
  static Color _colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
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

/// One uploaded document, mirrors the backend DocumentResponse.
class UploadedResource {
  final String? id;            // backend UUID (null before upload completes)
  final String name;
  final String type;           // RESUME | REFERENCE | QUESTIONS (or PDF for mock)
  final int sizeBytes;
  final String extractionStatus; // NOT_NEEDED | PENDING | DONE | FAILED

  const UploadedResource({
    this.id,
    required this.name,
    required this.type,
    this.sizeBytes = 0,
    this.extractionStatus = 'NOT_NEEDED',
  });

  /// Human-readable size for the UI, e.g. "248 KB".
  String get size {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory UploadedResource.fromJson(Map<String, dynamic> json) {
    return UploadedResource(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'file',
      type: json['type'] as String? ?? 'PDF',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      extractionStatus: json['extractionStatus'] as String? ?? 'NOT_NEEDED',
    );
  }
}
