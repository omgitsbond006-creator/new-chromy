import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'skins.dart';

/// Persistent player progress and settings, stored on the device only.
class GameStorage extends ChangeNotifier {
  GameStorage._(this._prefs);

  final SharedPreferences _prefs;

  static const _kBest = 'best_score';
  static const _kGems = 'gems';
  static const _kGames = 'games_played';
  static const _kOwned = 'owned_skins';
  static const _kSkin = 'selected_skin';
  static const _kSound = 'sound_on';
  static const _kMusic = 'music_on';
  static const _kVibration = 'vibration_on';
  static const _kTutorial = 'tutorial_seen';

  static Future<GameStorage> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GameStorage._(prefs);
  }

  int get bestScore => _prefs.getInt(_kBest) ?? 0;
  int get gems => _prefs.getInt(_kGems) ?? 0;
  int get gamesPlayed => _prefs.getInt(_kGames) ?? 0;
  bool get soundOn => _prefs.getBool(_kSound) ?? true;
  bool get musicOn => _prefs.getBool(_kMusic) ?? true;
  bool get vibrationOn => _prefs.getBool(_kVibration) ?? true;
  bool get tutorialSeen => _prefs.getBool(_kTutorial) ?? false;

  List<String> get ownedSkins {
    final owned = _prefs.getStringList(_kOwned) ?? const <String>[];
    return {kSkins.first.id, ...owned}.toList();
  }

  String get selectedSkinId {
    final id = _prefs.getString(_kSkin) ?? kSkins.first.id;
    return ownedSkins.contains(id) ? id : kSkins.first.id;
  }

  OrbSkin get selectedSkin => skinById(selectedSkinId);

  bool owns(String skinId) => ownedSkins.contains(skinId);

  /// Records a finished run. Returns true when it is a new best score.
  Future<bool> recordRun({required int score, required int gemsEarned}) async {
    final isBest = score > bestScore;
    if (isBest) await _prefs.setInt(_kBest, score);
    await _prefs.setInt(_kGems, gems + gemsEarned);
    await _prefs.setInt(_kGames, gamesPlayed + 1);
    notifyListeners();
    return isBest;
  }

  /// Buys a skin if affordable. Returns true on success.
  Future<bool> buySkin(OrbSkin skin) async {
    if (owns(skin.id)) return true;
    if (gems < skin.price) return false;
    await _prefs.setInt(_kGems, gems - skin.price);
    await _prefs.setStringList(_kOwned, [...ownedSkins, skin.id]);
    notifyListeners();
    return true;
  }

  Future<void> selectSkin(String skinId) async {
    if (!owns(skinId)) return;
    await _prefs.setString(_kSkin, skinId);
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    await _prefs.setBool(_kSound, value);
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    await _prefs.setBool(_kMusic, value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    await _prefs.setBool(_kVibration, value);
    notifyListeners();
  }

  Future<void> setTutorialSeen() async {
    await _prefs.setBool(_kTutorial, true);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await _prefs.remove(_kBest);
    await _prefs.remove(_kGems);
    await _prefs.remove(_kGames);
    await _prefs.remove(_kOwned);
    await _prefs.remove(_kSkin);
    await _prefs.remove(_kTutorial);
    notifyListeners();
  }
}
