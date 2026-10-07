import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/app_scope.dart';
import '../core/audio.dart';
import '../core/theme.dart';
import '../game/game_engine.dart';
import '../game/game_painter.dart';
import '../widgets/neon_button.dart';
import '../widgets/space_background.dart';

enum _Phase { ready, playing, paused, over }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.engineFactory});

  /// Creates the engine for each run. Defaults to a regular [GameEngine].
  final GameEngine Function()? engineFactory;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late GameEngine _engine = _newEngine();
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  final FocusNode _focusNode = FocusNode();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  _Phase _phase = _Phase.ready;
  bool _runRecorded = false;
  bool _isNewBest = false;
  bool _showOverPanel = false;
  bool _musicStarted = false;

  GameEngine _newEngine() => widget.engineFactory?.call() ?? GameEngine();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_musicStarted) {
      _musicStarted = true;
      AppScope.of(context).audio.playMusic(MusicTrack.game);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _phase == _Phase.playing) {
      _pause();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (_phase == _Phase.playing || _phase == _Phase.over) {
      _engine.update(dt);
      _handleEvents();
      if (_engine.isOver && _phase == _Phase.playing) {
        _onGameOver();
      }
      if (_phase == _Phase.over &&
          !_showOverPanel &&
          _engine.overTime > 0.9 &&
          _runRecorded) {
        setState(() => _showOverPanel = true);
      }
    }
    _frame.value++;
  }

  void _handleEvents() {
    final audio = AppScope.of(context).audio;
    for (final e in _engine.drainEvents()) {
      switch (e) {
        case GameEvent.hop:
          audio.play(Sfx.hop, volume: 0.5);
          audio.vibrate();
        case GameEvent.gem:
          audio.play(Sfx.gem, volume: 0.7);
        case GameEvent.powerUp:
          audio.play(Sfx.powerUp);
          audio.vibrate();
        case GameEvent.shieldBreak:
          audio.play(Sfx.shieldBreak);
          audio.vibrate(heavy: true);
        case GameEvent.crash:
          audio.play(Sfx.crash, volume: 0.9);
          audio.vibrate(heavy: true);
        case GameEvent.milestone:
          audio.play(Sfx.milestone, volume: 0.6);
      }
    }
  }

  Future<void> _onGameOver() async {
    setState(() => _phase = _Phase.over);
    final scope = AppScope.of(context);
    final isBest = await scope.storage.recordRun(
      score: _engine.score,
      gemsEarned: _engine.gemsCollected,
    );
    if (!mounted) return;
    if (isBest && _engine.score > 0) {
      scope.audio.play(Sfx.newBest);
    }
    setState(() {
      _isNewBest = isBest && _engine.score > 0;
      _runRecorded = true;
    });
  }

  void _start() {
    final storage = AppScope.of(context).storage;
    if (!storage.tutorialSeen) storage.setTutorialSeen();
    setState(() => _phase = _Phase.playing);
  }

  void _pause() {
    if (_phase != _Phase.playing) return;
    setState(() => _phase = _Phase.paused);
  }

  void _resume() {
    if (_phase != _Phase.paused) return;
    setState(() => _phase = _Phase.playing);
    _focusNode.requestFocus();
  }

  void _restart() {
    setState(() {
      _engine = _newEngine();
      _phase = _Phase.playing;
      _runRecorded = false;
      _isNewBest = false;
      _showOverPanel = false;
    });
    _focusNode.requestFocus();
  }

  void _exit() {
    Navigator.of(context).maybePop();
  }

  void _onTapDown(TapDownDetails details, double width) {
    switch (_phase) {
      case _Phase.ready:
        _start();
      case _Phase.playing:
        if (details.localPosition.dx < width / 2) {
          _engine.hopInward();
        } else {
          _engine.hopOutward();
        }
      case _Phase.paused:
      case _Phase.over:
        break;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (_phase == _Phase.ready &&
        (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter)) {
      _start();
      return KeyEventResult.handled;
    }
    if (_phase != _Phase.playing) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      _engine.hopInward();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      _engine.hopOutward();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
      _pause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final storage = AppScope.of(context).storage;
    return PopScope(
      canPop: _phase != _Phase.playing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Scaffold(
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: SpaceBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _onTapDown(d, constraints.maxWidth),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: GamePainter(
                            engine: _engine,
                            skin: storage.selectedSkin,
                            repaint: _frame,
                          ),
                        ),
                      ),
                    ),
                    if (_phase == _Phase.playing || _phase == _Phase.ready)
                      _ZoneHints(highlight: _phase == _Phase.ready),
                    SafeArea(child: _buildHud(storage.bestScore)),
                    if (_phase == _Phase.ready) _buildReady(),
                    if (_phase == _Phase.paused) _buildPaused(),
                    if (_phase == _Phase.over && _showOverPanel)
                      _buildGameOver(storage.bestScore),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHud(int best) {
    return ValueListenableBuilder<int>(
      valueListenable: _frame,
      builder: (context, frame, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  if (_phase == _Phase.playing)
                    RoundIconButton(
                      icon: Icons.pause_rounded,
                      tooltip: 'Pause',
                      onPressed: _pause,
                    )
                  else
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onPressed: _exit,
                    ),
                  const SizedBox(width: 12),
                  GemCounter(gems: _engine.gemsCollected),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'BEST',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: AppColors.textDim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$best',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (_engine.hasShield)
                    const _PowerChip(
                      icon: Icons.shield,
                      color: AppColors.cyan,
                      progress: 1,
                    ),
                  if (_engine.slowTimer > 0)
                    _PowerChip(
                      icon: Icons.hourglass_bottom,
                      color: AppColors.violet,
                      progress: _engine.slowTimer / GameEngine.powerUpDuration,
                    ),
                  if (_engine.magnetTimer > 0)
                    _PowerChip(
                      icon: Icons.bolt,
                      color: AppColors.orange,
                      progress:
                          _engine.magnetTimer / GameEngine.powerUpDuration,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReady() {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TAP TO START', style: titleStyle(24)),
            const SizedBox(height: 8),
            const Text(
              'Dodge the red arcs. Grab the gems.',
              style: TextStyle(color: AppColors.textDim, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaused() {
    return _Overlay(
      children: [
        Text('PAUSED', style: titleStyle(34)),
        const SizedBox(height: 32),
        NeonButton(
          label: 'RESUME',
          icon: Icons.play_arrow_rounded,
          filled: true,
          onPressed: _resume,
        ),
        const SizedBox(height: 16),
        NeonButton(
          label: 'RESTART',
          icon: Icons.refresh_rounded,
          onPressed: _restart,
        ),
        const SizedBox(height: 16),
        NeonButton(
          label: 'HOME',
          icon: Icons.home_rounded,
          color: AppColors.violet,
          onPressed: _exit,
        ),
      ],
    );
  }

  Widget _buildGameOver(int best) {
    return _Overlay(
      children: [
        Text(
          _isNewBest ? 'NEW BEST!' : 'GAME OVER',
          style: titleStyle(
            32,
            color: _isNewBest ? AppColors.gold : AppColors.text,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${_engine.score}',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            shadows: [Shadow(color: AppColors.cyan, blurRadius: 20)],
          ),
        ),
        Text(
          'BEST  $best',
          style: const TextStyle(
            fontSize: 16,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: AppColors.gem, size: 20),
            const SizedBox(width: 6),
            Text(
              '+${_engine.gemsCollected} gems',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gem,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        NeonButton(
          label: 'PLAY AGAIN',
          icon: Icons.replay_rounded,
          filled: true,
          onPressed: _restart,
        ),
        const SizedBox(height: 16),
        NeonButton(
          label: 'HOME',
          icon: Icons.home_rounded,
          color: AppColors.violet,
          onPressed: _exit,
        ),
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background.withValues(alpha: 0.78),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

class _ZoneHints extends StatelessWidget {
  const _ZoneHints({required this.highlight});

  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final alpha = highlight ? 0.9 : 0.35;
    final style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
      color: AppColors.text.withValues(alpha: alpha),
    );
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_double_arrow_left_rounded,
                  color: AppColors.cyan.withValues(alpha: alpha),
                ),
                const SizedBox(width: 4),
                Text('INNER', style: style),
                const Spacer(),
                Text('OUTER', style: style),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  color: AppColors.cyan.withValues(alpha: alpha),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerChip extends StatelessWidget {
  const _PowerChip({
    required this.icon,
    required this.color,
    required this.progress,
  });

  final IconData icon;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 3,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
          Icon(icon, color: color, size: 20),
        ],
      ),
    );
  }
}
