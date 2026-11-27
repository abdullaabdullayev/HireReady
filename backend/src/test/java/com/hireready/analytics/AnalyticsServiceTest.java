package com.hireready.analytics;

import com.hireready.answer.AnswerRecord;
import com.hireready.answer.AnswerRepository;
import com.hireready.common.enums.SessionStatus;
import com.hireready.question.Question;
import com.hireready.session.SessionRepository;
import com.hireready.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.tuple;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class AnalyticsServiceTest {

    private static final long USER_ID = 7L;

    private SessionRepository sessions;
    private AnswerRepository answers;
    private AnalyticsService service;
    private User user;

    @BeforeEach
    void setUp() {
        sessions = mock(SessionRepository.class);
        answers = mock(AnswerRepository.class);
        service = new AnalyticsService(sessions, answers);
        user = mock(User.class);
        when(user.getId()).thenReturn(USER_ID);
        when(answers.findByUserIdSince(eq(USER_ID), any())).thenReturn(List.of());
    }

    @Test
    void emptyHistoryGivesZeroes() {
        when(answers.findAllByUserId(USER_ID)).thenReturn(List.of());

        AnalyticsResponse result = service.overview(user);

        assertThat(result.sessions()).isZero();
        assertThat(result.questions()).isZero();
        assertThat(result.avgScore()).isZero();
        assertThat(result.dayStreak()).isZero();
        assertThat(result.weekly()).hasSize(7).allMatch(d -> d.count() == 0);
        assertThat(result.skills()).isEmpty();
    }

    @Test
    void computesAverageStreakAndSkillBreakdown() {
        Instant now = Instant.now();
        when(answers.findAllByUserId(USER_ID)).thenReturn(List.of(
                answer("Java", 80, now),
                answer("Java", 60, now.minus(Duration.ofDays(1))),
                answer("SQL", 40, now.minus(Duration.ofDays(2))),
                answer("SQL", 100, now.minus(Duration.ofDays(5)))));
        when(sessions.countByUserIdAndStatus(USER_ID, SessionStatus.COMPLETED)).thenReturn(3L);

        AnalyticsResponse result = service.overview(user);

        assertThat(result.sessions()).isEqualTo(3);
        assertThat(result.questions()).isEqualTo(4);
        assertThat(result.avgScore()).isEqualTo(70);
        assertThat(result.dayStreak()).isEqualTo(3);
        assertThat(result.skills())
                .extracting(AnalyticsResponse.SkillScore::name, AnalyticsResponse.SkillScore::percent)
                .containsExactly(tuple("Java", 70), tuple("SQL", 70));
    }

    @Test
    void streakBreaksOnMissedDay() {
        Instant now = Instant.now();
        when(answers.findAllByUserId(USER_ID)).thenReturn(List.of(
                answer("Java", 50, now),
                answer("Java", 50, now.minus(Duration.ofDays(2)))));

        assertThat(service.overview(user).dayStreak()).isEqualTo(1);
    }

    private static AnswerRecord answer(String category, int score, Instant at) {
        Question q = new Question();
        q.setCategory(category);
        AnswerRecord a = new AnswerRecord();
        a.setQuestion(q);
        a.setScore(score);
        a.setCreatedAt(at);
        return a;
    }
}
