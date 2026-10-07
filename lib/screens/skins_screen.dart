import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/audio.dart';
import '../core/skins.dart';
import '../core/theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/orb_view.dart';
import '../widgets/space_background.dart';

class SkinsScreen extends StatelessWidget {
  const SkinsScreen({super.key});

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
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 16),
                        Text('SKINS', style: titleStyle(24)),
                        const Spacer(),
                        GemCounter(gems: storage.gems),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Collect gems in runs to unlock new orbs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textDim),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: kSkins.length,
                      itemBuilder: (context, i) => _SkinTile(skin: kSkins[i]),
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

class _SkinTile extends StatelessWidget {
  const _SkinTile({required this.skin});

  final OrbSkin skin;

  Future<void> _onTap(BuildContext context) async {
    final scope = AppScope.of(context);
    final storage = scope.storage;
    if (storage.owns(skin.id)) {
      scope.audio.play(Sfx.click, volume: 0.6);
      await storage.selectSkin(skin.id);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (storage.gems < skin.price) {
      scope.audio.play(Sfx.click, volume: 0.6);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'You need ${skin.price - storage.gems} more gems for ${skin.name}.',
            ),
          ),
        );
      return;
    }
    final ok = await storage.buySkin(skin);
    if (ok) {
      scope.audio.play(Sfx.powerUp);
      await storage.selectSkin(skin.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${skin.name} unlocked!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = AppScope.of(context).storage;
    final owned = storage.owns(skin.id);
    final selected = storage.selectedSkinId == skin.id;
    final affordable = storage.gems >= skin.price;

    return Material(
      color: AppColors.panel.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? skin.glow
              : AppColors.textDim.withValues(alpha: 0.3),
          width: selected ? 2.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OrbView(skin: skin, size: 84),
              Text(
                skin.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 15,
                ),
              ),
              if (selected)
                const _Badge(text: 'EQUIPPED', color: AppColors.cyan)
              else if (owned)
                const _Badge(text: 'TAP TO EQUIP', color: AppColors.textDim)
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.diamond,
                      size: 16,
                      color: affordable ? AppColors.gem : AppColors.textDim,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${skin.price}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: affordable ? AppColors.gem : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}
