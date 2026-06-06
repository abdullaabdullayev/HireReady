import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../services/document_service.dart';
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
  bool _uploadingResume = false;
  bool _uploadingReference = false;

  static const _areas = ['Behavioral', 'Technical', 'System Design', 'Experience', 'Culture fit'];

  /// Opens the system picker and returns the chosen file, or null if cancelled.
  Future<PlatformFile?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      withData: false, // we use the file path
    );
    return result?.files.single;
  }

  Future<void> _uploadResume() async {
    final picked = await _pickFile();
    if (picked == null || picked.path == null) return;

    setState(() => _uploadingResume = true);
    try {
      final doc = await DocumentService.upload(
        filePath: picked.path!,
        fileName: picked.name,
        type: 'RESUME',
      );
      if (!mounted) return;
      setState(() => AppState.instance.setResume(doc));
      _toast('Resume uploaded', error: false);
    } catch (e) {
      _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploadingResume = false);
    }
  }

  Future<void> _uploadReference() async {
    final picked = await _pickFile();
    if (picked == null || picked.path == null) return;

    setState(() => _uploadingReference = true);
    try {
      final doc = await DocumentService.upload(
        filePath: picked.path!,
        fileName: picked.name,
        type: 'REFERENCE',
      );
      if (!mounted) return;
      setState(() => AppState.instance.addReferenceMaterial(doc));
      _toast('Reference added — the AI will use it to check answers', error: false);
    } catch (e) {
      _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploadingReference = false);
    }
  }

  Future<void> _removeResume() async {
    final r = AppState.instance.resume;
    setState(() => AppState.instance.removeResume());
    if (r?.id != null) {
      try {
        await DocumentService.delete(r!.id!);
      } catch (_) {/* already removed locally */}
    }
  }

  Future<void> _removeReference(UploadedResource r) async {
    setState(() => AppState.instance.removeReferenceMaterial(r));
    if (r.id != null) {
      try {
        await DocumentService.delete(r.id!);
      } catch (_) {}
    }
  }

  void _toast(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.danger : AppColors.accent,
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
                  if (_uploadingResume)
                    const _UploadingBox(label: 'Uploading resume…')
                  else if (state.resume == null)
                    UploadBox(
                      title: 'Tap to upload resume',
                      subtitle: 'PDF, DOCX • max 5 MB',
                      icon: Icons.description_rounded,
                      onTap: _uploadResume,
                    )
                  else
                    FileRow(
                      name: state.resume!.name,
                      meta: state.resume!.size,
                      badge: const TagPill(text: 'Uploaded', color: AppColors.success, icon: Icons.check_rounded),
                      onRemove: _removeResume,
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
                                meta: f.size,
                                onRemove: () => _removeReference(f),
                              )),
                          if (_uploadingReference)
                            const _UploadingBox(label: 'Uploading…')
                          else
                            UploadBox(
                              title: 'Tap to upload a book or resource',
                              subtitle: 'PDF, DOCX, TXT • max 25 MB',
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

/// Shown in place of an UploadBox while a file is being uploaded.
class _UploadingBox extends StatelessWidget {
  final String label;
  const _UploadingBox({required this.label});

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
      child: Column(
        children: [
          const SizedBox(
            height: 28, width: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ],
      ),
    );
  }
}
