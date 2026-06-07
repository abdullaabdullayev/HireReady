package com.hireready.session;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hireready.ai.AiClient;
import com.hireready.common.enums.QuestionType;
import com.hireready.question.Question;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class EvaluationService {

    private final AiClient aiClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public record Result(int score, boolean correct, String feedback) {}

    public Result evaluate(Question q, String text, Integer selectedOption) {
        if (q.getType() == QuestionType.MULTIPLE_CHOICE) {
            boolean correct = selectedOption != null
                    && selectedOption.equals(q.getCorrectIndex());
            return new Result(
                    correct ? 100 : 0,
                    correct,
                    (correct ? "Correct. " : "Not quite. ") + nz(q.getModelAnswer()));
        }

        String answer = text == null ? "" : text.trim();

        if (answer.split("\\s+").length < 5) {
            List<String> kp = q.getKeyPoints() == null ? List.of() : q.getKeyPoints();
            return new Result(15, false,
                    "Your answer is too short. Add structure and detail."
                            + (kp.isEmpty() ? "" : " Aim to cover: " + String.join(", ", kp) + "."));
        }

        try {
            return aiEvaluate(q, answer);
        } catch (Exception e) {
            return ruleBased(q, answer);
        }
    }

    private Result aiEvaluate(Question q, String answer) throws Exception {
        String system = """
                You are an expert interview coach grading a candidate's spoken/written answer.
                Grade fairly from 0 to 100. Consider relevance, structure (e.g. STAR for
                behavioral), depth, and whether the key points are covered.
                Reply with ONLY a JSON object, no markdown:
                {"score": <int 0-100>, "feedback": "<2-3 sentences, specific and actionable>"}
                """;

        String keyPoints = (q.getKeyPoints() == null || q.getKeyPoints().isEmpty())
                ? "(none provided)"
                : String.join("; ", q.getKeyPoints());

        String user = """
                Question: %s
                Category: %s
                Key points to look for: %s
                Reference answer: %s

                Candidate's answer:
                \"\"\"
                %s
                \"\"\"
                """.formatted(
                q.getPrompt(),
                nz(q.getCategory()),
                keyPoints,
                nz(q.getModelAnswer()),
                answer);

        String raw = aiClient.chat(system, user);
        JsonNode json = objectMapper.readTree(raw);

        int score = clamp(json.path("score").asInt(0));
        String feedback = json.path("feedback").asText("").trim();
        if (feedback.isEmpty()) feedback = "Evaluated.";
        boolean correct = score >= 60;
        return new Result(score, correct, feedback);
    }

    private Result ruleBased(Question q, String answer) {
        int words = answer.isEmpty() ? 0 : answer.split("\\s+").length;
        String lower = answer.toLowerCase();

        List<String> keyPoints = q.getKeyPoints() == null ? List.of() : q.getKeyPoints();
        List<String> missed = new ArrayList<>();
        int hits = 0;
        for (String k : keyPoints) {
            if (lower.contains(keyword(k))) hits++; else missed.add(k);
        }

        int lengthScore = (int) Math.round(Math.min(words, 80) / 80.0 * 60);
        int pointScore = keyPoints.isEmpty()
                ? 30
                : (int) Math.round((double) hits / keyPoints.size() * 40);
        int score = clamp(lengthScore + pointScore);
        boolean correct = score >= 60;

        String feedback;
        if (missed.isEmpty()) {
            feedback = "Strong, well-rounded answer that touches all the key areas. "
                    + "Tighten it with a concrete metric to make it memorable.";
        } else {
            feedback = "Good start. To strengthen it, also address: " + String.join(", ", missed) + ".";
        }
        return new Result(score, correct, feedback);
    }

    private String keyword(String k) {
        for (String w : k.toLowerCase().split(" ")) {
            if (w.length() > 3) return w;
        }
        return k.toLowerCase();
    }

    private int clamp(int v) { return Math.max(0, Math.min(100, v)); }

    private String nz(String s) { return s == null ? "" : s; }
}
