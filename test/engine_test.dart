import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:orbiquo/game/game_engine.dart';
import 'package:orbiquo/game/models.dart';

/// Simple look-ahead bot: moves to a ring that is free at the next obstacle.
void botStep(GameEngine e) {
  final ahead = e.hazards.where((h) => h.end > e.phi - 0.05).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  if (ahead.isEmpty) return;
  final next = ahead.first.start;
  final blocked = ahead
      .where((h) => (h.start - next).abs() < 1e-9)
      .map((h) => h.ring)
      .toSet();
  if (!blocked.contains(e.targetRing)) return;
  final free = [0, 1, 2].where((r) => !blocked.contains(r)).toList()
    ..sort((a, b) =>
        (a - e.targetRing).abs().compareTo((b - e.targetRing).abs()));
  final goal = free.first;
  if (goal < e.targetRing) {
    e.hopInward();
  } else {
    e.hopOutward();
  }
}

void main() {
  test('starts in a playable state and advances', () {
    final e = GameEngine(random: math.Random(1));
    expect(e.isOver, isFalse);
    expect(e.score, 0);
    for (var i = 0; i < 30; i++) {
      e.update(1 / 60);
    }
    expect(e.phi, greaterThan(0));
    expect(e.score, greaterThan(0));
    expect(e.isOver, isFalse, reason: 'no obstacles in the first 2.6 rad');
  });

  test('hopping is bounded to existing rings', () {
    final e = GameEngine(random: math.Random(1));
    e.hopOutward();
    e.hopOutward();
    e.hopOutward();
    expect(e.targetRing, 2);
    for (var i = 0; i < 5; i++) {
      e.hopInward();
    }
    expect(e.targetRing, 0);
    for (var i = 0; i < 20; i++) {
      e.update(1 / 60);
    }
    expect(e.ringPos, 0);
  });

  test('large or negative frame times are handled safely', () {
    final e = GameEngine(random: math.Random(1));
    e.update(-1);
    e.update(0);
    expect(e.phi, 0);
    e.update(10);
    expect(e.phi, closeTo(GameEngine.baseSpeed / 20, 0.01));
  });

  test('hitting a hazard ends the run, shield absorbs one hit', () {
    final e = GameEngine(random: math.Random(1));
    e.hazards.add(Hazard(ring: 1, start: 0.1, end: 0.4)..age = 1);
    e.hasShield = true;
    for (var i = 0; i < 20; i++) {
      e.update(1 / 60);
    }
    expect(e.isOver, isFalse);
    expect(e.hasShield, isFalse);

    e.invulnerableTimer = 0;
    e.hazards.add(Hazard(ring: 1, start: e.phi + 0.05, end: e.phi + 0.3)
      ..age = 1);
    for (var i = 0; i < 20; i++) {
      e.update(1 / 60);
    }
    expect(e.isOver, isTrue);
    expect(e.drainEvents(), contains(GameEvent.crash));
    final phiAtDeath = e.phi;
    e.update(1 / 60);
    expect(e.phi, phiAtDeath, reason: 'player stops after crashing');
  });

  test('collecting a gem adds score and gems', () {
    final e = GameEngine(random: math.Random(1));
    e.pickups.add(Pickup(type: PickupType.gem, ring: 1, angle: 0.2));
    for (var i = 0; i < 20; i++) {
      e.update(1 / 60);
    }
    expect(e.gemsCollected, 1);
    expect(e.bonusScore, GameEngine.gemScore);
  });

  test('power-ups activate', () {
    final e = GameEngine(random: math.Random(1));
    e.pickups.add(Pickup(type: PickupType.slow, ring: 1, angle: 0.1));
    e.pickups.add(Pickup(type: PickupType.magnet, ring: 1, angle: 0.3));
    e.pickups.add(Pickup(type: PickupType.shield, ring: 1, angle: 0.5));
    for (var i = 0; i < 40; i++) {
      e.update(1 / 60);
    }
    expect(e.slowTimer, greaterThan(0));
    expect(e.magnetTimer, greaterThan(0));
    expect(e.hasShield, isTrue);
  });

  test('generated patterns never block all rings and leave hop room', () {
    for (var seed = 0; seed < 20; seed++) {
      final e = GameEngine(random: math.Random(seed));
      final seen = <Hazard>{};
      // Make the run long so we also test the maximum speed.
      for (var i = 0; i < 60 * 200; i++) {
        e.invulnerableTimer = 1;
        e.update(1 / 60);
        seen.addAll(e.hazards);
      }
      expect(e.baseOmega, GameEngine.maxSpeed);
      final groups = <double, Set<int>>{};
      final ends = <double, double>{};
      for (final h in seen) {
        groups.putIfAbsent(h.start, () => <int>{}).add(h.ring);
        ends[h.start] = h.end;
      }
      expect(groups.values.every((rings) => rings.length < 3), isTrue);
      final starts = groups.keys.toList()..sort();
      for (var i = 1; i < starts.length; i++) {
        final gap = starts[i] - ends[starts[i - 1]]!;
        // At max speed two hops take 0.25 s = 0.9 rad; keep extra margin.
        expect(gap, greaterThan(1.0), reason: 'seed $seed gap $i');
      }
    }
  });

  test('a look-ahead bot can survive long runs (levels are fair)', () {
    for (var seed = 0; seed < 25; seed++) {
      final e = GameEngine(random: math.Random(seed));
      for (var i = 0; i < 60 * 150 && !e.isOver; i++) {
        botStep(e);
        e.update(1 / 60);
      }
      expect(e.isOver, isFalse, reason: 'bot died with seed $seed at ${e.time}');
      expect(e.score, greaterThan(1000));
    }
  });

  test('blinking hazards are only solid during their on phase', () {
    final h = Hazard(ring: 0, start: 0, end: 1, blinkPeriod: 1)..age = 1;
    expect(h.isSolid(0.1), isTrue);
    expect(h.isSolid(0.7), isFalse);
    expect(h.opacity(0.7), lessThan(h.opacity(0.1)));
    final fresh = Hazard(ring: 0, start: 0, end: 1);
    expect(fresh.isSolid(0), isFalse, reason: 'harmless while fading in');
  });
}
