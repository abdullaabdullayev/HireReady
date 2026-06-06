package com.hireready.document;

import com.hireready.common.enums.DocumentType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface DocumentRepository extends JpaRepository<Document, UUID> {

    List<Document> findByUserId(Long userId);
    List<Document> findByUserIdAndType(Long userId, DocumentType type);
}
