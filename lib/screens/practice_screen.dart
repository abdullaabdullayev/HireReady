import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import '../widgets/common.dart';
import '../widgets/interactions.dart';
import 'voice_answer_sheet.dart';
import 'session_complete_screen.dart';

enum _Phase { answering, evaluating, result }

/// The heart of the app: shows a question, accepts a text/voice/option answer,
/// runs the mock AI evaluation, then lets the user review and continue.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _state = AppState.instance;
  final _controller = TextEditingController();

  int _index = 0;
  _Phase _phase = _Phase.answering;
  int? _selectedOption;
  bool _answeredByVoice = false;
  AnswerRecord? _record;

  Question get _q => _state.sessionQuestions[_index];
  int get _total => _state.sessionQuestions.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _q.hasOptions
      ? _selectedOption != null
      : _controller.text.trim().isNotEmpty;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _phase = _Phase.evaluating);
    // Simulate the AI "thinking".
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final record = _state.evaluate(
      question: _q,
      text: _q.hasOptions ? null : _controller.text,
      selectedOption: _selectedOption,
      byVoice: _answeredByVoice,
    );
    setState(() {
      _record = record;
      _phase = _Phase.result;
    });
    (record.isCorrect ? HapticType.success : HapticType.error).fire();
  }

  void _next() {
    if (_index >= _total - 1) {
      _state.finishSession();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SessionCompleteScreen()),
      );
      return;
    }
    setState(() {
      _index++;
      _phase = _Phase.answering;
      _selectedOption = null;
      _answeredByVoice = false;
      _record = null;
      _controller.clear();
    });
  }

  Future<void> _startVoice() async {
    final transcript = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAnswerSheet(),
    );
    if (transcript != null && transcript.isNotEmpty) {
      setState(() {
        _controller.text = transcript;
        _answeredByVoice = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_index + 1} of $_total'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _confirmQuit(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_index + (_phase == _Phase.result ? 1 : 0)) / _total,
                      minHeight: 7,
                      backgroundColor: AppColors.line,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _phase == _Phase.evaluating
                        ? const _Evaluating()
                        : ListView(
                            key: ValueKey('$_index-$_phase'),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            children: [
                              _questionCard(),
                              const SizedBox(height: 20),
                              if (_phase == _Phase.answering) _answerArea() else _resultArea(),
                            ],
                          ),
                  ),
                ),
                if (_phase != _Phase.evaluating) _bottomAction(),
              ],
            ),
            // Celebrate a high score on this question.
            if (_phase == _Phase.result && (_record?.score ?? 0) >= 80)
              Positioned.fill(child: ConfettiBurst(key: ValueKey('confetti-$_index'))),
          ],
        ),
      ),
    );
  }

  Widget _questionCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TagPill(text: _q.category, icon: Icons.category_rounded),
              const Spacer(),
              TagPill(
                text: _q.hasOptions ? 'Multiple choice' : 'Open answer',
                color: _q.hasOptions ? AppColors.info : AppColors.accent,
                icon: _q.hasOptions ? Icons.checklist_rounded : Icons.edit_note_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_q.prompt,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.35, color: AppColors.ink)),
        ],
      ),
    );
  }

  // ---- Answering ----
  Widget _answerArea() {
    if (_q.hasOptions) return _options();
    return _openAnswer();
  }

  Widget _options() {
    return Column(
      children: List.generate(_q.options.length, (i) {
        final selected = _selectedOption == i;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            onTap: () => setState(() => _selectedOption = i),
            border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: 2),
                  ),
                  child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(_q.options[i],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, height: 1.3)),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _openAnswer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _controller,
            maxLines: 7,
            minLines: 5,
            keyboardType: TextInputType.multiline,
            stylusHandwritingEnabled: false, // keyboard text or voice only — no stylus handwriting
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Type your answer here, or use voice…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _startVoice,
                icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
                label: const Text('Answer by voice'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ),
            if (_answeredByVoice) ...[
              const SizedBox(width: 10),
              const TagPill(text: 'Voice', icon: Icons.graphic_eq_rounded, color: AppColors.accent),
            ],
          ],
        ),
      ],
    );
  }

  // ---- Result ----
  Widget _resultArea() {
    final r = _record!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          color: r.isCorrect ? AppColors.accentSoft : const Color(0xFFFFF1F0),
          child: Row(
            children: [
              ScoreRing(score: r.score, size: 92),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(r.isCorrect ? Icons.verified_rounded : Icons.error_rounded,
                            color: r.isCorrect ? AppColors.success : AppColors.danger, size: 22),
                        const SizedBox(width: 8),
                        Text(r.isCorrect ? 'Well done!' : 'Keep practicing',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: r.isCorrect ? AppColors.success : AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.isCorrect ? 'Your answer covered the key points.' : 'Review the explanation below.',
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // AI feedback
        _infoBlock(
          icon: Icons.auto_awesome_rounded,
          color: AppColors.primary,
          title: 'AI feedback',
          body: r.feedback,
        ),
        const SizedBox(height: 12),

        // Model answer / explanation
        _infoBlock(
          icon: Icons.menu_book_rounded,
          color: AppColors.info,
          title: 'Model answer',
          body: _q.modelAnswer,
        ),

        if (_q.keyPoints.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader('Key points to hit'),
          const SizedBox(height: 10),
          ..._q.keyPoints.map((k) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 19),
                    const SizedBox(width: 10),
                    Expanded(child: Text(k, style: const TextStyle(fontSize: 14, height: 1.3, color: AppColors.inkSoft))),
                  ],
                ),
              )),
        ],

        const SizedBox(height: 16),
        // Mark for review
        AppCard(
          onTap: () => setState(() => r.markedForReview = !r.markedForReview),
          padding: const EdgeInsets.all(16),
          border: Border.all(color: r.markedForReview ? AppColors.warning : Colors.transparent, width: 2),
          child: Row(
            children: [
              Icon(r.markedForReview ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: AppColors.warning),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Mark for review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Switch(
                value: r.markedForReview,
                activeThumbColor: AppColors.warning,
                onChanged: (v) {
                  HapticType.selection.fire();
                  setState(() => r.markedForReview = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBlock({required IconData icon, required Color color, required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _bottomAction() {
    final isResult = _phase == _Phase.result;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x0F15172B), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: isResult
              ? () {
                  HapticType.light.fire();
                  _next();
                }
              : (_canSubmit
                  ? () {
                      HapticType.light.fire();
                      _submit();
                    }
                  : null),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: AppColors.line,
            disabledForegroundColor: AppColors.muted,
          ),
          child: Text(isResult
              ? (_index >= _total - 1 ? 'Finish session' : 'Next question')
              : 'Submit answer'),
        ),
      ),
    );
  }

  void _confirmQuit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave session?'),
        content: const Text('Your progress in this session will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

/// "AI is thinking" loading state shown during evaluation.
class _Evaluating extends StatelessWidget {
  const _Evaluating();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('evaluating'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.brandGradient),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 42),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Evaluating your answer…',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Our AI is scoring against the key points',
              style: TextStyle(color: AppColors.muted, fontSize: 13.5)),
          const SizedBox(height: 24),
          const SizedBox(
            width: 130,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
