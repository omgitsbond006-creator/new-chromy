import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/audio.dart';
import '../core/skins.dart';
import '../core/theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/orb_view.dart';
import '../widgets/space_background.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';
import 'skins_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _musicStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_musicStarted) {
      _musicStarted = true;
      AppScope.of(context).audio.playMusic(MusicTrack.menu);
    }
  }

  Future<void> _open(Widget screen, {bool restoreMenuMusic = false}) async {
    final audio = AppScope.of(context).audio;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, a, b) => screen,
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    if (!mounted) return;
    if (restoreMenuMusic) audio.playMusic(MusicTrack.menu);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final storage = AppScope.of(context).storage;
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: storage,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Shrink the decorative orbit on short screens so the menu fits.
                  final orbitSize = math.min(
                    constraints.maxWidth * 0.7,
                    (constraints.maxHeight - 450).clamp(140.0, 300.0),
                  );
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GemCounter(gems: storage.gems),
                                const Spacer(),
                                RoundIconButton(
                                  icon: Icons.settings_rounded,
                                  tooltip: 'Settings',
                                  onPressed: () =>
                                      _open(const SettingsScreen()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FittedBox(
                              child: Text('ORBIQUO', style: titleStyle(48)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'HOP  •  DODGE  •  SURVIVE',
                              style: TextStyle(
                                color: AppColors.textDim,
                                letterSpacing: 3,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: orbitSize,
                              height: orbitSize,
                              child: _OrbitDemo(skin: storage.selectedSkin),
                            ),
                            const SizedBox(height: 12),
                            _BestScore(best: storage.bestScore),
                            const SizedBox(height: 20),
                            NeonButton(
                              label: 'PLAY',
                              icon: Icons.play_arrow_rounded,
                              filled: true,
                              onPressed: () => _open(
                                const GameScreen(),
                                restoreMenuMusic: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            NeonButton(
                              label: 'SKINS',
                              icon: Icons.palette_rounded,
                              color: AppColors.violet,
                              onPressed: () => _open(const SkinsScreen()),
                            ),
                            const SizedBox(height: 14),
                            NeonButton(
                              label: 'HOW TO PLAY',
                              icon: Icons.help_outline_rounded,
                              color: AppColors.gem,
                              onPressed: () => _open(const HowToPlayScreen()),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BestScore extends StatelessWidget {
  const _BestScore({required this.best});

  final int best;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
        const SizedBox(width: 8),
        Text(
          'BEST  $best',
          style: const TextStyle(
            fontSize: 18,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

/// Decorative animated rings with an orbiting orb.
class _OrbitDemo extends StatefulWidget {
  const _OrbitDemo({required this.skin});

  final OrbSkin skin;

  @override
  State<_OrbitDemo> createState() => _OrbitDemoState();
}

class _OrbitDemoState extends State<_OrbitDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _OrbitDemoPainter(_controller, widget.skin)),
    );
  }
}

class _OrbitDemoPainter extends CustomPainter {
  _OrbitDemoPainter(this._animation, this.skin) : super(repaint: _animation);

  final Animation<double> _animation;
  final OrbSkin skin;

  static const _radii = [0.4, 0.65, 0.9];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.shortestSide / 2;
    final t = _animation.value;

    for (var i = 0; i < _radii.length; i++) {
      canvas.drawCircle(
        c,
        _radii[i] * R,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = AppColors.cyan.withValues(alpha: 0.35 + i * 0.1),
      );
    }

    // Rotating hazard arcs.
    final hazard = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = R * 0.055
      ..color = AppColors.magenta;
    for (var i = 0; i < 3; i++) {
      final r = _radii[i] * R;
      final start = -t * math.pi * 2 * (i.isEven ? 1 : -0.7) + i * 2.1;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        0.7,
        false,
        hazard,
      );
    }

    // Gems.
    for (var i = 0; i < 4; i++) {
      final a = t * math.pi * 2 * 0.5 + i * math.pi / 2;
      final r = _radii[i % 3] * R;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a);
      final s = R * 0.03;
      final path = Path()
        ..moveTo(0, -s * 1.3)
        ..lineTo(s, 0)
        ..lineTo(0, s * 1.3)
        ..lineTo(-s, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = AppColors.gem);
      canvas.restore();
    }

    // Orb hopping between rings.
    final angle = t * math.pi * 4 - math.pi / 2;
    final ringPhase = (math.sin(t * math.pi * 2) + 1) / 2;
    final rr = (_radii[0] + (_radii[2] - _radii[0]) * ringPhase) * R;
    final orb = c + Offset(math.cos(angle), math.sin(angle)) * rr;
    paintOrb(canvas, orb, R * 0.06, skin);
  }

  @override
  bool shouldRepaint(_OrbitDemoPainter oldDelegate) => oldDelegate.skin != skin;
}
