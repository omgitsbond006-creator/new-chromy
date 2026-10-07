import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Deep-space gradient with softly twinkling stars.
class SpaceBackground extends StatefulWidget {
  const SpaceBackground({super.key, required this.child, this.animate = true});

  final Widget child;
  final bool animate;

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  late final List<_Star> _stars = _makeStars();

  static List<_Star> _makeStars() {
    final rng = math.Random(7);
    return List.generate(90, (_) {
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 0.6 + rng.nextDouble() * 1.6,
        phase: rng.nextDouble() * math.pi * 2,
        speed: 1 + rng.nextInt(3),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.backgroundTop, AppColors.background],
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(painter: StarfieldPainter(_stars, _controller)),
        ),
        widget.child,
      ],
    );
  }
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
  });

  final double x;
  final double y;
  final double size;
  final double phase;
  final int speed;
}

class StarfieldPainter extends CustomPainter {
  StarfieldPainter(this._stars, this._animation) : super(repaint: _animation);

  final List<_Star> _stars;
  final Animation<double> _animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = _animation.value * math.pi * 2;
    final paint = Paint();
    for (final s in _stars) {
      final twinkle =
          0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * s.speed + s.phase));
      paint.color = Colors.white.withValues(alpha: 0.75 * twinkle);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) => false;
}
