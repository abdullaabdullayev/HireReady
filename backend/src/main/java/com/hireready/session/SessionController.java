package com.hireready.session;

import com.hireready.session.dto.*;
import com.hireready.user.CustomUserDetails;
import com.hireready.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/sessions")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService service;

    @PostMapping
    public SessionResponse create(@AuthenticationPrincipal CustomUserDetails principal,
                                  @RequestBody CreateSessionRequest req) {
        User user = service.currentUser(principal);
        return service.create(user, req);
    }

    @GetMapping("/{id}")
    public SessionResponse get(@AuthenticationPrincipal CustomUserDetails principal,
                               @PathVariable UUID id) {
        User user = service.currentUser(principal);
        return service.getResponse(id, user);
    }

    @PostMapping("/{id}/answers")
    public EvaluationResponse submit(@AuthenticationPrincipal CustomUserDetails principal,
                                     @PathVariable UUID id,
                                     @RequestBody SubmitAnswerRequest req) {
        User user = service.currentUser(principal);
        return service.submitAnswer(id, user, req);
    }

    @PatchMapping("/{id}/answers/{answerId}")
    public void mark(@AuthenticationPrincipal CustomUserDetails principal,
                     @PathVariable UUID id,
                     @PathVariable UUID answerId,
                     @RequestParam boolean marked) {
        User user = service.currentUser(principal);
        service.setMarkedForReview(id, user, answerId, marked);
    }

    @PostMapping("/{id}/complete")
    public SessionSummaryResponse complete(@AuthenticationPrincipal CustomUserDetails principal,
                                           @PathVariable UUID id) {
        User user = service.currentUser(principal);
        return service.complete(id, user);
    }

    @GetMapping
    public List<SessionResponse> history(@AuthenticationPrincipal CustomUserDetails principal) {
        User user = service.currentUser(principal);
        return service.historyResponse(user);
    }
}