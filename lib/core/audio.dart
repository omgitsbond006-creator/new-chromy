import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'storage.dart';

enum Sfx { hop, gem, powerUp, shieldBreak, crash, milestone, click, newBest }

enum MusicTrack { menu, game }

/// Plays music and sound effects. Every call is fire-and-forget and
/// failures are swallowed so audio problems can never crash the game.
class AudioManager {
  AudioManager(this._storage);

  final GameStorage _storage;

  static const Map<Sfx, String> _sfxFiles = {
    Sfx.hop: 'audio/hop.wav',
    Sfx.gem: 'audio/gem.wav',
    Sfx.powerUp: 'audio/powerup.wav',
    Sfx.shieldBreak: 'audio/shield_break.wav',
    Sfx.crash: 'audio/crash.wav',
    Sfx.milestone: 'audio/milestone.wav',
    Sfx.click: 'audio/click.wav',
    Sfx.newBest: 'audio/new_best.wav',
  };

  static const Map<MusicTrack, String> _musicFiles = {
    MusicTrack.menu: 'audio/music_menu.wav',
    MusicTrack.game: 'audio/music_game.wav',
  };

  static const int _voicesPerSfx = 3;

  final Map<Sfx, List<AudioPlayer>> _sfxPlayers = {};
  final Map<Sfx, int> _nextVoice = {};
  AudioPlayer? _music;
  MusicTrack? _currentTrack;
  bool _initialized = false;
  bool _suspended = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );
    } catch (e) {
      debugPrint('Audio context not set: $e');
    }
    try {
      final music = AudioPlayer(playerId: 'music');
      await music.setReleaseMode(ReleaseMode.loop);
      _music = music;
      for (final sfx in Sfx.values) {
        _sfxPlayers[sfx] = List.generate(
          _voicesPerSfx,
          (i) => AudioPlayer(playerId: 'sfx_${sfx.name}_$i'),
        );
        _nextVoice[sfx] = 0;
      }
    } catch (e) {
      debugPrint('Audio unavailable: $e');
    }
  }

  void play(Sfx sfx, {double volume = 0.8}) {
    if (!_storage.soundOn || _suspended) return;
    final voices = _sfxPlayers[sfx];
    if (voices == null || voices.isEmpty) return;
    final index = _nextVoice[sfx] ?? 0;
    _nextVoice[sfx] = (index + 1) % voices.length;
    final player = voices[index];
    _guard(() async {
      await player.stop();
      await player.play(
        AssetSource(_sfxFiles[sfx]!),
        volume: volume,
        mode: kIsWeb ? PlayerMode.mediaPlayer : PlayerMode.lowLatency,
      );
    });
  }

  void playMusic(MusicTrack track) {
    _currentTrack = track;
    final music = _music;
    if (music == null || !_storage.musicOn || _suspended) return;
    _guard(() async {
      await music.stop();
      await music.play(AssetSource(_musicFiles[track]!), volume: 0.45);
    });
  }

  void stopMusic() {
    final music = _music;
    if (music == null) return;
    _guard(music.stop);
  }

  /// Called when the music setting changes.
  void refreshMusic() {
    if (_storage.musicOn) {
      playMusic(_currentTrack ?? MusicTrack.menu);
    } else {
      stopMusic();
    }
  }

  /// App went to the background.
  void suspend() {
    _suspended = true;
    final music = _music;
    if (music == null) return;
    _guard(music.pause);
  }

  /// App came back to the foreground.
  void resume() {
    _suspended = false;
    final music = _music;
    if (music == null || !_storage.musicOn || _currentTrack == null) return;
    _guard(() async {
      if (music.state == PlayerState.paused) {
        await music.resume();
      } else if (music.state != PlayerState.playing) {
        await music.play(
          AssetSource(_musicFiles[_currentTrack]!),
          volume: 0.45,
        );
      }
    });
  }

  void vibrate({bool heavy = false}) {
    if (!_storage.vibrationOn) return;
    _guard(heavy ? HapticFeedback.heavyImpact : HapticFeedback.selectionClick);
  }

  void _guard(Future<void> Function() action) {
    try {
      unawaited(
        action().catchError((Object e) {
          debugPrint('Audio error: $e');
        }),
      );
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }
}
