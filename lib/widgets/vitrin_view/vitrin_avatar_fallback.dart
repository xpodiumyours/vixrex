import 'package:flutter/material.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';

class VitrinStoreAvatar extends StatelessWidget {
  final VitrinThemePreset preset;
  final double size;
  final String monogramText;
  final String? logoUrl;

  const VitrinStoreAvatar({
    super.key,
    required this.preset,
    required this.size,
    required this.monogramText,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLogoUrl = logoUrl?.trim() ?? '';

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size > 100 ? 4 : 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: preset.background,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.86),
          width: size > 100 ? 2.6 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child:
            effectiveLogoUrl.isNotEmpty
                ? Image.network(
                  effectiveLogoUrl,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (_, __, ___) => VitrinAvatarFallback(
                        preset: preset,
                        size: size,
                        text: monogramText,
                      ),
                )
                : VitrinAvatarFallback(
                  preset: preset,
                  size: size,
                  text: monogramText,
                ),
      ),
    );
  }
}

class VitrinAvatarFallback extends StatelessWidget {
  final VitrinThemePreset preset;
  final double size;
  final String text;

  const VitrinAvatarFallback({
    super.key,
    required this.preset,
    required this.size,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            preset.surfaceSoft.withValues(alpha: 0.96),
            preset.surface.withValues(alpha: 0.96),
            preset.background,
          ],
        ),
      ),
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class VitrinVxMonogram extends StatelessWidget {
  final VitrinThemePreset preset;
  final double avatarRadius;
  final String text;

  const VitrinVxMonogram({
    super.key,
    required this.preset,
    required this.avatarRadius,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final monogramColor = preset.isDark ? preset.textPrimary : preset.accent;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            preset.accent.withValues(alpha: preset.isDark ? 0.24 : 0.14),
            preset.surface.withValues(alpha: preset.isDark ? 0.9 : 0.96),
            preset.surfaceSoft.withValues(alpha: preset.isDark ? 0.74 : 0.9),
          ],
        ),
        border: Border.all(
          color: preset.accent.withValues(alpha: preset.isDark ? 0.3 : 0.2),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: monogramColor,
            fontSize: avatarRadius * 0.62,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
