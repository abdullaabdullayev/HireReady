package com.hireready.session.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class SubmitAnswerRequest {
    private UUID questionId;
    private String text;
    private Integer selectedOption;
    private boolean answeredByVoice;
}
