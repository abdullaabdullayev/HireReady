package com.hireready.analytics;

import com.hireready.user.CustomUserDetails;
import com.hireready.user.User;
import com.hireready.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
public class AnalyticsController {

    private final AnalyticsService service;
    private final UserRepository userRepository;

    @GetMapping
    public AnalyticsResponse get(@AuthenticationPrincipal CustomUserDetails principal) {
        User user = userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new RuntimeException("User not found"));
        return service.overview(user);
    }
}
