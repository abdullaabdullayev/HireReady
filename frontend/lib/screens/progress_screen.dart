import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/interactions.dart';

/// Analytics / progress dashboard (a bottom-nav tab, and reachable as
/// "view analytics" from the flow).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  // Mock weekly activity (questions answered per day).
  static const _week = [4, 7, 3, 9, 6, 11, 8];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  // Mock skill breakdown.
  static const _skills = [
    ('Behavioral', 0.82, AppColors.primary),
    ('Technical', 0.68, AppColors.info),
    ('System Design', 0.54, AppColors.warning),
    ('Experience', 0.74, AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text('Your progress',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text('Keep the streak going!', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
        const SizedBox(height: 20),

        // Overview tiles
        Row(
          children: [
            _tile(state.sessionsCompleted, 'Sessions', AppColors.primary),
            const SizedBox(width: 12),
            _tile(state.questionsAnswered, 'Questions', AppColors.info),
            const SizedBox(width: 12),
            _tile(72, 'Avg score', AppColors.accent, suffix: '%'),
          ],
        ),
        const SizedBox(height: 20),

        // Weekly activity bar chart
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('This week'),
              const SizedBox(height: 20),
              SizedBox(
                height: 178,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_week.length, (i) {
                    final maxV = _week.reduce((a, b) => a > b ? a : b);
                    final h = 24 + (_week[i] / maxV) * 96;
                    final isPeak = _week[i] == maxV;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${_week[i]}',
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
                                    : [AppColors.primary.withValues(alpha: 0.45), AppColors.primary.withValues(alpha: 0.25)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_days[i], style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Skill breakdown
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Skills breakdown'),
              const SizedBox(height: 18),
              ..._skills.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(s.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const Spacer(),
                            Text('${(s.$2 * 100).round()}%',
                                style: TextStyle(fontWeight: FontWeight.w800, color: s.$3)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: s.$2),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) => LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              backgroundColor: s.$3.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(s.$3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Achievements
        const SectionHeader('Achievements'),
        const SizedBox(height: 14),
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _Badge(icon: Icons.local_fire_department_rounded, label: '4-day streak', color: AppColors.warning),
              _Badge(icon: Icons.bolt_rounded, label: 'Fast learner', color: AppColors.primary),
              _Badge(icon: Icons.star_rounded, label: 'First 90+', color: AppColors.accent),
              _Badge(icon: Icons.psychology_rounded, label: '50 answered', color: AppColors.info),
            ],
          ),
        ),
      ],
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
