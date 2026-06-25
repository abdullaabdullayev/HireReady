import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../services/analytics_service.dart';
import '../widgets/common.dart';
import '../widgets/interactions.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const _palette = [AppColors.primary, AppColors.info, AppColors.warning, AppColors.accent];

  @override
  void initState() {
    super.initState();
    AppState.instance.loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final a = state.analytics;
        return RefreshIndicator(
          onRefresh: () => state.loadAnalytics(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Text('Your progress',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Keep the streak going!',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
              const SizedBox(height: 20),

              Row(
                children: [
                  _tile(a.sessions, 'Sessions', AppColors.primary),
                  const SizedBox(width: 12),
                  _tile(a.questions, 'Questions', AppColors.info),
                  const SizedBox(width: 12),
                  _tile(a.avgScore, 'Avg score', AppColors.accent, suffix: '%'),
                ],
              ),
              const SizedBox(height: 20),

              _weeklyCard(a),
              const SizedBox(height: 20),
              _skillsCard(a),
              const SizedBox(height: 20),

              const SectionHeader('Achievements'),
              const SizedBox(height: 14),
              SizedBox(
                height: 108,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Badge(
                        icon: Icons.local_fire_department_rounded,
                        label: '${a.dayStreak}-day streak',
                        color: AppColors.warning),
                    const _Badge(icon: Icons.bolt_rounded, label: 'Fast learner', color: AppColors.primary),
                    const _Badge(icon: Icons.star_rounded, label: 'First 90+', color: AppColors.accent),
                    _Badge(
                        icon: Icons.psychology_rounded,
                        label: '${a.questions} answered',
                        color: AppColors.info),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _weeklyCard(Analytics a) {
    final week = a.weekly;
    final maxV = week.isEmpty ? 1 : week.map((d) => d.count).fold(1, (p, c) => c > p ? c : p);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('This week'),
          const SizedBox(height: 20),
          if (week.isEmpty)
            const _EmptyHint('No activity yet this week')
          else
            SizedBox(
              height: 178,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(week.length, (i) {
                  final count = week[i].count;
                  final h = 24 + (count / maxV) * 96;
                  final isPeak = count == maxV && count > 0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('$count',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPeak ? AppColors.primary : AppColors.muted)),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: h),
                        duration: Duration(milliseconds: 500 + i * 80),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => Container(
                          width: 26,
                          height: value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isPeak
                                  ? AppColors.brandGradient
                                  : [
                                      AppColors.primary.withValues(alpha: 0.45),
                                      AppColors.primary.withValues(alpha: 0.25)
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(week[i].day,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _skillsCard(Analytics a) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Skills breakdown'),
          const SizedBox(height: 18),
          if (a.skills.isEmpty)
            const _EmptyHint('Answer some questions to see your skills')
          else
            ...List.generate(a.skills.length, (i) {
              final s = a.skills[i];
              final color = _palette[i % _palette.length];
              final value = s.percent / 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const Spacer(),
                        Text('${s.percent}%',
                            style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: value),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 10,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _tile(int value, String label, Color color, {String suffix = ''}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Column(
          children: [
            AnimatedCounter(
              value: value,
              suffix: suffix,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
      );
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.1)),
        ],
      ),
    );
  }
}
