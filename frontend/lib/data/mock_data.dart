import '../models/app_models.dart';

/// Static mock content still used while backend endpoints are not yet ready.
/// Roles have been moved to the backend (/api/roles) and RoleService.
class MockData {

  static const List<UploadedResource> sampleResources = [
    UploadedResource(name: 'Resume_2026.pdf', type: 'PDF', sizeBytes: 248 * 1024),
    UploadedResource(name: 'Job_Description.pdf', type: 'PDF', sizeBytes: 92 * 1024),
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

  /// Questions "extracted" from a custom questions file the user uploads in
  /// the Set requirements step (mock).
  static const List<Question> customFileBank = [
    Question(
      id: 'c1',
      prompt: 'Explain the difference between optimistic and pessimistic locking, and when you would use each.',
      category: 'Technical',
      modelAnswer:
          'Optimistic locking assumes conflicts are rare and validates at commit (version checks); pessimistic locking blocks others by acquiring locks up front. Use optimistic for low-contention/high-throughput, pessimistic for high-contention critical sections.',
      keyPoints: ['Optimistic vs pessimistic', 'Contention trade-off', 'Concrete use case'],
    ),
    Question(
      id: 'c2',
      prompt: 'Describe a time you disagreed with a teammate on a technical decision. How was it resolved?',
      category: 'Behavioral',
      modelAnswer:
          'Use STAR. Show that you listened, backed your view with data or a prototype, stayed respectful, and aligned on a shared decision and outcome.',
      keyPoints: ['Healthy disagreement', 'Evidence-based', 'Resolution & outcome'],
    ),
    Question(
      id: 'c3',
      prompt: 'What happens, step by step, when you type a URL into the browser and press Enter?',
      category: 'Technical',
      modelAnswer:
          'DNS resolution, TCP/TLS handshake, HTTP request, server response, then parsing HTML/CSS/JS, building the DOM/CSSOM, rendering and painting. Mention caching and CDNs.',
      keyPoints: ['DNS & connection', 'Request/response', 'Render pipeline'],
    ),
    Question(
      id: 'c4',
      prompt: 'How do you prioritise tasks when everything feels urgent and the deadline is tight?',
      category: 'Behavioral',
      modelAnswer:
          'Clarify impact vs effort, align with stakeholders on must-haves vs nice-to-haves, communicate trade-offs early, and protect focus on the highest-leverage work.',
      keyPoints: ['Impact vs effort', 'Stakeholder alignment', 'Clear communication'],
    ),
    Question(
      id: 'c5',
      prompt: 'What is idempotency and why does it matter for API design?',
      category: 'Technical',
      options: [
        'An operation that can only run once',
        'An operation that produces the same result no matter how many times it is applied',
        'An operation that always fails safely',
        'An operation that requires authentication',
      ],
      correctIndex: 1,
      modelAnswer:
          'Idempotency means repeating a request yields the same result/state. It matters for safe retries on network failures (e.g., PUT/DELETE, idempotency keys for payments).',
    ),
  ];
}
