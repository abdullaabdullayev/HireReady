package com.hireready.question;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface QuestionRepository extends JpaRepository<Question, UUID> {
    List<Question> findByCategoryInAndOwnerUserIdIsNull(List<String> categories);
    List<Question> findByOwnerUserIdIsNull();
    List<Question> findBySourceDocumentIdOrderBySeqAsc(UUID sourceDocumentId);
}
