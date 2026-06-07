package com.hireready.session.dto;

import com.hireready.answer.AnswerRecord;
import java.util.List;
import java.util.UUID;

public record EvaluationResponse(
        UUID answerId,
        int score,
        boolean correct,
        String feedback,
        String modelAnswer,
        List<String> keyPoints
) {
    public static EvaluationResponse from(AnswerRecord a) {
        return new EvaluationResponse(
                a.getId(), a.getScore(), a.isCorrect(), a.getFeedback(),
                a.getQuestion().getModelAnswer(), a.getQuestion().getKeyPoints());
    }
}