package com.hireready.session.dto;

import com.hireready.answer.AnswerRecord;

import java.util.UUID;

public record AnswerResponse(
        UUID id,
        UUID questionId,
        String textAnswer,
        Integer selectedOption,
        boolean answeredByVoice,
        int score,
        boolean correct,
        String feedback,
        boolean markedForReview
) {
    public static AnswerResponse from(AnswerRecord a) {
        return new AnswerResponse(
                a.getId(),
                a.getQuestion().getId(),
                a.getTextAnswer(),
                a.getSelectedOption(),
                a.isAnsweredByVoice(),
                a.getScore(),
                a.isCorrect(),
                a.getFeedback(),
                a.isMarkedForReview());
    }
}
