import 'dart:ui';

/// A blocking arc that sits on one ring between [start] and [end]
/// (angles measured along the player's unwrapped path, in radians).
class Hazard {
  Hazard({
    required this.ring,
    required this.start,
    required this.end,
    this.blinkPeriod = 0,
    this.blinkOffset = 0,
  });

  final int ring;
  final double start;
  final double end;

  /// When > 0 the hazard switches on and off with this period (seconds).
  final double blinkPeriod;
  final double blinkOffset;

  /// Seconds since the hazard appeared. Used for fade-in.
  double age = 0;
  bool destroyed = false;

  static const double fadeInTime = 0.45;

  double get center => (start + end) / 2;

  /// Whether the hazard can hurt the player right now.
  bool isSolid(double time) {
    if (destroyed || age < fadeInTime) return false;
    if (blinkPeriod <= 0) return true;
    final phase = ((time + blinkOffset) % blinkPeriod) / blinkPeriod;
    return phase < 0.55;
  }

  /// 0..1 visual intensity.
  double opacity(double time) {
    if (destroyed) return 0;
    final fade = (age / fadeInTime).clamp(0.0, 1.0);
    if (blinkPeriod <= 0) return fade;
    final phase = ((time + blinkOffset) % blinkPeriod) / blinkPeriod;
    if (phase < 0.55) return fade;
    // Warn the player shortly before it switches back on.
    return phase > 0.85 ? fade * 0.55 : fade * 0.18;
  }
}

enum PickupType { gem, shield, slow, magnet }

class Pickup {
  Pickup({required this.type, required this.ring, required this.angle});

  final PickupType type;
  int ring;
  final double angle;
  bool collected = false;
  double age = 0;
}

class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.size,
  }) : maxLife = life;

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final Color color;
  final double size;

  double get t => (life / maxLife).clamp(0.0, 1.0);
}

class TrailPoint {
  TrailPoint(this.x, this.y);
  final double x;
  final double y;
}

/// Short floating text such as "+5".
class FloatingText {
  FloatingText({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
  });

  final String text;
  final double x;
  double y;
  final Color color;
  double life = 0.9;
}
