package com.hireready;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/** Boots the full application context (security, JPA mappings, seeders) against a disposable PostgreSQL. */
@SpringBootTest(properties = {
        "jwt.secret=test-secret-key-that-is-at-least-32-bytes-long",
        "ai.groq.api-key=test-key",
        "app.storage.r2.account-id=test-account",
        "app.storage.r2.access-key=test-access",
        "app.storage.r2.secret-key=test-secret",
        "app.storage.r2.bucket=test-bucket"
})
@Testcontainers(disabledWithoutDocker = true)
class HireReadyApplicationTests {

    @Container
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:16-alpine");

    @DynamicPropertySource
    static void database(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Test
    void contextLoads() {
    }
}
