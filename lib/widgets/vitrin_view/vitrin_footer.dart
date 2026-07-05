import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/vitrin_theme_preset.dart';

class VitrinFooter extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool publicMode;

  const VitrinFooter({
    super.key,
    required this.storeData,
    required this.preset,
    this.publicMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          publicMode
              ? 'Bu vitrin VixRex ile oluşturuldu'
              : 'vixrex.app/${storeData.name.toLowerCase().replaceAll(' ', '-')}',
          style: TextStyle(
            fontSize: publicMode ? 12 : 14,
            fontWeight: publicMode ? FontWeight.w700 : FontWeight.w800,
            color: preset.textSecondary.withValues(
              alpha: preset.isDark ? 0.86 : 0.78,
            ),
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: publicMode ? 26 : 48),
        Container(
          height: 1,
          width: publicMode ? 34 : 50,
          color: preset.border.withValues(alpha: publicMode ? 0.7 : 1),
        ),
        SizedBox(height: publicMode ? 18 : 24),
        if (!publicMode)
          Text(
            'BU BİR VITRINX DİJİTAL KİMLİĞİDİR',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: preset.textSecondary.withValues(alpha: 0.72),
              letterSpacing: 4,
            ),
          ),
      ],
    );
  }
}
