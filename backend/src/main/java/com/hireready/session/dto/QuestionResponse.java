package com.hireready.session.dto;

import com.hireready.question.Question;

import java.util.List;
import java.util.UUID;

public record QuestionResponse (
        UUID id,
        String prompt,
        String category,
        String type,
        List<String> options,
        Integer correctIndex,
        String modelAnswer,
        List<String> keyPoints
){
    public static QuestionResponse from(Question q) {
        return new QuestionResponse(
                q.getId(), q.getPrompt(), q.getCategory(), q.getType().name(),
                q.getOptions(), q.getCorrectIndex(), q.getModelAnswer(), q.getKeyPoints());
    }
}
