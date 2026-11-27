package com.hireready.session;

import com.hireready.ai.AiClient;
import com.hireready.common.enums.QuestionType;
import com.hireready.question.Question;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class EvaluationServiceTest {

    private static final String LONG_ANSWER =
            "I would design the cache with a time to live and invalidate entries on every write";

    private AiClient aiClient;
    private EvaluationService service;

    @BeforeEach
    void setUp() {
        aiClient = mock(AiClient.class);
        service = new EvaluationService(aiClient);
    }

    @Test
    void multipleChoiceCorrectOptionScoresFull() {
        EvaluationService.Result result = service.evaluate(multipleChoice(2), null, 2);

        assertThat(result.score()).isEqualTo(100);
        assertThat(result.correct()).isTrue();
        assertThat(result.feedback()).startsWith("Correct.");
        verifyNoInteractions(aiClient);
    }

    @Test
    void multipleChoiceWrongOrMissingOptionScoresZero() {
        assertThat(service.evaluate(multipleChoice(2), null, 1).score()).isZero();
        assertThat(service.evaluate(multipleChoice(2), null, null).correct()).isFalse();
    }

    @Test
    void tooShortOpenAnswerIsRejectedWithoutCallingAi() {
        EvaluationService.Result result = service.evaluate(open(List.of("caching")), "use a cache", null);

        assertThat(result.score()).isEqualTo(15);
        assertThat(result.correct()).isFalse();
        assertThat(result.feedback()).contains("too short").contains("caching");
        verifyNoInteractions(aiClient);
    }

    @Test
    void aiScoreAndFeedbackAreUsed() {
        when(aiClient.chat(anyString(), anyString()))
                .thenReturn("{\"score\": 82, \"feedback\": \"Clear and structured.\"}");

        EvaluationService.Result result = service.evaluate(open(List.of()), LONG_ANSWER, null);

        assertThat(result.score()).isEqualTo(82);
        assertThat(result.correct()).isTrue();
        assertThat(result.feedback()).isEqualTo("Clear and structured.");
    }

    @Test
    void aiScoreIsClampedAndEmptyFeedbackReplaced() {
        when(aiClient.chat(anyString(), anyString())).thenReturn("{\"score\": 250, \"feedback\": \"\"}");

        EvaluationService.Result result = service.evaluate(open(List.of()), LONG_ANSWER, null);

        assertThat(result.score()).isEqualTo(100);
        assertThat(result.feedback()).isEqualTo("Evaluated.");
    }

    @Test
    void fallsBackToRuleBasedScoringWhenAiFails() {
        when(aiClient.chat(anyString(), anyString())).thenThrow(new RuntimeException("LLM unavailable"));

        EvaluationService.Result result =
                service.evaluate(open(List.of("invalidate cache", "latency budget")), LONG_ANSWER, null);

        assertThat(result.score()).isBetween(0, 100);
        assertThat(result.feedback()).contains("latency budget").doesNotContain("invalidate cache");
    }

    @Test
    void fallsBackWhenAiReturnsInvalidJson() {
        when(aiClient.chat(anyString(), anyString())).thenReturn("not json");

        EvaluationService.Result result = service.evaluate(open(List.of("invalidate")), LONG_ANSWER, null);

        assertThat(result.feedback()).startsWith("Strong");
    }

    private static Question multipleChoice(int correctIndex) {
        Question q = new Question();
        q.setType(QuestionType.MULTIPLE_CHOICE);
        q.setOptions(List.of("A", "B", "C", "D"));
        q.setCorrectIndex(correctIndex);
        q.setModelAnswer("Option C is right.");
        return q;
    }

    private static Question open(List<String> keyPoints) {
        Question q = new Question();
        q.setType(QuestionType.OPEN);
        q.setPrompt("How would you design a cache?");
        q.setCategory("System design");
        q.setKeyPoints(keyPoints);
        return q;
    }
}
