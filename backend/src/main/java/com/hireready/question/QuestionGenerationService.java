package com.hireready.question;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hireready.ai.AiClient;
import com.hireready.common.enums.ExperienceLevel;
import com.hireready.common.enums.QuestionType;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class QuestionGenerationService {

    private final AiClient aiClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final int MAX_DOC_CHARS = 8000;

    private static final String OUTPUT_FORMAT = """
            Reply with ONLY a JSON object, no markdown:
            {"questions": [{
              "prompt": "<the question>",
              "category": "<one of: Behavioral, Technical, System Design, Experience, Culture fit>",
              "type": "<OPEN or MULTIPLE_CHOICE>",
              "options": ["<4 answer options, MULTIPLE_CHOICE only, otherwise []>"],
              "correctIndex": <index into options for MULTIPLE_CHOICE, otherwise null>,
              "modelAnswer": "<short reference answer>",
              "keyPoints": ["<thing a strong answer should cover>"]
            }]}
            """;

    public List<Question> generateFromDocuments(String roleTitle, ExperienceLevel level,
                                                List<String> focusAreas,
                                                String resumeText, List<String> referenceTexts,
                                                List<String> avoidPrompts,
                                                int count) {
        String system = """
                You are an expert interviewer preparing a mock interview.
                Create %d interview questions tailored to this candidate.
                Ground the questions in the candidate's resume (their actual projects, skills and
                experience) and in the provided reference material, referring to them where relevant.
                Never repeat or closely paraphrase a question the candidate has already practiced.
                """.formatted(count) + OUTPUT_FORMAT;

        StringBuilder user = new StringBuilder();
        user.append("Target role: ").append(roleTitle == null ? "(not specified)" : roleTitle).append('\n');
        user.append("Experience level: ").append(level == null ? "(not specified)" : level).append('\n');
        if (focusAreas != null && !focusAreas.isEmpty()) {
            user.append("Focus areas: ").append(String.join(", ", focusAreas)).append('\n');
        }
        if (resumeText != null && !resumeText.isBlank()) {
            user.append("\nCandidate's resume:\n\"\"\"\n").append(truncate(resumeText)).append("\n\"\"\"\n");
        }
        if (referenceTexts != null) {
            int i = 1;
            for (String ref : referenceTexts) {
                if (ref == null || ref.isBlank()) continue;
                user.append("\nReference material ").append(i++).append(":\n\"\"\"\n")
                        .append(truncate(ref)).append("\n\"\"\"\n");
            }
        }
        if (avoidPrompts != null && !avoidPrompts.isEmpty()) {
            user.append("\nQuestions the candidate has ALREADY practiced (do not repeat these):\n");
            avoidPrompts.stream().limit(25).forEach(p ->
                    user.append("- ").append(p.length() > 200 ? p.substring(0, 200) : p).append('\n'));
        }
        return parse(aiClient.chat(system, user.toString()), level, count);
    }

    public List<Question> extractFromQuestionsFile(String fileText, ExperienceLevel level, int max) {
        String system = """
                You are given the text of a document that contains interview questions.
                Extract the questions that actually appear in the document - do not invent new ones.
                Keep their original wording and order. If a question comes with answer options, use
                type MULTIPLE_CHOICE and include the options (and correctIndex when the document
                indicates the right answer). Provide a modelAnswer and keyPoints for every question
                using your own expertise so the candidate's answer can be graded.
                """ + OUTPUT_FORMAT;

        String user = "Document text:\n\"\"\"\n" + truncate(fileText) + "\n\"\"\"";
        return parse(aiClient.chat(system, user), level, max);
    }

    private List<Question> parse(String raw, ExperienceLevel level, int max) {
        List<Question> out = new ArrayList<>();
        try {
            JsonNode arr = objectMapper.readTree(raw).path("questions");
            for (JsonNode n : arr) {
                if (out.size() >= max) break;
                String prompt = n.path("prompt").asText("").trim();
                if (prompt.isEmpty()) continue;

                Question q = new Question();
                q.setPrompt(prompt);
                q.setCategory(n.path("category").asText("General"));
                q.setModelAnswer(n.path("modelAnswer").asText(""));
                q.setLevel(level);

                List<String> keyPoints = new ArrayList<>();
                n.path("keyPoints").forEach(k -> keyPoints.add(k.asText()));
                q.setKeyPoints(keyPoints);

                List<String> options = new ArrayList<>();
                n.path("options").forEach(o -> options.add(o.asText()));
                JsonNode ci = n.path("correctIndex");
                boolean multipleChoice = "MULTIPLE_CHOICE".equalsIgnoreCase(n.path("type").asText(""))
                        && options.size() >= 2
                        && ci.isInt() && ci.asInt() >= 0 && ci.asInt() < options.size();
                if (multipleChoice) {
                    q.setType(QuestionType.MULTIPLE_CHOICE);
                    q.setOptions(options);
                    q.setCorrectIndex(ci.asInt());
                } else {
                    q.setType(QuestionType.OPEN);
                }
                out.add(q);
            }
        } catch (Exception ignored) {}
        return out;
    }

    private String truncate(String s) {
        return s.length() > MAX_DOC_CHARS ? s.substring(0, MAX_DOC_CHARS) : s;
    }
}
