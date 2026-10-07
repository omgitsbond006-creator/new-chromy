import 'package:flutter/widgets.dart';

import 'audio.dart';
import 'storage.dart';

/// Makes the shared [GameStorage] and [AudioManager] available to all
/// screens.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.storage,
    required this.audio,
    required super.child,
  });

  final GameStorage storage;
  final AudioManager audio;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      storage != oldWidget.storage || audio != oldWidget.audio;
}
