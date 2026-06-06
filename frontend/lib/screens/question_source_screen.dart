import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../services/document_service.dart';
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
  bool _uploading = false;

  Future<void> _uploadQuestionsFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      withData: false,
    );
    final picked = result?.files.single;
    if (picked == null || picked.path == null) return;

    setState(() => _uploading = true);
    try {
      final doc = await DocumentService.upload(
        filePath: picked.path!,
        fileName: picked.name,
        type: 'QUESTIONS',
      );
      if (!mounted) return;
      setState(() => AppState.instance.addQuestionFile(doc));

      final ok = doc.extractionStatus == 'DONE';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? AppColors.accent : AppColors.danger,
          content: Text(ok
              ? 'Questions extracted from your file'
              : 'Could not read questions from this file'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
            content: Text(friendlyError(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeQuestionFile(UploadedResource f) async {
    setState(() => AppState.instance.removeQuestionFile(f));
    if (f.id != null) {
      try {
        await DocumentService.delete(f.id!);
      } catch (_) {}
    }
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
                                meta: f.size,
                                badge: TagPill(
                                  text: f.extractionStatus == 'DONE' ? 'Extracted' : 'No questions',
                                  color: f.extractionStatus == 'DONE' ? AppColors.accent : AppColors.warning,
                                  icon: f.extractionStatus == 'DONE' ? Icons.check_rounded : Icons.warning_amber_rounded,
                                ),
                                onRemove: () => _removeQuestionFile(f),
                              )),
                          if (_uploading)
                            const _UploadingBox()
                          else if (state.questionFiles.isEmpty)
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
              // System source is always ready; custom-file source needs a file
              // whose questions were successfully extracted.
              enabled: _source == QuestionSource.system || state.customQuestions.isNotEmpty,
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

/// Loading box shown while the questions file uploads + extracts.
class _UploadingBox extends StatelessWidget {
  const _UploadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: const Column(
        children: [
          SizedBox(
            height: 28, width: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primary),
          ),
          SizedBox(height: 12),
          Text('Uploading & extracting…',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}
