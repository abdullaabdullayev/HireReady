package com.hireready.auth;

import com.hireready.auth.dto.LoginRequest;
import com.hireready.auth.dto.RegisterRequest;
import com.hireready.user.User;
import com.hireready.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authManager;
    private final JwtUtil jwtUtil;

    @PostMapping("/register")
    public ResponseEntity<String> register(@RequestBody RegisterRequest registerRequest) {

        if (userRepository.findByEmail(registerRequest.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Email already exists");
        }

        User user = new User();
        user.setEmail(registerRequest.getEmail());
        user.setName(registerRequest.getName());
        user.setPasswordHash(passwordEncoder.encode(registerRequest.getPassword()));
        user.setRole(Role.ROLE_USER);

        userRepository.save(user);
        return ResponseEntity.ok().body("User registered successfully");
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest loginRequest) {
        authManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        loginRequest.getEmail(),
                        loginRequest.getPassword()
                )
        );
        User user = userRepository.findByEmail(loginRequest.getEmail()).orElseThrow();

        String accessToken = jwtUtil.generateAccessToken(user.getEmail(), user.getName());
        String refreshToken = jwtUtil.generateRefreshToken();
        user.setRefreshToken(refreshToken);
        user.setRefreshTokenExpiry(LocalDateTime.now().plusDays(7));

        userRepository.save(user);
        return ResponseEntity.ok(Map.of(
                "accessToken", accessToken,
                "refreshToken", refreshToken
        ));

    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody Map<String, String> body) {
        String refreshToken = body.get("refreshToken");

        User user = userRepository.findByRefreshToken(refreshToken)
                .orElseThrow(() -> new RuntimeException("Refresh token not found"));

        if (user.getRefreshTokenExpiry().isBefore(LocalDateTime.now())) {
            return ResponseEntity.status(401).body("Refresh token expired");
        }

        String newAccessToken = jwtUtil.generateAccessToken(user.getEmail(), user.getName());

        return ResponseEntity.ok(Map.of("accessToken", newAccessToken));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody Map<String, String> body) {
        String refreshToken = body.get("refreshToken");

        userRepository.findByRefreshToken(refreshToken).ifPresent(user -> {
            user.setRefreshToken(null);
            user.setRefreshTokenExpiry(null);
            userRepository.save(user);
        });

        return ResponseEntity.ok("Logout successfully");
    }
}
