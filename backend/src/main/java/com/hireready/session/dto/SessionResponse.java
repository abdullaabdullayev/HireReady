package com.hireready.session.dto;

import com.hireready.session.PracticeSession;

import java.util.List;
import java.util.UUID;

public record SessionResponse(
        UUID id,
        String status,
        List<QuestionResponse> questions
) {
    public static SessionResponse from(PracticeSession s) {
        return new SessionResponse(
                s.getId(),
                s.getStatus().name(),
                s.getQuestions().stream().map(QuestionResponse::from).toList());
    }
}
