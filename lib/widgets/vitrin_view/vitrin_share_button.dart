import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';

class VitrinShareButton extends StatelessWidget {
  final VitrinThemePreset preset;
  final bool isEmbedded;
  final VoidCallback onTap;

  const VitrinShareButton({
    super.key,
    required this.preset,
    required this.isEmbedded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(isEmbedded ? 8.0 : 12.0),
                child: Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: isEmbedded ? 16 : 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
