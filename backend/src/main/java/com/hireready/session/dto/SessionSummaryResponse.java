package com.hireready.session.dto;

import com.hireready.session.PracticeSession;

public record SessionSummaryResponse(
        int averageScore,
        int correct,
        int total
) {
    public static SessionSummaryResponse from(PracticeSession s) {
        int total = s.getAnswers().size();
        int correct = (int) s.getAnswers().stream().filter(a -> a.isCorrect()).count();
        int avg = total == 0 ? 0
                : (int) Math.round(s.getAnswers().stream().mapToInt(a -> a.getScore()).average().orElse(0));
        return new SessionSummaryResponse(avg, correct, total);
    }
}