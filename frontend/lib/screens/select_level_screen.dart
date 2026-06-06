import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';
import 'session_setup_screen.dart';

/// Step 2 — pick the experience level.
class SelectLevelScreen extends StatefulWidget {
  const SelectLevelScreen({super.key});

  @override
  State<SelectLevelScreen> createState() => _SelectLevelScreenState();
}

class _SelectLevelScreenState extends State<SelectLevelScreen> {
  ExperienceLevel _level = AppState.instance.level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Experience level')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepDots(current: 2, total: 3),
                  const SizedBox(height: 20),
                  Text('How senior is the ${AppState.instance.selectedRole?.title ?? "role"}?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 6),
                  const Text('We tailor question difficulty to your level.',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 14.5)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: ExperienceLevel.values.map((lvl) {
                  final selected = _level == lvl;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      onTap: () => setState(() => _level = lvl),
                      border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              switch (lvl) {
                                ExperienceLevel.junior => Icons.eco_rounded,
                                ExperienceLevel.mid => Icons.trending_up_rounded,
                                ExperienceLevel.senior => Icons.military_tech_rounded,
                              },
                              color: selected ? Colors.white : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lvl.label, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(lvl.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(
                            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                            color: selected ? AppColors.primary : AppColors.line,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            FlowBottomBar(
              enabled: true,
              onNext: () {
                AppState.instance.level = _level;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SessionSetupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
