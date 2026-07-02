import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';
import 'package:vitrinx/widgets/vitrin_view/vitrin_view_content.dart';

class VitrinAboutCard extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;

  const VitrinAboutCard({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
  });

  @override
  Widget build(BuildContext context) {
    final aboutText = VitrinViewContent.aboutText(storeData);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isEmbedded ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isEmbedded ? 16 : 22),
        decoration: BoxDecoration(
          color: preset.surface.withValues(alpha: preset.isDark ? 0.9 : 0.98),
          borderRadius: BorderRadius.circular(isEmbedded ? 16 : 24),
          border: Border.all(
            color: preset.border.withValues(alpha: preset.isDark ? 0.9 : 0.78),
            width: isEmbedded ? 1 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: preset.isDark ? 0.12 : 0.045,
              ),
              blurRadius: isEmbedded ? 12 : 24,
              offset: Offset(0, isEmbedded ? 3 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hakkımızda',
              style: TextStyle(
                color: preset.textPrimary,
                fontSize: isEmbedded ? 14 : 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              aboutText,
              style: TextStyle(
                color: preset.textSecondary,
                fontSize: isEmbedded ? 12 : 13,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VitrinProfessionalBio extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final bool isEmbedded;

  const VitrinProfessionalBio({
    super.key,
    required this.storeData,
    required this.preset,
    required this.isEmbedded,
  });

  @override
  Widget build(BuildContext context) {
    final bioText = VitrinViewContent.professionalBioText(storeData);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isEmbedded ? 28 : 40),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: preset.accent.withValues(alpha: preset.isDark ? 0.28 : 0.18),
            size: isEmbedded ? 38 : 54,
          ),
          SizedBox(height: isEmbedded ? 4 : 8),
          Text(
            bioText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isEmbedded ? 13 : 16,
              height: isEmbedded ? 1.55 : 1.8,
              color: preset.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
