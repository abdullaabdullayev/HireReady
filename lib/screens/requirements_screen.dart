import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';
import 'question_source_screen.dart';

/// Step 3 — "Set requirements": use defaults or customise focus areas & count.
class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key});

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  late bool _custom = AppState.instance.useCustomRequirements;
  double _count = 6;

  static const _areas = ['Behavioral', 'Technical', 'System Design', 'Experience', 'Culture fit'];

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Set requirements')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  const StepDots(current: 3, total: 4),
                  const SizedBox(height: 20),
                  const Text('How should we tailor it?',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),

                  // Default vs Custom toggle cards
                  _choice(
                    title: 'Default requirements',
                    subtitle: 'A balanced mix for ${state.level.label} ${state.selectedRole?.title ?? "candidates"}.',
                    icon: Icons.auto_awesome_rounded,
                    selected: !_custom,
                    onTap: () => setState(() => _custom = false),
                  ),
                  const SizedBox(height: 12),
                  _choice(
                    title: 'Custom requirements',
                    subtitle: 'Choose focus areas and how many questions.',
                    icon: Icons.tune_rounded,
                    selected: _custom,
                    onTap: () => setState(() => _custom = true),
                  ),

                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _custom ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader('Focus areas'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _areas.map((a) {
                              final on = state.focusAreas.contains(a);
                              return GestureDetector(
                                onTap: () => setState(() => state.toggleFocus(a)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: on ? AppColors.primary : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: on ? AppColors.primary : AppColors.line, width: 1.5),
                                  ),
                                  child: Text(a,
                                      style: TextStyle(
                                        color: on ? Colors.white : AppColors.inkSoft,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      )),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          SectionHeader('Number of questions',
                              trailing: TagPill(text: '${_count.round()}', icon: Icons.numbers_rounded)),
                          Slider(
                            value: _count,
                            min: 3,
                            max: 10,
                            divisions: 7,
                            label: '${_count.round()}',
                            onChanged: (v) => setState(() => _count = v),
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
            FlowBottomBar(
              enabled: !_custom || state.focusAreas.isNotEmpty,
              onNext: () {
                state.useCustomRequirements = _custom;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuestionSourceScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
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
            child: Icon(icon, color: selected ? Colors.white : AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.line),
        ],
      ),
    );
  }
}
