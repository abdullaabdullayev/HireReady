package com.hireready.session;

import com.hireready.answer.AnswerRecord;
import com.hireready.answer.AnswerRepository;
import com.hireready.common.enums.SessionStatus;
import com.hireready.question.Question;
import com.hireready.question.QuestionRepository;
import com.hireready.session.dto.CreateSessionRequest;
import com.hireready.session.dto.EvaluationResponse;
import com.hireready.session.dto.SessionResponse;
import com.hireready.session.dto.SessionSummaryResponse;
import com.hireready.session.dto.SubmitAnswerRequest;
import com.hireready.user.CustomUserDetails;
import com.hireready.user.User;
import com.hireready.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SessionService {

    private final SessionRepository sessionRepo;
    private final QuestionRepository questionRepo;
    private final AnswerRepository answerRepo;
    private final UserRepository userRepository;
    private final EvaluationService evaluationService;

    private static final int QUESTIONS_PER_SESSION = 6;

    @Transactional
    public SessionResponse create(User user, CreateSessionRequest req) {
        PracticeSession s = new PracticeSession();
        s.setUser(user);
        s.setRoleId(req.getRoleId());
        s.setLevel(req.getLevel());
        s.setFocusAreas(req.getFocusAreas() == null ? new ArrayList<>() : req.getFocusAreas());

        s.setQuestions(pickQuestions(s.getFocusAreas()));
        sessionRepo.save(s);
        return SessionResponse.from(s);
    }

    private List<Question> pickQuestions(List<String> focusAreas) {
        List<Question> pool = (focusAreas == null || focusAreas.isEmpty())
                ? questionRepo.findAll()
                : questionRepo.findByCategoryIn(focusAreas);

        if (pool.isEmpty()) pool = questionRepo.findAll();

        List<Question> shuffled = new ArrayList<>(pool);
        Collections.shuffle(shuffled);
        return shuffled.subList(0, Math.min(QUESTIONS_PER_SESSION, shuffled.size()));
    }

    @Transactional(readOnly = true)
    public PracticeSession get(UUID id, User user) {
        PracticeSession s = sessionRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Session not found"));
        if (!s.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Not your session");
        }
        return s;
    }

    @Transactional(readOnly = true)
    public SessionResponse getResponse(UUID id, User user) {
        return SessionResponse.from(get(id, user));
    }

    @Transactional
    public EvaluationResponse submitAnswer(UUID sessionId, User user, SubmitAnswerRequest req) {
        PracticeSession s = get(sessionId, user);
        Question q = questionRepo.findById(req.getQuestionId())
                .orElseThrow(() -> new RuntimeException("Question not found"));

        EvaluationService.Result r =
                evaluationService.evaluate(q, req.getText(), req.getSelectedOption());

        AnswerRecord a = new AnswerRecord();
        a.setSession(s);
        a.setQuestion(q);
        a.setTextAnswer(req.getText());
        a.setSelectedOption(req.getSelectedOption());
        a.setAnsweredByVoice(req.isAnsweredByVoice());
        a.setScore(r.score());
        a.setCorrect(r.correct());
        a.setFeedback(r.feedback());
        answerRepo.save(a);
        return EvaluationResponse.from(a);
    }

    @Transactional
    public void setMarkedForReview(UUID sessionId, User user, UUID answerId, boolean marked) {
        get(sessionId, user);
        AnswerRecord a = answerRepo.findById(answerId)
                .orElseThrow(() -> new RuntimeException("Answer not found"));
        a.setMarkedForReview(marked);
        answerRepo.save(a);
    }

    @Transactional
    public SessionSummaryResponse complete(UUID sessionId, User user) {
        PracticeSession s = get(sessionId, user);
        List<AnswerRecord> answers = answerRepo.findBySessionId(sessionId);
        int avg = answers.isEmpty() ? 0
                : (int) Math.round(answers.stream().mapToInt(AnswerRecord::getScore).average().orElse(0));
        s.setAverageScore(avg);
        s.setStatus(SessionStatus.COMPLETED);
        s.setCompletedAt(Instant.now());
        sessionRepo.save(s);

        int correct = (int) answers.stream().filter(AnswerRecord::isCorrect).count();
        return new SessionSummaryResponse(avg, correct, answers.size());
    }

    @Transactional(readOnly = true)
    public List<SessionResponse> historyResponse(User user) {
        return sessionRepo.findByUserIdOrderByStartedAtDesc(user.getId())
                .stream().map(SessionResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public List<AnswerRecord> answers(UUID sessionId, User user) {
        get(sessionId, user);
        return answerRepo.findBySessionId(sessionId);
    }

    public User currentUser(CustomUserDetails principal) {
        return userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}