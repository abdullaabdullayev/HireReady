package com.hireready.document;

import java.util.UUID;

public record DocumentResponse(
        UUID id,
        String name,
        String type,
        long sizeBytes,

        String extractionStatus
) {

    public static DocumentResponse from(Document d) {
        return new DocumentResponse(
                d.getId(),
                d.getName(),
                d.getType().name(),
                d.getSizeBytes(),
                d.getExtractionStatus().name()
        );
    }
}
