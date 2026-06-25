import 'package:flutter/material.dart';

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

enum QuestionSource { system, customFile }

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

  factory JobRole.fromJson(Map<String, dynamic> json) {
    return JobRole(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      icon: _iconMap[json['iconName']] ?? Icons.work_rounded,
      color: _colorFromHex(json['colorHex'] as String),
    );
  }

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

  static Color _colorFromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class Question {
  final String id;
  final String prompt;
  final String category;
  final List<String> options;
  final int? correctIndex;
  final String modelAnswer;
  final List<String> keyPoints;

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

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      category: (json['category'] as String?) ?? 'General',
      options: ((json['options'] as List?) ?? const []).map((e) => e.toString()).toList(),
      correctIndex: json['correctIndex'] as int?,
      modelAnswer: (json['modelAnswer'] as String?) ?? '',
      keyPoints: ((json['keyPoints'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

class AnswerRecord {
  final String? id;
  final Question question;
  final String? textAnswer;
  final int? selectedOption;
  final bool answeredByVoice;
  final int score;
  final bool isCorrect;
  final String feedback;
  bool markedForReview;

  AnswerRecord({
    this.id,
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

class UploadedResource {
  final String? id;
  final String name;
  final String type;
  final int sizeBytes;
  final String extractionStatus;

  const UploadedResource({
    this.id,
    required this.name,
    required this.type,
    this.sizeBytes = 0,
    this.extractionStatus = 'NOT_NEEDED',
  });

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
