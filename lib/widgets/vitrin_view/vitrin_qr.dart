import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';

class VitrinQrCard extends StatelessWidget {
  final String url;
  final VitrinThemePreset preset;
  final bool isEmbedded;

  const VitrinQrCard({
    super.key,
    required this.url,
    required this.preset,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 18 : 22,
          vertical: isCompact ? 18 : 22,
        ),
        decoration: BoxDecoration(
          color: preset.qrBackground,
          borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
          border: Border.all(
            color: preset.qrForeground.withValues(alpha: 0.12),
            width: isCompact ? 1 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: isCompact ? 18 : 28,
              offset: Offset(0, isCompact ? 5 : 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Vitrin QR kodu',
              style: TextStyle(
                color: preset.qrForeground,
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            SizedBox(height: isCompact ? 4 : 6),
            Text(
              'Müşteriler bu kodu okutarak vitrininize ulaşabilir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: preset.qrForeground.withValues(alpha: 0.62),
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            SizedBox(height: isCompact ? 14 : 18),
            Container(
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                color: preset.qrBackground,
                borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
                border: Border.all(
                  color: preset.qrForeground.withValues(alpha: 0.1),
                ),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: isCompact ? 132 : 156,
                backgroundColor: preset.qrBackground,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: preset.qrForeground,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: preset.qrForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
