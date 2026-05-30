import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';
import 'practice_screen.dart';

/// Step 4 — choose where questions come from: an uploaded resume (tailored)
/// or the default question bank.
class QuestionSourceScreen extends StatefulWidget {
  const QuestionSourceScreen({super.key});

  @override
  State<QuestionSourceScreen> createState() => _QuestionSourceScreenState();
}

class _QuestionSourceScreenState extends State<QuestionSourceScreen> {
  QuestionSource _source = AppState.instance.source;

  void _mockUpload() {
    // Simulate a file picker result — no real I/O.
    const r = UploadedResource(name: 'Resume_2026.pdf', type: 'PDF', size: '248 KB');
    if (!AppState.instance.resources.any((e) => e.name == r.name)) {
      setState(() => AppState.instance.addResource(r));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accent,
        content: Text('Resume uploaded — generating tailored questions'),
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
                    source: QuestionSource.resume,
                    title: 'From my resume',
                    subtitle: 'Upload your resume — we generate questions tailored to your experience.',
                    icon: Icons.description_rounded,
                  ),
                  const SizedBox(height: 12),
                  _sourceCard(
                    source: QuestionSource.defaultBank,
                    title: 'Default question bank',
                    subtitle: 'Curated ${state.selectedRole?.title ?? "role"} questions for ${state.level.label} level.',
                    icon: Icons.library_books_rounded,
                  ),

                  // Upload area only relevant for the resume source.
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState:
                        _source == QuestionSource.resume ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader('Your documents'),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _mockUpload,
                            child: DottedUploadBox(),
                          ),
                          const SizedBox(height: 12),
                          ...state.resources.map((r) => _fileRow(r)),
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
              enabled: _source == QuestionSource.defaultBank || state.resources.isNotEmpty,
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

  Widget _fileRow(UploadedResource r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${r.type} • ${r.size}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
        ],
      ),
    );
  }
}

/// Dashed-border upload drop zone.
class DottedUploadBox extends StatelessWidget {
  const DottedUploadBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
      ),
      child: const Column(
        children: [
          Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 34),
          SizedBox(height: 10),
          Text('Tap to upload resume', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          SizedBox(height: 4),
          Text('PDF, DOCX • max 5 MB', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
