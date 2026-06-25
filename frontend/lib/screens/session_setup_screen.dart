import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../services/document_service.dart';
import '../widgets/common.dart';
import 'practice_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  bool _uploadingResume = false;
  bool _uploadingReference = false;
  bool _uploadingQuestions = false;
  bool _starting = false;

  Future<void> _startPractice() async {
    setState(() => _starting = true);
    try {
      await AppState.instance.startSession();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PracticeScreen()),
      );
    } catch (e) {
      _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  static const _areas = ['Behavioral', 'Technical', 'System Design', 'Experience', 'Culture fit'];

  Future<PlatformFile?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      withData: false,
    );
    return result?.files.single;
  }

  Future<void> _uploadResume() async {
    final picked = await _pickFile();
    if (picked == null || picked.path == null) return;
    setState(() => _uploadingResume = true);
    try {
      final doc = await DocumentService.upload(
          filePath: picked.path!, fileName: picked.name, type: 'RESUME');
      if (!mounted) return;
      setState(() => AppState.instance.setResume(doc));
      _toast('Resume added', error: false);
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
          filePath: picked.path!, fileName: picked.name, type: 'REFERENCE');
      if (!mounted) return;
      setState(() => AppState.instance.addReferenceMaterial(doc));
      _toast('Reference added', error: false);
    } catch (e) {
      _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploadingReference = false);
    }
  }

  Future<void> _uploadQuestions() async {
    final picked = await _pickFile();
    if (picked == null || picked.path == null) return;
    setState(() => _uploadingQuestions = true);
    try {
      final doc = await DocumentService.upload(
          filePath: picked.path!, fileName: picked.name, type: 'QUESTIONS');
      if (!mounted) return;
      setState(() => AppState.instance.addQuestionFile(doc));
      final ok = doc.extractionStatus == 'DONE';
      _toast(ok ? 'Questions extracted from your file' : 'Could not read questions from this file',
          error: !ok);
    } catch (e) {
      _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => _uploadingQuestions = false);
    }
  }

  Future<void> _removeResume() async {
    final r = AppState.instance.resume;
    setState(() => AppState.instance.removeResume());
    if (r?.id != null) {
      try { await DocumentService.delete(r!.id!); } catch (_) {}
    }
  }

  Future<void> _removeReference(UploadedResource r) async {
    setState(() => AppState.instance.removeReferenceMaterial(r));
    if (r.id != null) {
      try { await DocumentService.delete(r.id!); } catch (_) {}
    }
  }

  Future<void> _removeQuestions(UploadedResource f) async {
    setState(() => AppState.instance.removeQuestionFile(f));
    if (f.id != null) {
      try { await DocumentService.delete(f.id!); } catch (_) {}
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
    final hasQuestionsFile = state.questionFiles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Customize')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  const StepDots(current: 3, total: 3),
                  const SizedBox(height: 20),
                  const Text('Customize your session',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Everything below is optional. Tap Start to use smart defaults.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  _label('Focus areas', 'Leave empty for a balanced mix'),
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
                  const SizedBox(height: 28),

                  _label('Resume', 'Tailors questions to your experience'),
                  const SizedBox(height: 12),
                  if (_uploadingResume)
                    const _UploadingBox(label: 'Uploading resume…')
                  else if (state.resume == null)
                    UploadBox(
                      title: 'Add your resume',
                      subtitle: 'PDF, DOCX, TXT • optional',
                      icon: Icons.description_rounded,
                      onTap: _uploadResume,
                    )
                  else
                    FileRow(
                      name: state.resume!.name,
                      meta: state.resume!.size,
                      badge: const TagPill(text: 'Added', color: AppColors.success, icon: Icons.check_rounded),
                      onRemove: _removeResume,
                    ),
                  const SizedBox(height: 28),

                  _label('Reference materials', 'Books/resources the AI checks answers against'),
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
                      title: 'Add a book or resource',
                      subtitle: 'PDF, DOCX, TXT • optional',
                      icon: Icons.menu_book_rounded,
                      onTap: _uploadReference,
                    ),
                  const SizedBox(height: 28),

                  _label('Your own questions', 'Skip to use our curated question bank'),
                  const SizedBox(height: 12),
                  ...state.questionFiles.map((f) => FileRow(
                        name: f.name,
                        meta: f.size,
                        badge: TagPill(
                          text: f.extractionStatus == 'DONE' ? 'Extracted' : 'No questions',
                          color: f.extractionStatus == 'DONE' ? AppColors.accent : AppColors.warning,
                          icon: f.extractionStatus == 'DONE' ? Icons.check_rounded : Icons.warning_amber_rounded,
                        ),
                        onRemove: () => _removeQuestions(f),
                      )),
                  if (_uploadingQuestions)
                    const _UploadingBox(label: 'Uploading & extracting…')
                  else if (!hasQuestionsFile)
                    UploadBox(
                      title: 'Upload a questions file',
                      subtitle: 'PDF, DOCX, TXT • optional',
                      icon: Icons.note_add_rounded,
                      onTap: _uploadQuestions,
                    ),
                ],
              ),
            ),
            FlowBottomBar(
              label: _starting ? 'Starting…' : 'Start practice',
              enabled: !_starting,
              onNext: _startPractice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String title, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3)),
      ],
    );
  }
}

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
