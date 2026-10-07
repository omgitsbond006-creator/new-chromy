import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/space_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final storage = AppScope.of(context).storage;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'Your best score, gems and unlocked skins will be erased. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'RESET',
              style: TextStyle(color: AppColors.magenta),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await storage.resetProgress();
    messenger.showSnackBar(
      const SnackBar(content: Text('Progress has been reset.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final storage = scope.storage;
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: storage,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 16),
                      Text('SETTINGS', style: titleStyle(24)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Panel(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.music_note_rounded,
                          color: AppColors.cyan,
                        ),
                        title: const Text('Music'),
                        value: storage.musicOn,
                        onChanged: (v) async {
                          await storage.setMusic(v);
                          scope.audio.refreshMusic();
                        },
                      ),
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.cyan,
                        ),
                        title: const Text('Sound effects'),
                        value: storage.soundOn,
                        onChanged: storage.setSound,
                      ),
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.vibration_rounded,
                          color: AppColors.cyan,
                        ),
                        title: const Text('Vibration'),
                        value: storage.vibrationOn,
                        onChanged: storage.setVibration,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Panel(
                    children: [
                      _StatRow(
                        icon: Icons.emoji_events_rounded,
                        label: 'Best score',
                        value: '${storage.bestScore}',
                      ),
                      _StatRow(
                        icon: Icons.sports_esports_rounded,
                        label: 'Games played',
                        value: '${storage.gamesPlayed}',
                      ),
                      _StatRow(
                        icon: Icons.diamond_rounded,
                        label: 'Gems',
                        value: '${storage.gems}',
                      ),
                      _StatRow(
                        icon: Icons.palette_rounded,
                        label: 'Skins unlocked',
                        value: '${storage.ownedSkins.length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: NeonButton(
                      label: 'RESET PROGRESS',
                      icon: Icons.delete_forever_rounded,
                      color: AppColors.magenta,
                      width: 280,
                      onPressed: () => _confirmReset(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Orbiquo v1.0.0\nAll progress is stored only on this device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel.withValues(alpha: 0.8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: children),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: AppColors.text,
        ),
      ),
    );
  }
}
