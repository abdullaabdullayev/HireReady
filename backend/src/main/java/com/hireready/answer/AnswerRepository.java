package com.hireready.answer;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface AnswerRepository extends JpaRepository<AnswerRecord, UUID> {

    List<AnswerRecord> findBySessionId(UUID sessionId);

    @Query("select a from AnswerRecord a where a.session.user.id = :userId")
    List<AnswerRecord> findAllByUserId(@Param("userId") Long userId);

    @Query("select a from AnswerRecord a where a.session.user.id = :userId and a.createdAt >= :since")
    List<AnswerRecord> findByUserIdSince(@Param("userId") Long userId, @Param("since") Instant since);

    long countBySessionUserId(Long userId);
}
