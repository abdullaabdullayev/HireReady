package com.hireready.analytics;

import java.util.List;

public record AnalyticsResponse(
        int sessions,
        int questions,
        int avgScore,
        int dayStreak,
        List<DayActivity> weekly,
        List<SkillScore> skills
) {
    public record DayActivity(String day, int count) {}
    public record SkillScore(String name, int percent) {}
}
