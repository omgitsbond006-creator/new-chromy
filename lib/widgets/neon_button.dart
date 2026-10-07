import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/audio.dart';
import '../core/theme.dart';

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.cyan,
    this.filled = false,
    this.width = 240,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled;
  final double width;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final c = enabled ? color : AppColors.textDim;
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: enabled
            ? [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 18)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: enabled
              ? () {
                  AppScope.of(context).audio.play(Sfx.click, volume: 0.6);
                  onPressed!();
                }
              : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: c, width: 2),
              gradient: filled
                  ? LinearGradient(
                      colors: [
                        c.withValues(alpha: 0.85),
                        Color.lerp(
                          c,
                          AppColors.magenta,
                          0.55,
                        )!.withValues(alpha: 0.85),
                      ],
                    )
                  : null,
              color: filled ? null : AppColors.panel,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: filled ? Colors.white : c, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: filled ? Colors.white : c,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.cyan,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.panel.withValues(alpha: 0.7),
      shape: CircleBorder(side: BorderSide(color: color, width: 1.5)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          AppScope.of(context).audio.play(Sfx.click, volume: 0.6);
          onPressed();
        },
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

class GemCounter extends StatelessWidget {
  const GemCounter({super.key, required this.gems, this.size = 18});

  final int gems;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gem.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond, color: AppColors.gem, size: size),
          const SizedBox(width: 6),
          Text(
            '$gems',
            style: TextStyle(
              fontSize: size * 0.9,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
