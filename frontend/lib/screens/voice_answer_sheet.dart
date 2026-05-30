import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/interactions.dart';

/// UI-only voice answer capture. Shows a mic button, animated waveform and
/// timer while "recording", then returns a mock transcript. No real audio is
/// recorded (that would require native mic/transcription — out of scope).
class VoiceAnswerSheet extends StatefulWidget {
  const VoiceAnswerSheet({super.key});

  @override
  State<VoiceAnswerSheet> createState() => _VoiceAnswerSheetState();
}

class _VoiceAnswerSheetState extends State<VoiceAnswerSheet> {
  bool _recording = false;
  bool _done = false;
  int _seconds = 0;
  Timer? _timer;

  static const _mockTranscript =
      'In my last role I led a project that was running behind schedule. I broke the work '
      'into smaller milestones, re-prioritised with the team, and shipped the core feature '
      'two weeks early, which increased user retention by about fifteen percent.';

  void _toggle() {
    if (_recording) {
      _stop();
    } else {
      HapticType.medium.fire();
      setState(() {
        _recording = true;
        _seconds = 0;
        _done = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
    }
  }

  void _stop() {
    _timer?.cancel();
    HapticType.light.fire();
    setState(() {
      _recording = false;
      _done = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _time {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 44,
            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(height: 24),
          Text(
            _recording ? 'Listening…' : (_done ? 'Recording captured' : 'Tap to start speaking'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _recording ? 'Speak your answer clearly' : (_done ? 'Review the transcript below' : 'Answer the question out loud'),
            style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
          ),
          const SizedBox(height: 28),

          // Waveform
          SizedBox(
            height: 56,
            child: _recording ? const _Waveform() : _idleBars(),
          ),
          const SizedBox(height: 16),
          Text(_time,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFeatures: const [],
                color: _recording ? AppColors.danger : AppColors.ink,
              )),
          const SizedBox(height: 24),

          if (_done) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(_mockTranscript, style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.inkSoft)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _done = false;
                      _seconds = 0;
                    }),
                    child: const Text('Re-record'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticType.selection.fire();
                      Navigator.pop(context, _mockTranscript);
                    },
                    child: const Text('Use answer'),
                  ),
                ),
              ],
            ),
          ] else
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 84,
                width: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _recording ? AppColors.danger : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (_recording ? AppColors.danger : AppColors.primary).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: _recording ? 6 : 0,
                    ),
                  ],
                ),
                child: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 38),
              ),
            ),
        ],
      ),
    );
  }

  Widget _idleBars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        21,
        (i) => Container(
          width: 3,
          height: 8 + (i % 5) * 4,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}

/// Animated bars that bounce while "recording".
class _Waveform extends StatefulWidget {
  const _Waveform();

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  final _rand = Random();
  late final List<double> _seeds = List.generate(25, (_) => 0.2 + _rand.nextDouble());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(25, (i) {
          final phase = sin((_c.value * 2 * pi) + i) * 0.5 + 0.5;
          // Keep within the 56px container (max seed 1.2 -> 6 + 1.2*40 = 54).
          final h = (6 + phase * _seeds[i] * 40).clamp(6.0, 54.0);
          return Container(
            width: 3.5,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.danger],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
