import 'package:flutter/material.dart';
import '../models/app_models.dart';

/// Static, in-memory content. No backend — this stands in for what an API
/// or AI service would return.
class MockData {
  static const List<JobRole> roles = [
    JobRole(id: 'frontend', title: 'Frontend Developer', category: 'Engineering', icon: Icons.web_rounded, color: Color(0xFF4F46E5)),
    JobRole(id: 'backend', title: 'Backend Developer', category: 'Engineering', icon: Icons.dns_rounded, color: Color(0xFF0EA5E9)),
    JobRole(id: 'mobile', title: 'Mobile Engineer', category: 'Engineering', icon: Icons.phone_iphone_rounded, color: Color(0xFF10B981)),
    JobRole(id: 'data', title: 'Data Scientist', category: 'Data & AI', icon: Icons.insights_rounded, color: Color(0xFF8B5CF6)),
    JobRole(id: 'pm', title: 'Product Manager', category: 'Product', icon: Icons.dashboard_customize_rounded, color: Color(0xFFF59E0B)),
    JobRole(id: 'design', title: 'Product Designer', category: 'Design', icon: Icons.brush_rounded, color: Color(0xFFEC4899)),
    JobRole(id: 'devops', title: 'DevOps Engineer', category: 'Engineering', icon: Icons.settings_suggest_rounded, color: Color(0xFF14B8A6)),
    JobRole(id: 'qa', title: 'QA Engineer', category: 'Engineering', icon: Icons.bug_report_rounded, color: Color(0xFFEF4444)),
  ];

  static const List<UploadedResource> sampleResources = [
    UploadedResource(name: 'Resume_2026.pdf', type: 'PDF', size: '248 KB'),
    UploadedResource(name: 'Job_Description.pdf', type: 'PDF', size: '92 KB'),
  ];

  /// Default question bank used when the user picks "use default question bank".
  static const List<Question> defaultBank = [
    Question(
      id: 'q1',
      prompt: 'Tell me about a challenging project you worked on. What made it hard and how did you handle it?',
      category: 'Behavioral',
      modelAnswer:
          'Use the STAR method: describe the Situation and Task, the specific Actions you took, and the measurable Result. Emphasise ownership, trade-offs, and what you learned.',
      keyPoints: ['Clear situation/context', 'Your specific actions', 'Measurable outcome', 'Lesson learned'],
    ),
    Question(
      id: 'q2',
      prompt: 'What is the difference between "let", "const", and "var" in JavaScript?',
      category: 'Technical',
      options: [
        'They are identical and interchangeable',
        'var is function-scoped; let/const are block-scoped, const cannot be reassigned',
        'const is function-scoped; let/var are block-scoped',
        'Only var can be used inside loops',
      ],
      correctIndex: 1,
      modelAnswer:
          'var is function-scoped and hoisted. let and const are block-scoped. const cannot be reassigned after initialisation, though objects it holds can still be mutated.',
    ),
    Question(
      id: 'q3',
      prompt: 'How would you design a URL shortener that handles millions of requests per day?',
      category: 'System Design',
      modelAnswer:
          'Discuss requirements, a hashing/encoding scheme for short keys, a key-value store for lookups, caching for hot links, database sharding, and read-vs-write scaling. Mention analytics and rate limiting.',
      keyPoints: ['Encoding / key generation', 'Data store choice', 'Caching layer', 'Scaling reads & writes'],
    ),
    Question(
      id: 'q4',
      prompt: 'Where do you see yourself in five years, and how does this role fit that path?',
      category: 'Behavioral',
      modelAnswer:
          'Show ambition aligned with the company. Connect your growth goals to the impact you want to have and how this role builds the skills to get there.',
      keyPoints: ['Genuine motivation', 'Alignment with the role', 'Growth mindset'],
    ),
    Question(
      id: 'q5',
      prompt: 'Which data structure gives O(1) average time for insert, delete, and lookup?',
      category: 'Technical',
      options: ['Array', 'Hash table', 'Binary search tree', 'Linked list'],
      correctIndex: 1,
      modelAnswer:
          'A hash table provides amortised O(1) insert, delete, and lookup by mapping keys to buckets via a hash function.',
    ),
    Question(
      id: 'q6',
      prompt: 'Describe a time you received difficult feedback. How did you respond?',
      category: 'Behavioral',
      modelAnswer:
          'Demonstrate self-awareness and growth. Describe the feedback honestly, how you processed it without defensiveness, the concrete change you made, and the result.',
      keyPoints: ['Openness to feedback', 'Concrete change made', 'Positive outcome'],
    ),
  ];

  /// Questions "extracted" from an uploaded resume (mock).
  static const List<Question> resumeBank = [
    Question(
      id: 'r1',
      prompt: 'Your resume mentions leading a migration to a microservices architecture. Walk me through that decision.',
      category: 'Experience',
      modelAnswer:
          'Explain the pain points of the monolith, why microservices addressed them, the migration strategy (strangler pattern), and the measurable improvements afterwards.',
      keyPoints: ['Motivation for change', 'Migration strategy', 'Measured impact'],
    ),
    Question(
      id: 'r2',
      prompt: 'You list Flutter as a core skill. How do you manage state in a large Flutter application?',
      category: 'Technical',
      modelAnswer:
          'Compare approaches (setState, Provider, Riverpod, Bloc), discuss separating UI from business logic, and choosing based on team size and complexity.',
      keyPoints: ['State options compared', 'Separation of concerns', 'Justified choice'],
    ),
    Question(
      id: 'r3',
      prompt: 'Your CV says you improved app performance by 40%. How did you measure and achieve that?',
      category: 'Experience',
      modelAnswer:
          'Describe profiling tools used to find bottlenecks, the specific optimisations (lazy loading, caching, reducing rebuilds), and how you measured the before/after.',
      keyPoints: ['Profiling / measurement', 'Specific optimisations', 'Validated result'],
    ),
    Question(
      id: 'r4',
      prompt: 'You worked at a startup and an enterprise. How did your engineering approach differ between them?',
      category: 'Behavioral',
      modelAnswer:
          'Contrast speed vs. process, ownership breadth, and how you adapted communication and rigor to each environment.',
      keyPoints: ['Awareness of context', 'Adaptability', 'Concrete examples'],
    ),
  ];
}
