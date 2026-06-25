package com.hireready.session;

import com.hireready.common.enums.SessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

public interface SessionRepository extends JpaRepository<PracticeSession, UUID> {
    List<PracticeSession> findByUserIdOrderByStartedAtDesc(Long userId);

    long countByUserIdAndStatus(Long userId, SessionStatus status);

    List<PracticeSession> findByUserIdAndStatus(Long userId, SessionStatus status);

    Optional<PracticeSession> findFirstByUserIdAndStatusOrderByStartedAtDesc(Long userId, SessionStatus status);

    @Query("select q.id from PracticeSession s join s.questions q where s.user.id = :userId")
    Set<UUID> findSeenQuestionIds(@Param("userId") Long userId);
}
