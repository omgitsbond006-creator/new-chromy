import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/neon_button.dart';
import '../widgets/space_background.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _tips = [
    (
      Icons.touch_app_rounded,
      AppColors.cyan,
      'Hop between rings',
      'Tap the LEFT half of the screen to hop to the inner ring and the '
          'RIGHT half to hop to the outer ring.',
    ),
    (
      Icons.block_rounded,
      AppColors.magenta,
      'Dodge the arcs',
      'Red arcs end your run. Orange arcs flicker on and off - watch the '
          'rhythm and slip through when they fade.',
    ),
    (
      Icons.diamond_rounded,
      AppColors.gem,
      'Collect gems',
      'Every gem adds 10 points and goes to your wallet. Spend gems on new '
          'orb skins.',
    ),
    (
      Icons.shield_rounded,
      AppColors.cyan,
      'Shield',
      'Absorbs one hit and breaks the arc you touch.',
    ),
    (
      Icons.hourglass_bottom_rounded,
      AppColors.violet,
      'Slow-mo',
      'Slows your orbit for a few seconds.',
    ),
    (
      Icons.bolt_rounded,
      AppColors.orange,
      'Magnet',
      'Pulls in gems from every ring for a few seconds.',
    ),
    (
      Icons.speed_rounded,
      AppColors.gold,
      'Keep going',
      'Your orbit speeds up the longer you survive. Every 250 points is a '
          'new milestone!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Column(
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
                    Flexible(
                      child: FittedBox(
                        child: Text('HOW TO PLAY', style: titleStyle(24)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tips.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final (icon, color, title, body) = _tips[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.panel.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: color.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.15),
                            ),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
