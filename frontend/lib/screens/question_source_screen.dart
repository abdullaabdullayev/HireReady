import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';
import 'practice_screen.dart';

/// Step 4 — choose where questions come from: the system's question bank, or a
/// custom questions file the user uploads (we extract questions from it).
class QuestionSourceScreen extends StatefulWidget {
  const QuestionSourceScreen({super.key});

  @override
  State<QuestionSourceScreen> createState() => _QuestionSourceScreenState();
}

class _QuestionSourceScreenState extends State<QuestionSourceScreen> {
  QuestionSource _source = AppState.instance.source;

  void _uploadQuestionsFile() {
    const file = UploadedResource(name: 'Interview_Questions.pdf', type: 'PDF', size: '64 KB');
    setState(() => AppState.instance.addQuestionFile(file));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accent,
        content: Text('Extracted ${AppState.instance.customQuestions.length} questions from your file'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Question source')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  const StepDots(current: 4, total: 4),
                  const SizedBox(height: 20),
                  const Text('Where should questions come from?',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 16),

                  _sourceCard(
                    source: QuestionSource.system,
                    title: 'Questions from the system',
                    subtitle: 'Curated ${state.selectedRole?.title ?? "role"} questions for ${state.level.label} level.',
                    icon: Icons.library_books_rounded,
                  ),
                  const SizedBox(height: 12),
                  _sourceCard(
                    source: QuestionSource.customFile,
                    title: 'Upload custom questions file',
                    subtitle: 'We extract the interview questions from your file.',
                    icon: Icons.note_add_rounded,
                  ),

                  // Upload area only relevant for the custom-file source.
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState:
                        _source == QuestionSource.customFile ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader('Your questions file'),
                          const SizedBox(height: 12),
                          ...state.questionFiles.map((f) => FileRow(
                                name: f.name,
                                meta: '${f.type} • ${f.size}',
                                badge: TagPill(
                                  text: '${state.customQuestions.length} questions',
                                  color: AppColors.accent,
                                  icon: Icons.check_rounded,
                                ),
                                onRemove: () => setState(() => state.removeQuestionFile(f)),
                              )),
                          if (state.questionFiles.isEmpty)
                            UploadBox(
                              title: 'Tap to upload questions file',
                              subtitle: 'PDF, DOCX, TXT • max 5 MB',
                              icon: Icons.note_add_rounded,
                              onTap: _uploadQuestionsFile,
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
              label: 'Start practice',
              enabled: _source == QuestionSource.system || state.questionFiles.isNotEmpty,
              onNext: () {
                state.source = _source;
                state.buildSession();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PracticeScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceCard({
    required QuestionSource source,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _source == source;
    return AppCard(
      onTap: () => setState(() => _source = source),
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
