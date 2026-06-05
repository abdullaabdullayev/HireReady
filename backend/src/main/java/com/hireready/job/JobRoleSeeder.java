package com.hireready.job;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class JobRoleSeeder implements CommandLineRunner {

    private final JobRoleRepository repo;
    @Override
    public void run(String... args) throws Exception {
        if(repo.count()>0)return;
        repo.saveAll(List.of(
                new JobRole("frontend", "Frontend Developer", "Engineering", "web_rounded",                 "#4F46E5", 1),
                new JobRole("backend",  "Backend Developer",  "Engineering", "dns_rounded",                 "#0EA5E9", 2),
                new JobRole("mobile",   "Mobile Engineer",    "Engineering", "phone_iphone_rounded",        "#10B981", 3),
                new JobRole("data",     "Data Scientist",     "Data & AI",   "insights_rounded",            "#8B5CF6", 4),
                new JobRole("pm",       "Product Manager",    "Product",     "dashboard_customize_rounded", "#F59E0B", 5),
                new JobRole("design",   "Product Designer",   "Design",      "brush_rounded",               "#EC4899", 6),
                new JobRole("devops",   "DevOps Engineer",    "Engineering", "settings_suggest_rounded",    "#14B8A6", 7),
                new JobRole("qa",       "QA Engineer",        "Engineering", "bug_report_rounded",          "#EF4444", 8)
        ));

    }
}
