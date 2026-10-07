import 'package:flutter/material.dart';

import '../core/skins.dart';

/// Draws a glowing orb using a skin's colors.
class OrbView extends StatelessWidget {
  const OrbView({super.key, required this.skin, this.size = 48});

  final OrbSkin skin;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: OrbPainter(skin)),
    );
  }
}

class OrbPainter extends CustomPainter {
  OrbPainter(this.skin);

  final OrbSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.3;
    paintOrb(canvas, c, r, skin);
  }

  @override
  bool shouldRepaint(OrbPainter oldDelegate) => oldDelegate.skin != skin;
}

void paintOrb(
  Canvas canvas,
  Offset c,
  double r,
  OrbSkin skin, {
  double glow = 1,
}) {
  canvas.drawCircle(
    c,
    r * 1.7,
    Paint()
      ..color = skin.glow.withValues(alpha: 0.35 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9),
  );
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        colors: [skin.core, skin.glow],
        stops: const [0.35, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );
  canvas.drawCircle(
    c.translate(-r * 0.3, -r * 0.3),
    r * 0.25,
    Paint()..color = Colors.white.withValues(alpha: 0.55),
  );
}
