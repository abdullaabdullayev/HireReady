package com.hireready.answer;

import com.hireready.question.Question;
import com.hireready.session.PracticeSession;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "answer_records")
@Getter
@Setter
public class AnswerRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private PracticeSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "question_id", nullable = false)
    private Question question;

    @Column(columnDefinition = "TEXT")
    private String textAnswer;

    private Integer selectedOption;
    private boolean answeredByVoice;

    private int score;
    private boolean correct;

    @Column(columnDefinition = "TEXT")
    private String feedback;

    private boolean markedForReview;

    private Instant createdAt = Instant.now();
}
