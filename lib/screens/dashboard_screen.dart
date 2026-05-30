import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';
import '../widgets/interactions.dart';
import 'select_role_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

/// Main app shell with bottom navigation.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [const _HomeTab(), const ProgressScreen(), const ProfileScreen()];
    return Scaffold(
      body: SafeArea(bottom: false, child: tabs[_index]),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySoft,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          height: 68,
          onDestinationSelected: (i) {
            HapticType.selection.fire();
            setState(() => _index = i);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi, ${state.userName} 👋',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  const Text('Ready to practice today?', style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
                ],
              ),
            ),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.brandGradient),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(state.userName[0],
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Stats row
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: Row(
            children: [
              _stat(state.sessionsCompleted, 'Sessions', Icons.task_alt_rounded, AppColors.primary),
              const SizedBox(width: 12),
              _stat(state.questionsAnswered, 'Answered', Icons.quiz_rounded, AppColors.info),
              const SizedBox(width: 12),
              _stat(state.dayStreak, 'Day streak', Icons.local_fire_department_rounded, AppColors.warning,
                  suffix: '🔥'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Primary CTA — "Start new session?" in the flow
        const FadeSlideIn(delay: Duration(milliseconds: 120), child: _StartSessionCard()),
        const SizedBox(height: 24),

        const SectionHeader('Popular roles'),
        const SizedBox(height: 14),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MockData.roles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final role = MockData.roles[i];
              return _RoleChip(
                role: role,
                onTap: () {
                  AppState.instance.reset();
                  AppState.instance.selectedRole = role;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SelectRoleScreen(skipToLevel: true)),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        const SectionHeader('Interview tip'),
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.accentSoft,
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.lightbulb_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Structure behavioral answers with STAR: Situation, Task, Action, Result.',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(int value, String label, IconData icon, Color color, {String suffix = ''}) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            AnimatedCounter(
              value: value,
              suffix: suffix,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StartSessionCard extends StatelessWidget {
  const _StartSessionCard();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: HapticType.light,
      onTap: () {
        AppState.instance.reset();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SelectRoleScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.brandGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start a new session',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Pick a role, set the level, and practice.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, height: 1.3)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Begin', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.rocket_launch_rounded, color: Colors.white.withValues(alpha: 0.9), size: 56),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final JobRole role;
  final VoidCallback onTap;
  const _RoleChip({required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: role.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(role.icon, color: role.color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(role.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.2)),
          ],
        ),
      ),
    );
  }
}
