package com.hireready.question;

import com.hireready.common.enums.QuestionType;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class QuestionSeeder implements CommandLineRunner {

    private final QuestionRepository repo;

    @Override
    public void run(String... args) throws Exception {

        if (!repo.findByOwnerUserIdIsNull().isEmpty()) return;

        repo.save(open(
                "Tell me about a challenging project you worked on. What made it hard and how did you handle it?",
                "Behavioral",
                "Use the STAR method: Situation, Task, Action, Result. Emphasise ownership, trade-offs, and what you learned.",
                List.of("Clear situation/context", "Your specific actions", "Measurable outcome", "Lesson learned")));

        repo.save(open(
                "How would you design a URL shortener that handles millions of requests per day?",
                "System Design",
                "Discuss requirements, a hashing/encoding scheme, a key-value store, caching for hot links, sharding, and read-vs-write scaling.",
                List.of("Encoding / key generation", "Data store choice", "Caching layer", "Scaling reads & writes")));

        repo.save(open(
                "Where do you see yourself in five years, and how does this role fit that path?",
                "Behavioral",
                "Show ambition aligned with the company. Connect growth goals to the impact you want and how this role builds those skills.",
                List.of("Genuine motivation", "Alignment with the role", "Growth mindset")));

        repo.save(open(
                "Describe a time you received difficult feedback. How did you respond?",
                "Behavioral",
                "Demonstrate self-awareness and growth: the feedback, how you processed it without defensiveness, the change you made, the result.",
                List.of("Openness to feedback", "Concrete change made", "Positive outcome")));

        repo.save(mc(
                "Which data structure gives O(1) average time for insert, delete, and lookup?",
                "Technical",
                List.of("Array", "Hash table", "Binary search tree", "Linked list"), 1,
                "A hash table provides amortised O(1) insert, delete, and lookup via a hash function."));

        repo.save(mc(
                "What is the difference between \"let\", \"const\", and \"var\" in JavaScript?",
                "Technical",
                List.of(
                        "They are identical and interchangeable",
                        "var is function-scoped; let/const are block-scoped, const cannot be reassigned",
                        "const is function-scoped; let/var are block-scoped",
                        "Only var can be used inside loops"), 1,
                "var is function-scoped and hoisted. let/const are block-scoped; const cannot be reassigned."));

    }

    private Question open(String prompt, String category, String model, List<String> keyPoints) {
        Question q = new Question();
        q.setPrompt(prompt);
        q.setCategory(category);
        q.setType(QuestionType.OPEN);
        q.setModelAnswer(model);
        q.setKeyPoints(keyPoints);
        return q;
    }

    private Question mc(String prompt, String category, List<String> options, int correct, String model) {
        Question q = new Question();
        q.setPrompt(prompt);
        q.setCategory(category);
        q.setType(QuestionType.MULTIPLE_CHOICE);
        q.setOptions(options);
        q.setCorrectIndex(correct);
        q.setModelAnswer(model);
        return q;
    }
}
