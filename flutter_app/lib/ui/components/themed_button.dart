import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_palette.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_tokens.dart';

enum ThemedButtonType {
  primary,
  secondary,
  danger,
  reward,
  campaign,
  minimal,
}

class ThemedButton extends ConsumerWidget {
  final String label;
  final VoidCallback? onPressed;
  final ThemedButtonType type;
  final double width;
  final double height;
  final IconData? icon;
  final double iconSize;

  const ThemedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = ThemedButtonType.primary,
    this.width = ThemeTokens.btnWidth,
    this.height = ThemeTokens.btnHeight,
    this.icon,
    this.iconSize = ThemeTokens.btnIconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.palette;
    final colors = _colorsFor(palette);

    if (type == ThemedButtonType.minimal) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.textPrimary,
            side: BorderSide(color: palette.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeTokens.radiusLg)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
          child: _buildLabel(),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: palette.textPrimary,
          disabledBackgroundColor: palette.buttonDisabled,
          disabledForegroundColor: palette.textSecondary,
          elevation: colors.elevation,
          shadowColor: colors.shadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ThemeTokens.radiusLg)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
        child: _buildLabel(),
      ),
    );
  }

  Widget _buildLabel() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: ThemeTokens.btnFontSize, letterSpacing: 1.5)),
        ],
      );
    }
    return Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: ThemeTokens.btnFontSize, letterSpacing: 1.5));
  }

  _BtnColors _colorsFor(AppPalette p) => switch (type) {
    ThemedButtonType.primary => _BtnColors(p.buttonPrimary, ThemeTokens.elevationLg, p.glow.withValues(alpha: 0.3)),
    ThemedButtonType.secondary => _BtnColors(p.buttonSecondary, ThemeTokens.elevationMd, null),
    ThemedButtonType.danger => _BtnColors(p.danger, ThemeTokens.elevationLg, p.danger.withValues(alpha: 0.3)),
    ThemedButtonType.reward => _BtnColors(p.rewardGold, ThemeTokens.elevationLg, p.rewardGold.withValues(alpha: 0.3)),
    ThemedButtonType.campaign => _BtnColors(p.campaignAccent, ThemeTokens.elevationLg, p.campaignAccent.withValues(alpha: 0.3)),
    ThemedButtonType.minimal => _BtnColors(Colors.transparent, 0, null),
  };
}

class _BtnColors {
  final Color background;
  final double elevation;
  final Color? shadow;
  const _BtnColors(this.background, this.elevation, this.shadow);
}
