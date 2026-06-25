package com.hireready.session;

import com.hireready.answer.AnswerRecord;
import com.hireready.answer.AnswerRepository;
import com.hireready.common.enums.SessionStatus;
import com.hireready.document.Document;
import com.hireready.document.DocumentRepository;
import com.hireready.job.JobRole;
import com.hireready.job.JobRoleRepository;
import com.hireready.question.Question;
import com.hireready.question.QuestionGenerationService;
import com.hireready.question.QuestionRepository;
import com.hireready.session.dto.ActiveSessionResponse;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SessionService {

    private final SessionRepository sessionRepo;
    private final QuestionRepository questionRepo;
    private final AnswerRepository answerRepo;
    private final UserRepository userRepository;
    private final EvaluationService evaluationService;
    private final DocumentRepository documentRepo;
    private final JobRoleRepository jobRoleRepo;
    private final QuestionGenerationService questionGenerationService;

    private static final int QUESTIONS_PER_SESSION = 6;
    private static final int MAX_FILE_QUESTIONS = 40;

    @Transactional
    public SessionResponse create(User user, CreateSessionRequest req) {
        // Starting a new session abandons any unfinished one (the user chose not to resume).
        for (PracticeSession old : sessionRepo.findByUserIdAndStatus(user.getId(), SessionStatus.IN_PROGRESS)) {
            old.setStatus(SessionStatus.ABANDONED);
            sessionRepo.save(old);
        }

        PracticeSession s = new PracticeSession();
        s.setUser(user);
        s.setRoleId(req.getRoleId());
        s.setLevel(req.getLevel());
        s.setFocusAreas(req.getFocusAreas() == null ? new ArrayList<>() : req.getFocusAreas());

        s.setQuestions(buildQuestions(user, req));
        sessionRepo.save(s);
        return SessionResponse.from(s);
    }

    @Transactional(readOnly = true)
    public ActiveSessionResponse activeResponse(User user) {
        return sessionRepo
                .findFirstByUserIdAndStatusOrderByStartedAtDesc(user.getId(), SessionStatus.IN_PROGRESS)
                .map(s -> ActiveSessionResponse.from(s, answerRepo.findBySessionId(s.getId())))
                .orElse(null);
    }

    private List<Question> buildQuestions(User user, CreateSessionRequest req) {
        Set<UUID> seen = sessionRepo.findSeenQuestionIds(user.getId());
        List<Question> result = new ArrayList<>();

        // 1. Questions file: extract the whole file once, then progress through the
        //    not-yet-seen questions session by session (Duolingo-style).
        Document qFile = ownedDocument(user, req.getQuestionsFileId());
        if (qFile != null) {
            List<Question> fileQuestions = questionRepo.findBySourceDocumentIdOrderBySeqAsc(qFile.getId());
            if (fileQuestions.isEmpty()) {
                fileQuestions = extractFileQuestions(user, qFile, req);
            }
            fileQuestions.stream()
                    .filter(q -> !seen.contains(q.getId()))
                    .limit(QUESTIONS_PER_SESSION)
                    .forEach(result::add);
        }

        // 2. Resume + reference materials: AI generates fresh questions grounded in them,
        //    avoiding ones the user has already practiced.
        int remaining = QUESTIONS_PER_SESSION - result.size();
        if (remaining > 0) {
            String resumeText = extractedText(ownedDocument(user, req.getResumeFileId()));
            List<String> referenceTexts = new ArrayList<>();
            if (req.getReferenceFileIds() != null) {
                for (UUID id : req.getReferenceFileIds()) {
                    String t = extractedText(ownedDocument(user, id));
                    if (t != null) referenceTexts.add(t);
                }
            }
            if (resumeText != null || !referenceTexts.isEmpty()) {
                try {
                    List<Question> generated = questionGenerationService.generateFromDocuments(
                            roleTitle(req.getRoleId()), req.getLevel(), req.getFocusAreas(),
                            resumeText, referenceTexts, seenPrompts(seen), remaining);
                    for (Question q : generated) {
                        q.setOwnerUserId(user.getId());
                        q.setRoleId(req.getRoleId());
                    }
                    questionRepo.saveAll(generated);
                    result.addAll(generated);
                } catch (Exception ignored) {}
            }
        }

        // 3. Fill any remaining slots from the curated bank, preferring unseen questions.
        remaining = QUESTIONS_PER_SESSION - result.size();
        if (remaining > 0) {
            Set<String> seenPromptKeys = seenPrompts(seen).stream()
                    .map(SessionService::promptKey)
                    .collect(java.util.stream.Collectors.toSet());
            result.addAll(pickBankQuestions(req.getFocusAreas(), seen, seenPromptKeys, remaining));
        }
        return result;
    }

    private List<Question> extractFileQuestions(User user, Document qFile, CreateSessionRequest req) {
        String fileText = extractedText(qFile);
        if (fileText == null) return new ArrayList<>();
        try {
            List<Question> extracted = questionGenerationService.extractFromQuestionsFile(
                    fileText, req.getLevel(), MAX_FILE_QUESTIONS);
            for (int i = 0; i < extracted.size(); i++) {
                Question q = extracted.get(i);
                q.setSeq(i);
                q.setSourceDocumentId(qFile.getId());
                q.setOwnerUserId(user.getId());
                q.setRoleId(req.getRoleId());
            }
            questionRepo.saveAll(extracted);
            return extracted;
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private List<String> seenPrompts(Set<UUID> seen) {
        if (seen.isEmpty()) return List.of();
        return questionRepo.findAllById(seen).stream()
                .map(Question::getPrompt)
                .toList();
    }

    private static String promptKey(String prompt) {
        return prompt == null ? "" : prompt.trim().toLowerCase();
    }

    private List<Question> pickBankQuestions(List<String> focusAreas, Set<UUID> seenIds,
                                             Set<String> seenPromptKeys, int count) {
        List<Question> pool = (focusAreas == null || focusAreas.isEmpty())
                ? questionRepo.findByOwnerUserIdIsNull()
                : questionRepo.findByCategoryInAndOwnerUserIdIsNull(focusAreas);

        if (pool.isEmpty()) pool = questionRepo.findByOwnerUserIdIsNull();

        // Compare by prompt text as well as id so duplicate rows of the same
        // question never resurface as "new" ones.
        Map<String, Question> unseen = new LinkedHashMap<>();
        for (Question q : pool) {
            String key = promptKey(q.getPrompt());
            if (seenIds.contains(q.getId()) || seenPromptKeys.contains(key)) continue;
            unseen.putIfAbsent(key, q);
        }

        List<Question> candidates;
        if (unseen.isEmpty()) {
            // Once the whole bank has been practiced, recycle it rather than running dry.
            Map<String, Question> byPrompt = new LinkedHashMap<>();
            for (Question q : pool) byPrompt.putIfAbsent(promptKey(q.getPrompt()), q);
            candidates = new ArrayList<>(byPrompt.values());
        } else {
            candidates = new ArrayList<>(unseen.values());
        }
        Collections.shuffle(candidates);
        return candidates.subList(0, Math.min(count, candidates.size()));
    }

    private Document ownedDocument(User user, UUID id) {
        if (id == null) return null;
        Document doc = documentRepo.findById(id).orElse(null);
        if (doc == null || !doc.getUser().getId().equals(user.getId())) return null;
        return doc;
    }

    private String extractedText(Document doc) {
        if (doc == null || doc.getExtractedText() == null || doc.getExtractedText().isBlank()) {
            return null;
        }
        return doc.getExtractedText();
    }

    private String roleTitle(String roleId) {
        if (roleId == null) return null;
        return jobRoleRepo.findById(roleId).map(JobRole::getTitle).orElse(roleId);
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