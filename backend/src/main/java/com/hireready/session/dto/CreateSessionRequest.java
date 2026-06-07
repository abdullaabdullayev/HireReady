package com.hireready.session.dto;

import com.hireready.common.enums.ExperienceLevel;
import lombok.Getter;
import lombok.Setter;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
public class CreateSessionRequest {

    private String roleId;
    private ExperienceLevel level;
    private List<String> focusAreas;
    private UUID questionsFileId;
    private Long resumeFileId;
}
