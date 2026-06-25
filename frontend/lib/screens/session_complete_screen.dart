import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/interactions.dart';
import 'dashboard_screen.dart';
import 'review_screen.dart';

class SessionCompleteScreen extends StatefulWidget {
  const SessionCompleteScreen({super.key});

  @override
  State<SessionCompleteScreen> createState() => _SessionCompleteScreenState();
}

class _SessionCompleteScreenState extends State<SessionCompleteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => HapticType.success.fire());
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final avg = state.averageScore.round();
    final correct = state.correctCount;
    final total = state.answers.length;
    final reviewCount = state.reviewList.length;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                children: [
                  Center(
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.accentGradient),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 42),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('Session complete!',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text('You answered $total questions for ${state.selectedRole?.title ?? "your role"}',
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
                  ),
                  const SizedBox(height: 28),

                  AppCard(
                    child: Column(
                      children: [
                        ScoreRing(score: avg, size: 130),
                        const SizedBox(height: 8),
                        const Text('Average score', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statCard('$correct/$total', 'Correct', Icons.check_circle_rounded, AppColors.success),
                      const SizedBox(width: 12),
                      _statCard('$reviewCount', 'To review', Icons.bookmark_rounded, AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 28),

                  const SectionHeader('Question breakdown'),
                  const SizedBox(height: 12),
                  ...state.answers.asMap().entries.map((e) {
                    final i = e.key;
                    final a = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: kCardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 34,
                            width: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: (a.isCorrect ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: a.isCorrect ? AppColors.success : AppColors.danger)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(a.question.prompt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          ),
                          const SizedBox(width: 8),
                          Text('${a.score}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: a.score >= 60 ? AppColors.success : AppColors.danger)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [BoxShadow(color: Color(0x0F15172B), blurRadius: 20, offset: Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    if (reviewCount > 0)
                      OutlinedButton.icon(
                        onPressed: () {
                          HapticType.light.fire();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReviewScreen()),
                          );
                        },
                        icon: const Icon(Icons.bookmark_rounded, color: AppColors.warning),
                        label: Text('Review $reviewCount question${reviewCount == 1 ? "" : "s"}'),
                      ),
                    if (reviewCount > 0) const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        HapticType.light.fire();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Back to dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
            const Positioned.fill(child: ConfettiBurst()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
