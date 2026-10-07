import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_scope.dart';
import 'core/audio.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final storage = await GameStorage.load();
  final audio = AudioManager(storage);
  await audio.init();

  runApp(OrbiquoApp(storage: storage, audio: audio));
}

class OrbiquoApp extends StatefulWidget {
  const OrbiquoApp({super.key, required this.storage, required this.audio});

  final GameStorage storage;
  final AudioManager audio;

  @override
  State<OrbiquoApp> createState() => _OrbiquoAppState();
}

class _OrbiquoAppState extends State<OrbiquoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        widget.audio.resume();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        widget.audio.suspend();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      storage: widget.storage,
      audio: widget.audio,
      child: MaterialApp(
        title: 'Orbiquo',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
