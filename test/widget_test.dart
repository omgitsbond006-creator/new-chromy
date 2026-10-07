import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbiquo/core/audio.dart';
import 'package:orbiquo/core/storage.dart';
import 'package:orbiquo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameStorage> _storage([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return GameStorage.load();
}

Future<void> _pumpApp(WidgetTester tester, GameStorage storage) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  // AudioManager.init() is not called, so no platform players are created.
  await tester.pumpWidget(
      OrbiquoApp(storage: storage, audio: AudioManager(storage)));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  testWidgets('home screen shows title and menu', (tester) async {
    await _pumpApp(tester, await _storage());
    expect(find.text('ORBIQUO'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('SKINS'), findsOneWidget);
    expect(find.text('HOW TO PLAY'), findsOneWidget);
  });

  testWidgets('play a full run until game over and return home',
      (tester) async {
    final storage = await _storage();
    await _pumpApp(tester, storage);
    await tester.tap(find.text('PLAY'));
    await _frames(tester);
    expect(find.text('TAP TO START'), findsOneWidget);

    await tester.tapAt(const Offset(200, 600));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('TAP TO START'), findsNothing);

    // Idle on the middle ring until something hits us.
    var guard = 0;
    while (find.text('PLAY AGAIN').evaluate().isEmpty && guard < 3000) {
      await tester.pump(const Duration(milliseconds: 16));
      guard++;
    }
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(storage.gamesPlayed, 1);
    expect(storage.bestScore, greaterThan(0));

    await tester.tap(find.text('PLAY AGAIN'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PLAY AGAIN'), findsNothing);

    // Pause, then go home.
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PAUSED'), findsOneWidget);
    await tester.tap(find.text('HOME'));
    await _frames(tester);
    expect(find.text('ORBIQUO'), findsOneWidget);
  });

  testWidgets('back button pauses an active run', (tester) async {
    await _pumpApp(tester, await _storage());
    await tester.tap(find.text('PLAY'));
    await _frames(tester);
    await tester.tapAt(const Offset(200, 600));
    await tester.pump(const Duration(milliseconds: 100));
    final handled = await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(handled, isTrue);
    expect(find.text('PAUSED'), findsOneWidget);
    await tester.tap(find.text('RESUME'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PAUSED'), findsNothing);
  });

  testWidgets('skins can be bought and equipped', (tester) async {
    final storage = await _storage({'gems': 100});
    await _pumpApp(tester, storage);
    await tester.tap(find.text('SKINS'));
    await _frames(tester);
    expect(find.text('EMBER'), findsOneWidget);
    await tester.tap(find.text('EMBER'));
    await _frames(tester);
    expect(storage.owns('ember'), isTrue);
    expect(storage.selectedSkinId, 'ember');
    expect(storage.gems, 60);

    // Not enough gems for Mint (80).
    await tester.tap(find.text('MINT'));
    await _frames(tester);
    expect(storage.owns('mint'), isFalse);
    expect(find.textContaining('more gems'), findsOneWidget);
  });

  testWidgets('settings toggles and reset work', (tester) async {
    final storage = await _storage({'gems': 50, 'best_score': 300});
    await _pumpApp(tester, storage);
    await tester.tap(find.byTooltip('Settings'));
    await _frames(tester);
    expect(find.text('SETTINGS'), findsOneWidget);
    await tester.tap(find.text('Sound effects'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(storage.soundOn, isFalse);
    await tester.tap(find.text('Music'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(storage.musicOn, isFalse);

    await tester.scrollUntilVisible(find.text('RESET PROGRESS'), 100);
    await tester.tap(find.text('RESET PROGRESS'));
    await _frames(tester);
    await tester.tap(find.text('RESET'));
    await _frames(tester);
    expect(storage.bestScore, 0);
    expect(storage.gems, 0);
  });

  testWidgets('how to play screen renders', (tester) async {
    await _pumpApp(tester, await _storage());
    await tester.tap(find.text('HOW TO PLAY'));
    await _frames(tester);
    expect(find.text('Hop between rings'), findsOneWidget);
  });

  testWidgets('home fits on a small phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final storage = await _storage();
    await tester.pumpWidget(
        OrbiquoApp(storage: storage, audio: AudioManager(storage)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
