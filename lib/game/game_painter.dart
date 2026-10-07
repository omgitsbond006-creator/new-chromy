import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/skins.dart';
import '../core/theme.dart';
import '../widgets/orb_view.dart';
import 'game_engine.dart';
import 'models.dart';

/// Computes where the arena sits on screen.
class ArenaLayout {
  ArenaLayout(Size size)
    : radius = math.min(size.width * 0.45, size.height * 0.34),
      center = Offset(size.width / 2, size.height * 0.52);

  final double radius;
  final Offset center;

  Offset toScreen(double x, double y) =>
      Offset(center.dx + x * radius, center.dy + y * radius);
}

class GamePainter extends CustomPainter {
  GamePainter({
    required this.engine,
    required this.skin,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final GameEngine engine;
  final OrbSkin skin;
  final math.Random _shakeRng = math.Random();

  @override
  void paint(Canvas canvas, Size size) {
    final layout = ArenaLayout(size);
    final r = layout.radius;

    canvas.save();
    if (engine.shake > 0) {
      final m = engine.shake * r * 0.05;
      canvas.translate(
        (_shakeRng.nextDouble() * 2 - 1) * m,
        (_shakeRng.nextDouble() * 2 - 1) * m,
      );
    }

    if (engine.slowTimer > 0) {
      canvas.drawCircle(
        layout.center,
        r * 1.08,
        Paint()
          ..color = AppColors.violet.withValues(alpha: 0.08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.1),
      );
    }

    _paintRings(canvas, layout);
    if (!engine.isOver) _paintCenter(canvas, layout);
    _paintHazards(canvas, layout);
    _paintPickups(canvas, layout);
    _paintTrail(canvas, layout);
    if (!engine.isOver) _paintPlayer(canvas, layout);
    _paintParticles(canvas, layout);
    _paintTexts(canvas, layout);

    canvas.restore();
  }

  void _paintRings(Canvas canvas, ArenaLayout layout) {
    for (var i = 0; i < GameEngine.ringCount; i++) {
      final active = i == engine.targetRing && !engine.isOver;
      final radius = GameEngine.ringRadii[i] * layout.radius;
      canvas.drawCircle(
        layout.center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = layout.radius * 0.035
          ..color = AppColors.cyan.withValues(alpha: active ? 0.10 : 0.04)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            layout.radius * 0.02,
          ),
      );
      canvas.drawCircle(
        layout.center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2.2 : 1.4
          ..color = AppColors.cyan.withValues(alpha: active ? 0.75 : 0.32),
      );
    }
  }

  void _paintCenter(Canvas canvas, ArenaLayout layout) {
    final r = layout.radius;
    final innerR = GameEngine.ringRadii.first * r * 0.72;
    canvas.drawCircle(
      layout.center,
      innerR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.magenta.withValues(alpha: 0.22),
            AppColors.background.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: layout.center, radius: innerR)),
    );
    _drawText(
      canvas,
      '${engine.score}',
      layout.center.translate(0, -r * 0.02),
      TextStyle(
        fontSize: r * 0.17,
        fontWeight: FontWeight.w900,
        color: AppColors.text,
        letterSpacing: 2,
        shadows: const [Shadow(color: AppColors.cyan, blurRadius: 16)],
      ),
    );
    _drawText(
      canvas,
      'SCORE',
      layout.center.translate(0, r * 0.12),
      TextStyle(
        fontSize: r * 0.05,
        fontWeight: FontWeight.w700,
        color: AppColors.textDim,
        letterSpacing: 3,
      ),
    );
  }

  void _paintHazards(Canvas canvas, ArenaLayout layout) {
    final t = engine.time;
    for (final h in engine.hazards) {
      final o = h.opacity(t);
      if (o <= 0.01) continue;
      final radius = GameEngine.ringRadii[h.ring] * layout.radius;
      final rect = Rect.fromCircle(center: layout.center, radius: radius);
      final start = GameEngine.screenAngle(h.start);
      final sweep = h.end - h.start;
      final color = h.blinkPeriod > 0 ? AppColors.orange : AppColors.magenta;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = layout.radius * 0.1
          ..color = color.withValues(alpha: 0.35 * o)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            layout.radius * 0.03,
          ),
      );
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = layout.radius * 0.055
          ..color = color.withValues(alpha: o),
      );
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = layout.radius * 0.018
          ..color = Colors.white.withValues(alpha: 0.7 * o),
      );
    }
  }

  void _paintPickups(Canvas canvas, ArenaLayout layout) {
    final r = layout.radius;
    for (final p in engine.pickups) {
      final pos = GameEngine.pointOnRing(p.ring, p.angle);
      final c = layout.toScreen(pos.dx, pos.dy);
      final fade = (p.age / 0.4).clamp(0.0, 1.0);
      final pulse = 1 + 0.12 * math.sin(engine.time * 6 + p.angle);
      if (p.type == PickupType.gem) {
        final s = r * 0.035 * pulse;
        canvas.drawCircle(
          c,
          s * 2,
          Paint()
            ..color = AppColors.gem.withValues(alpha: 0.3 * fade)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s),
        );
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(engine.time * 2 + p.angle);
        final path = Path()
          ..moveTo(0, -s * 1.3)
          ..lineTo(s, 0)
          ..lineTo(0, s * 1.3)
          ..lineTo(-s, 0)
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = AppColors.gem.withValues(alpha: fade),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.8 * fade),
        );
        canvas.restore();
      } else {
        final (color, icon) = switch (p.type) {
          PickupType.shield => (AppColors.cyan, Icons.shield),
          PickupType.slow => (AppColors.violet, Icons.hourglass_bottom),
          PickupType.magnet => (AppColors.orange, Icons.bolt),
          PickupType.gem => (AppColors.gem, Icons.diamond),
        };
        final s = r * 0.055 * pulse;
        canvas.drawCircle(
          c,
          s * 1.6,
          Paint()
            ..color = color.withValues(alpha: 0.35 * fade)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.8),
        );
        canvas.drawCircle(
          c,
          s,
          Paint()..color = AppColors.background.withValues(alpha: 0.9 * fade),
        );
        canvas.drawCircle(
          c,
          s,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = color.withValues(alpha: fade),
        );
        _drawText(
          canvas,
          String.fromCharCode(icon.codePoint),
          c,
          TextStyle(
            fontSize: s * 1.2,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: color.withValues(alpha: fade),
          ),
        );
      }
    }
  }

  void _paintTrail(Canvas canvas, ArenaLayout layout) {
    final trail = engine.trail;
    if (trail.isEmpty) return;
    final paint = Paint();
    for (var i = 0; i < trail.length; i++) {
      final f = (i + 1) / trail.length;
      paint.color = skin.glow.withValues(alpha: 0.35 * f);
      canvas.drawCircle(
        layout.toScreen(trail[i].x, trail[i].y),
        layout.radius * GameEngine.playerRadius * (0.3 + 0.6 * f),
        paint,
      );
    }
  }

  void _paintPlayer(Canvas canvas, ArenaLayout layout) {
    final pos = engine.playerPosition;
    final c = layout.toScreen(pos.dx, pos.dy);
    final pr = layout.radius * GameEngine.playerRadius;

    if (engine.magnetTimer > 0) {
      canvas.drawCircle(
        c,
        pr * 3.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.orange.withValues(
            alpha: 0.35 + 0.25 * math.sin(engine.time * 10),
          ),
      );
    }

    final blinking =
        engine.invulnerableTimer > 0 &&
        (engine.invulnerableTimer * 12).floor().isEven;
    paintOrb(canvas, c, pr, skin, glow: blinking ? 0.3 : 1);

    if (engine.hasShield) {
      canvas.drawCircle(
        c,
        pr * 1.8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.cyan.withValues(alpha: 0.85),
      );
      canvas.drawCircle(
        c,
        pr * 1.8,
        Paint()..color = AppColors.cyan.withValues(alpha: 0.12),
      );
    }
  }

  void _paintParticles(Canvas canvas, ArenaLayout layout) {
    final paint = Paint();
    for (final p in engine.particles) {
      paint.color = p.color.withValues(alpha: p.t);
      canvas.drawCircle(
        layout.toScreen(p.x, p.y),
        p.size * layout.radius * (0.5 + 0.5 * p.t),
        paint,
      );
    }
  }

  void _paintTexts(Canvas canvas, ArenaLayout layout) {
    for (final t in engine.texts) {
      final a = (t.life / 0.9).clamp(0.0, 1.0);
      _drawText(
        canvas,
        t.text,
        layout.toScreen(t.x, t.y - 0.08),
        TextStyle(
          fontSize: layout.radius * 0.07,
          fontWeight: FontWeight.w900,
          color: t.color.withValues(alpha: a),
          letterSpacing: 1.5,
        ),
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) =>
      oldDelegate.engine != engine || oldDelegate.skin != skin;
}
