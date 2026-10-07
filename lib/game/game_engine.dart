import 'dart:math' as math;
import 'dart:ui';

import 'models.dart';

enum GameEvent { hop, gem, powerUp, shieldBreak, crash, milestone }

/// Pure game logic for Orbiquo. All positions live in a normalized arena
/// whose outer radius is 1.0 and whose center is (0, 0). Angles along the
/// path are "unwrapped" so obstacles can be laid out like a track.
class GameEngine {
  GameEngine({math.Random? random}) : _rng = random ?? math.Random();

  final math.Random _rng;

  static const List<double> ringRadii = [0.40, 0.65, 0.90];
  static const int ringCount = 3;
  static const double playerRadius = 0.05;

  /// Ring units per second while hopping.
  static const double hopSpeed = 8.0;

  /// How far ahead (radians) obstacles are generated.
  static const double lookAhead = 4.2;

  static const double baseSpeed = 1.6;
  static const double maxSpeed = 3.6;
  static const double speedGain = 0.028;

  static const double powerUpDuration = 6.0;
  static const int gemScore = 10;
  static const double distanceScorePerRadian = 4.0;

  // ---- State ---------------------------------------------------------------
  double time = 0;
  double phi = 0;
  int targetRing = 1;
  double ringPos = 1;

  bool isOver = false;
  bool hasShield = false;
  double slowTimer = 0;
  double magnetTimer = 0;
  double invulnerableTimer = 0;
  double shake = 0;
  double overTime = 0;

  int bonusScore = 0;
  int gemsCollected = 0;
  int _lastMilestone = 0;

  final List<Hazard> hazards = [];
  final List<Pickup> pickups = [];
  final List<Particle> particles = [];
  final List<TrailPoint> trail = [];
  final List<FloatingText> texts = [];
  final List<GameEvent> events = [];

  double _nextPatternAt = 2.6;

  int get score => (phi * distanceScorePerRadian).floor() + bonusScore;

  double get difficulty =>
      ((baseSpeed + speedGain * time - baseSpeed) / (maxSpeed - baseSpeed))
          .clamp(0.0, 1.0);

  /// Angular speed in radians per second, before slow-motion.
  double get baseOmega => math.min(baseSpeed + speedGain * time, maxSpeed);

  double get omega => baseOmega * (slowTimer > 0 ? 0.6 : 1.0);

  /// Radius of the player at its current (possibly in-between) ring position.
  double get playerOrbitRadius => radiusAt(ringPos);

  static double radiusAt(double ringPosition) {
    final p = ringPosition.clamp(0.0, (ringCount - 1).toDouble());
    final i = p.floor().clamp(0, ringCount - 2);
    final f = p - i;
    return ringRadii[i] + (ringRadii[i + 1] - ringRadii[i]) * f;
  }

  /// Screen angle (clockwise from the top) for a path angle.
  static double screenAngle(double pathAngle) => pathAngle - math.pi / 2;

  Offset get playerPosition {
    final a = screenAngle(phi);
    final r = playerOrbitRadius;
    return Offset(math.cos(a) * r, math.sin(a) * r);
  }

  static Offset pointOnRing(int ring, double pathAngle) {
    final a = screenAngle(pathAngle);
    final r = ringRadii[ring];
    return Offset(math.cos(a) * r, math.sin(a) * r);
  }

  // ---- Input -----------------------------------------------------------------
  void hopInward() => _hopTo(targetRing - 1);

  void hopOutward() => _hopTo(targetRing + 1);

  void _hopTo(int ring) {
    if (isOver) return;
    if (ring < 0 || ring >= ringCount) return;
    targetRing = ring;
    events.add(GameEvent.hop);
  }

  // ---- Simulation ----------------------------------------------------------
  void update(double rawDt) {
    if (rawDt <= 0) return;
    final dt = math.min(rawDt, 1 / 20);

    _updateEffects(dt);

    if (isOver) {
      overTime += dt;
      return;
    }

    time += dt;
    phi += omega * dt;

    // Smoothly move towards the target ring.
    final diff = targetRing - ringPos;
    final step = hopSpeed * dt;
    ringPos = diff.abs() <= step
        ? targetRing.toDouble()
        : ringPos + step * diff.sign;

    if (slowTimer > 0) slowTimer = math.max(0, slowTimer - dt);
    if (magnetTimer > 0) magnetTimer = math.max(0, magnetTimer - dt);
    if (invulnerableTimer > 0) {
      invulnerableTimer = math.max(0, invulnerableTimer - dt);
    }

    final pos = playerPosition;
    trail.add(TrailPoint(pos.dx, pos.dy));
    if (trail.length > 16) trail.removeAt(0);

    for (final h in hazards) {
      h.age += dt;
    }
    for (final p in pickups) {
      p.age += dt;
    }

    _spawnAhead();
    _checkPickups();
    _checkHazards();
    _cleanup();

    final milestone = score ~/ 250;
    if (milestone > _lastMilestone) {
      _lastMilestone = milestone;
      events.add(GameEvent.milestone);
      _addText('${milestone * 250}!', pos, const Color(0xFFFFE066));
    }
  }

  void _updateEffects(double dt) {
    if (shake > 0) shake = math.max(0, shake - dt * 2.5);
    for (final p in particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= 0.96;
      p.vy *= 0.96;
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);
    for (final t in texts) {
      t.y -= 0.18 * dt;
      t.life -= dt;
    }
    texts.removeWhere((t) => t.life <= 0);
  }

  double _angularHalfSize() =>
      playerRadius / math.max(playerOrbitRadius, ringRadii.first);

  void _checkHazards() {
    if (invulnerableTimer > 0) return;
    final half = _angularHalfSize() * 0.85;
    for (final h in hazards) {
      if (!h.isSolid(time)) continue;
      if ((ringPos - h.ring).abs() >= 0.5) continue;
      if (phi + half > h.start && phi - half < h.end) {
        if (hasShield) {
          hasShield = false;
          h.destroyed = true;
          invulnerableTimer = 1.0;
          shake = 0.5;
          events.add(GameEvent.shieldBreak);
          _burst(playerPosition, const Color(0xFF5CE1FF), 22, 0.9);
        } else {
          _crash();
        }
        return;
      }
    }
  }

  void _crash() {
    isOver = true;
    shake = 1.0;
    events.add(GameEvent.crash);
    final pos = playerPosition;
    _burst(pos, const Color(0xFFFF4D8D), 36, 1.2);
    _burst(pos, const Color(0xFFFFFFFF), 14, 0.7);
  }

  void _checkPickups() {
    final half = _angularHalfSize();
    final magnet = magnetTimer > 0;
    for (final p in pickups) {
      if (p.collected) continue;
      final angular = (phi - p.angle).abs();
      final sameRing = (ringPos - p.ring).abs() < 0.5;
      final hit = sameRing && angular < half + 0.08;
      final magnetHit = magnet && p.type == PickupType.gem && angular < 0.22;
      if (!hit && !magnetHit) continue;

      p.collected = true;
      final at = pointOnRing(p.ring, p.angle);
      switch (p.type) {
        case PickupType.gem:
          gemsCollected++;
          bonusScore += gemScore;
          events.add(GameEvent.gem);
          _burst(at, const Color(0xFF7CFFB2), 10, 0.5);
          _addText('+$gemScore', at, const Color(0xFF7CFFB2));
        case PickupType.shield:
          hasShield = true;
          events.add(GameEvent.powerUp);
          _burst(at, const Color(0xFF5CE1FF), 16, 0.6);
          _addText('SHIELD', at, const Color(0xFF5CE1FF));
        case PickupType.slow:
          slowTimer = powerUpDuration;
          events.add(GameEvent.powerUp);
          _burst(at, const Color(0xFFB98CFF), 16, 0.6);
          _addText('SLOW-MO', at, const Color(0xFFB98CFF));
        case PickupType.magnet:
          magnetTimer = powerUpDuration;
          events.add(GameEvent.powerUp);
          _burst(at, const Color(0xFFFFB347), 16, 0.6);
          _addText('MAGNET', at, const Color(0xFFFFB347));
      }
    }
  }

  void _cleanup() {
    hazards.removeWhere((h) => h.destroyed || h.end < phi - 0.6);
    pickups.removeWhere((p) => p.collected || p.angle < phi - 0.6);
  }

  // ---- Level generation ------------------------------------------------------
  void _spawnAhead() {
    while (_nextPatternAt < phi + lookAhead) {
      _spawnPattern(_nextPatternAt);
    }
  }

  /// Places one obstacle pattern at [start] followed by a safe gap. A pattern
  /// never blocks all three rings, and gaps are wide enough to hop across
  /// every ring, so a path always exists.
  void _spawnPattern(double start) {
    final d = difficulty;
    final width = 0.35 + _rng.nextDouble() * (0.3 + 0.25 * d);
    final end = start + width;

    final rings = [0, 1, 2]..shuffle(_rng);
    final roll = _rng.nextDouble();
    final int blocked;
    if (roll < 0.5 - 0.25 * d) {
      blocked = 1;
    } else {
      blocked = 2;
    }

    final blinking = d > 0.15 && _rng.nextDouble() < 0.18 + 0.2 * d;
    for (var i = 0; i < blocked; i++) {
      final makeBlink = blinking && i == 0;
      hazards.add(
        Hazard(
          ring: rings[i],
          start: start,
          end: end,
          blinkPeriod: makeBlink ? 1.6 - 0.4 * d : 0,
          blinkOffset: makeBlink ? _rng.nextDouble() * 2 : 0,
        ),
      );
    }

    // Reward the risky line: a gem trail on a free ring inside the pattern.
    final freeRing = rings[blocked];
    if (_rng.nextDouble() < 0.35) {
      const count = 3;
      for (var i = 0; i < count; i++) {
        pickups.add(
          Pickup(
            type: PickupType.gem,
            ring: freeRing,
            angle: start + width * (i + 0.5) / count,
          ),
        );
      }
    }

    final gap = 0.8 + baseOmega * 0.3 + _rng.nextDouble() * (0.6 - 0.35 * d);
    final mid = end + gap / 2;
    final r = _rng.nextDouble();
    if (r < 0.08) {
      const types = [PickupType.shield, PickupType.slow, PickupType.magnet];
      pickups.add(
        Pickup(
          type: types[_rng.nextInt(types.length)],
          ring: _rng.nextInt(ringCount),
          angle: mid,
        ),
      );
    } else if (r < 0.75) {
      pickups.add(
        Pickup(type: PickupType.gem, ring: _rng.nextInt(ringCount), angle: mid),
      );
    }

    _nextPatternAt = end + gap;
  }

  // ---- Effects ---------------------------------------------------------------
  void _burst(Offset at, Color color, int count, double speed) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final s = speed * (0.3 + _rng.nextDouble() * 0.7);
      particles.add(
        Particle(
          x: at.dx,
          y: at.dy,
          vx: math.cos(a) * s,
          vy: math.sin(a) * s,
          life: 0.4 + _rng.nextDouble() * 0.5,
          color: color,
          size: 0.008 + _rng.nextDouble() * 0.012,
        ),
      );
    }
  }

  void _addText(String text, Offset at, Color color) {
    texts.add(FloatingText(text: text, x: at.dx, y: at.dy, color: color));
  }

  /// Returns and clears events produced since the last call.
  List<GameEvent> drainEvents() {
    if (events.isEmpty) return const [];
    final copy = List<GameEvent>.of(events);
    events.clear();
    return copy;
  }
}
