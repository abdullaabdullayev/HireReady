package com.hireready.session;

import com.hireready.answer.AnswerRecord;
import com.hireready.common.enums.ExperienceLevel;
import com.hireready.common.enums.SessionStatus;
import com.hireready.question.Question;
import com.hireready.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "practice_sessions")
@Getter
@Setter
public class PracticeSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private String roleId;

    @Enumerated(EnumType.STRING)
    private ExperienceLevel level;

    @ElementCollection
    @CollectionTable(name = "session_focus_areas", joinColumns = @JoinColumn(name = "session_id"))
    @Column(name = "area")
    private List<String> focusAreas = new ArrayList<>();

    @ManyToMany
    @JoinTable(
            name = "session_questions",
            joinColumns = @JoinColumn(name = "session_id"),
            inverseJoinColumns = @JoinColumn(name = "question_id"))
    @OrderColumn(name = "position")
    private List<Question> questions = new ArrayList<>();

    @OneToMany(mappedBy = "session", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AnswerRecord> answers = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    private SessionStatus status = SessionStatus.IN_PROGRESS;

    private Integer averageScore;

    private Instant startedAt = Instant.now();
    private Instant completedAt;
}
