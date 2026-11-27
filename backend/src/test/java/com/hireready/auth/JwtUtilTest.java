package com.hireready.auth;

import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtUtilTest {

    private static final String SECRET = "test-secret-key-that-is-at-least-32-bytes-long";

    private JwtUtil jwtUtil;

    @BeforeEach
    void setUp() {
        jwtUtil = newJwtUtil(SECRET, 60_000);
    }

    @Test
    void generatedTokenCarriesEmailAsSubject() {
        String token = jwtUtil.generateAccessToken("ali@example.com", "Ali");

        assertThat(jwtUtil.extractEmail(token)).isEqualTo("ali@example.com");
    }

    @Test
    void tokenIsValidOnlyForItsOwner() {
        String token = jwtUtil.generateAccessToken("ali@example.com", "Ali");

        assertThat(jwtUtil.validateToken(token, user("ali@example.com"))).isTrue();
        assertThat(jwtUtil.validateToken(token, user("other@example.com"))).isFalse();
    }

    @Test
    void tokenSignedWithAnotherKeyIsRejected() {
        String foreign = newJwtUtil("another-secret-key-that-is-at-least-32-bytes", 60_000)
                .generateAccessToken("ali@example.com", "Ali");

        assertThatThrownBy(() -> jwtUtil.extractEmail(foreign)).isInstanceOf(JwtException.class);
    }

    @Test
    void expiredTokenIsRejected() {
        String expired = newJwtUtil(SECRET, -1_000).generateAccessToken("ali@example.com", "Ali");

        assertThatThrownBy(() -> jwtUtil.validateToken(expired, user("ali@example.com")))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void refreshTokensAreUnique() {
        assertThat(jwtUtil.generateRefreshToken()).isNotEqualTo(jwtUtil.generateRefreshToken());
    }

    private static JwtUtil newJwtUtil(String secret, long expirationMs) {
        JwtUtil util = new JwtUtil();
        ReflectionTestUtils.setField(util, "jwtSecret", secret);
        ReflectionTestUtils.setField(util, "expiration", expirationMs);
        return util;
    }

    private static UserDetails user(String email) {
        return User.withUsername(email).password("x").roles("USER").build();
    }
}
