import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../theme/app_theme.dart';
import '../widgets/interactions.dart';

class VoiceAnswerSheet extends StatefulWidget {
  const VoiceAnswerSheet({super.key});

  @override
  State<VoiceAnswerSheet> createState() => _VoiceAnswerSheetState();
}

class _VoiceAnswerSheetState extends State<VoiceAnswerSheet> {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _recording = false;
  bool _done = false;
  String _transcript = '';
  String _error = '';
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _available = await _speech.initialize(
        onError: (e) => setState(() => _error = 'Recognition error: ${e.errorMsg}'),
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted && _recording) _stop();
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = 'Speech recognition unavailable on this device.');
    }
  }

  Future<void> _toggle() async {
    if (_recording) {
      _stop();
      return;
    }
    if (!_available) {
      setState(() => _error = 'Speech recognition is not available.');
      return;
    }
    HapticType.medium.fire();
    setState(() {
      _recording = true;
      _done = false;
      _transcript = '';
      _error = '';
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));

    await _speech.listen(
      onResult: (r) => setState(() => _transcript = r.recognizedWords),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  void _stop() {
    _timer?.cancel();
    HapticType.light.fire();
    _speech.stop();
    setState(() {
      _recording = false;
      _done = _transcript.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.cancel();
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
            _recording
                ? 'Speak your answer clearly'
                : (_done ? 'Review the transcript below' : 'Answer the question out loud'),
            style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
          ),
          const SizedBox(height: 28),

          SizedBox(height: 56, child: _recording ? const _Waveform() : _idleBars()),
          const SizedBox(height: 16),
          Text(_time,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _recording ? AppColors.danger : AppColors.ink,
              )),
          const SizedBox(height: 16),

          if (_recording && _transcript.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(16)),
              child: Text(_transcript, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.inkSoft)),
            ),
            const SizedBox(height: 16),
          ],

          if (_error.isNotEmpty) ...[
            Text(_error, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            const SizedBox(height: 12),
          ],

          if (_done) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(16)),
              child: Text(_transcript, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.inkSoft)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _done = false;
                      _transcript = '';
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
                      Navigator.pop(context, _transcript.trim());
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
