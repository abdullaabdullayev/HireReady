import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps any child so it gently scales down while pressed, then springs back.
/// Rest state is visually identical to the unwrapped child. Fires an optional
/// haptic + onTap. Use for custom (non-AppCard) tappable surfaces.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final HapticType haptic;
  final BorderRadius? borderRadius;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptic = HapticType.selection,
    this.borderRadius,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTapCancel: widget.onTap == null ? null : () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              widget.haptic.fire();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// One-shot entrance: fades in and slides up a few pixels, settling at the
/// exact final position. Stagger siblings by passing increasing [delay].
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 16});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (_, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offset),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Counts an integer up from 0 to [value] on first build. Ends at [value].
class AnimatedCounter extends StatelessWidget {
  final int value;
  final String suffix;
  final TextStyle? style;
  final Duration duration;
  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Haptic intensity options with a single fire() entry point.
enum HapticType { none, selection, light, medium, success, error }

extension HapticTypeX on HapticType {
  void fire() {
    switch (this) {
      case HapticType.none:
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.success:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.error:
        HapticFeedback.heavyImpact();
        break;
    }
  }
}

/// Ephemeral celebration. Drops colourful confetti from the top across the
/// width, spins + fades out, then is inert. Place inside a Stack as a
/// Positioned.fill child — it ignores pointer events so it never blocks taps.
class ConfettiBurst extends StatefulWidget {
  final int count;
  final Duration duration;
  const ConfettiBurst({super.key, this.count = 90, this.duration = const Duration(milliseconds: 2600)});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final List<_Particle> _particles;

  static const _colors = [
    Color(0xFF4F46E5),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _particles = List.generate(widget.count, (_) {
      return _Particle(
        startX: rnd.nextDouble(),
        startY: -0.15 * rnd.nextDouble(),
        drift: (rnd.nextDouble() - 0.5) * 0.5,
        fall: 0.9 + rnd.nextDouble() * 0.5,
        size: 6 + rnd.nextDouble() * 7,
        color: _colors[rnd.nextInt(_colors.length)],
        rotments: (rnd.nextDouble() - 0.5) * 8,
        wobble: rnd.nextDouble() * pi * 2,
        round: rnd.nextBool(),
      );
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(_particles, _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  final double startX, startY, drift, fall, size, rotments, wobble;
  final Color color;
  final bool round;
  _Particle({
    required this.startX,
    required this.startY,
    required this.drift,
    required this.fall,
    required this.size,
    required this.color,
    required this.rotments,
    required this.wobble,
    required this.round,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0..1
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1.0) return;
    final paint = Paint();
    for (final p in particles) {
      final progress = (t * p.fall);
      final y = (p.startY + progress) * size.height * 1.15;
      if (y > size.height + 20) continue;
      final x = (p.startX + p.drift * t) * size.width + sin(p.wobble + t * 6) * 10;
      final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotments * t * pi);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
