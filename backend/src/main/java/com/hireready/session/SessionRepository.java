package com.hireready.session;

import com.hireready.common.enums.SessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SessionRepository extends JpaRepository<PracticeSession, UUID> {
    List<PracticeSession> findByUserIdOrderByStartedAtDesc(Long userId);

    long countByUserIdAndStatus(Long userId, SessionStatus status);
}
