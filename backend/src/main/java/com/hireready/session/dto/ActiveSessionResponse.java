package com.hireready.session.dto;

import com.hireready.answer.AnswerRecord;
import com.hireready.session.PracticeSession;

import java.util.List;
import java.util.UUID;

public record ActiveSessionResponse(
        UUID id,
        String status,
        List<QuestionResponse> questions,
        List<AnswerResponse> answers
) {
    public static ActiveSessionResponse from(PracticeSession s, List<AnswerRecord> answers) {
        return new ActiveSessionResponse(
                s.getId(),
                s.getStatus().name(),
                s.getQuestions().stream().map(QuestionResponse::from).toList(),
                answers.stream().map(AnswerResponse::from).toList());
    }
}
