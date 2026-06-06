package com.hireready.document;


import com.hireready.common.enums.DocumentType;
import com.hireready.common.enums.ExtractionStatus;
import com.hireready.user.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "documents")
@Getter
@Setter
public class Document {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private DocumentType type;

    @Column(nullable = false)
    private String name;

    @Column(name = "content_type")
    private String contentType;

    @Column(name = "size_bytes")
    private long sizeBytes;

    @Column(name = "storage_key", nullable = false)
    private String storageKey;

    @Enumerated(EnumType.STRING)
    @Column(name = "extraction_status")
    private ExtractionStatus extractionStatus = ExtractionStatus.NOT_NEEDED;

    @Column(name = "extracted_text", columnDefinition = "TEXT")
    private String extractedText;

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();


}
