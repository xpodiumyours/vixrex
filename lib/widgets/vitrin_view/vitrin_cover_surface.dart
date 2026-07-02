import 'package:flutter/material.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';

class VitrinCoverSurface extends StatelessWidget {
  final VitrinThemePreset preset;
  final Widget? heroChild;
  final Widget? centeredChild;
  final List<Color> overlayColors;
  final Alignment begin;
  final Alignment end;

  const VitrinCoverSurface({
    super.key,
    required this.preset,
    required this.overlayColors,
    this.heroChild,
    this.centeredChild,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        heroChild ?? VitrinHeaderFallbackSurface(preset: preset),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: overlayColors,
            ),
          ),
        ),
        if (heroChild == null && centeredChild != null)
          Center(child: centeredChild),
      ],
    );
  }
}

class VitrinHeaderFallbackSurface extends StatelessWidget {
  final VitrinThemePreset preset;

  const VitrinHeaderFallbackSurface({super.key, required this.preset});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            preset.accent.withValues(alpha: preset.isDark ? 0.2 : 0.16),
            preset.surfaceSoft.withValues(alpha: preset.isDark ? 0.42 : 0.88),
            preset.background.withValues(alpha: preset.isDark ? 0.96 : 0.98),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
    );
  }
}
