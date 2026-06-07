package com.hireready.analytics;

import com.hireready.answer.AnswerRecord;
import com.hireready.answer.AnswerRepository;
import com.hireready.common.enums.SessionStatus;
import com.hireready.session.SessionRepository;
import com.hireready.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AnalyticsService {

    private final SessionRepository sessionRepo;
    private final AnswerRepository answerRepo;

    private static final String[] DAY_LABELS = {"M", "T", "W", "T", "F", "S", "S"};

    @Transactional(readOnly = true)
    public AnalyticsResponse overview(User user) {
        Long uid = user.getId();
        List<AnswerRecord> answers = answerRepo.findAllByUserId(uid);

        int sessions = (int) sessionRepo.countByUserIdAndStatus(uid, SessionStatus.COMPLETED);
        int questions = answers.size();
        int avg = answers.isEmpty() ? 0
                : (int) Math.round(answers.stream().mapToInt(AnswerRecord::getScore).average().orElse(0));

        return new AnalyticsResponse(
                sessions, questions, avg,
                computeStreak(answers),
                weekly(uid),
                skills(answers));
    }

    private List<AnalyticsResponse.DayActivity> weekly(Long uid) {
        ZoneId zone = ZoneId.systemDefault();
        LocalDate today = LocalDate.now(zone);
        LocalDate monday = today.with(DayOfWeek.MONDAY);
        Instant since = monday.atStartOfDay(zone).toInstant();

        List<AnswerRecord> recent = answerRepo.findByUserIdSince(uid, since);
        Map<LocalDate, Long> byDay = recent.stream().collect(Collectors.groupingBy(
                a -> a.getCreatedAt().atZone(zone).toLocalDate(), Collectors.counting()));

        List<AnalyticsResponse.DayActivity> out = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            LocalDate d = monday.plusDays(i);
            out.add(new AnalyticsResponse.DayActivity(
                    DAY_LABELS[i], byDay.getOrDefault(d, 0L).intValue()));
        }
        return out;
    }

    private List<AnalyticsResponse.SkillScore> skills(List<AnswerRecord> answers) {
        Map<String, List<AnswerRecord>> byCat = answers.stream()
                .collect(Collectors.groupingBy(a -> a.getQuestion().getCategory()));
        return byCat.entrySet().stream()
                .map(e -> new AnalyticsResponse.SkillScore(
                        e.getKey(),
                        (int) Math.round(e.getValue().stream()
                                .mapToInt(AnswerRecord::getScore).average().orElse(0))))
                .sorted(Comparator.comparing(AnalyticsResponse.SkillScore::name))
                .toList();
    }

    private int computeStreak(List<AnswerRecord> answers) {
        if (answers.isEmpty()) return 0;
        ZoneId zone = ZoneId.systemDefault();
        Set<LocalDate> days = answers.stream()
                .map(a -> a.getCreatedAt().atZone(zone).toLocalDate())
                .collect(Collectors.toSet());

        LocalDate cursor = LocalDate.now(zone);
        if (!days.contains(cursor)) cursor = cursor.minusDays(1);
        int streak = 0;
        while (days.contains(cursor)) {
            streak++;
            cursor = cursor.minusDays(1);
        }
        return streak;
    }
}
