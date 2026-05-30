import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';
import 'question_source_screen.dart';

/// Step 3 — "Set requirements": optionally upload a resume, then choose default
/// or custom requirements. Under custom, the user can upload reference
/// books/resources the AI uses to check answers and generate questions.
class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key});

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  late bool _custom = AppState.instance.useCustomRequirements;

  static const _areas = ['Behavioral', 'Technical', 'System Design', 'Experience', 'Culture fit'];

  void _uploadResume() {
    const file = UploadedResource(name: 'Resume_2026.pdf', type: 'PDF', size: '248 KB');
    setState(() => AppState.instance.setResume(file));
    _toast('Resume uploaded');
  }

  void _uploadReference() {
    final n = AppState.instance.referenceMaterials.length + 1;
    final file = UploadedResource(name: 'Reference_$n.pdf', type: 'PDF', size: '1.2 MB');
    setState(() => AppState.instance.addReferenceMaterial(file));
    _toast('Reference added — the AI will use it to check answers');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accent,
        content: Text(msg),
      ),
    );
  }

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

                  // 1) Resume upload (optional, first)
                  const SectionHeader('Your resume'),
                  const SizedBox(height: 6),
                  const Text(
                    'Upload your resume so we can tailor questions and feedback to you. (Optional)',
                    style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  if (state.resume == null)
                    UploadBox(
                      title: 'Tap to upload resume',
                      subtitle: 'PDF, DOCX • max 5 MB',
                      icon: Icons.description_rounded,
                      onTap: _uploadResume,
                    )
                  else
                    FileRow(
                      name: state.resume!.name,
                      meta: '${state.resume!.type} • ${state.resume!.size}',
                      badge: const TagPill(text: 'Uploaded', color: AppColors.success, icon: Icons.check_rounded),
                      onRemove: () => setState(() => state.removeResume()),
                    ),

                  const SizedBox(height: 28),

                  // 2) Requirement type
                  const Text('How should we tailor it?',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
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
                    subtitle: 'Choose focus areas and add reference materials.',
                    icon: Icons.tune_rounded,
                    selected: _custom,
                    onTap: () => setState(() => _custom = true),
                  ),

                  // Custom panel: focus areas + reference materials
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
                          const SizedBox(height: 26),
                          const SectionHeader('Reference materials'),
                          const SizedBox(height: 6),
                          const Text(
                            'Upload books or resources — the AI uses them to check your answers and generate questions. (Optional)',
                            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          ...state.referenceMaterials.map((f) => FileRow(
                                name: f.name,
                                meta: '${f.type} • ${f.size}',
                                onRemove: () => setState(() => state.removeReferenceMaterial(f)),
                              )),
                          UploadBox(
                            title: 'Tap to upload a book or resource',
                            subtitle: 'PDF, DOCX, EPUB • max 25 MB',
                            icon: Icons.menu_book_rounded,
                            onTap: _uploadReference,
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
