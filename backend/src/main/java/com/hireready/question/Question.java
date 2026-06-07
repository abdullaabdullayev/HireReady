package com.hireready.question;

import com.hireready.common.enums.ExperienceLevel;
import com.hireready.common.enums.QuestionType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "questions")
@Getter
@Setter
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String prompt;

    @Column(nullable = false)
    private String category;

    @Enumerated(EnumType.STRING)
    private QuestionType type = QuestionType.OPEN;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "question_options", joinColumns = @JoinColumn(name = "question_id"))
    private List<String> options = new ArrayList<>();

    private Integer correctIndex;

    @Column(columnDefinition = "TEXT")
    private String modelAnswer;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "question_key_points", joinColumns = @JoinColumn(name = "question_id"))
    @Column(name = "point", columnDefinition = "TEXT")
    private List<String> keyPoints = new ArrayList<>();

    private String roleId;

    @Enumerated(EnumType.STRING)
    private ExperienceLevel level;
}
