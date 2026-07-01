import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/vitrin_theme_preset.dart';

class VitrinPremiumIdentityCard extends StatelessWidget {
  final StoreData storeData;
  final VitrinThemePreset preset;
  final double radius;
  final bool isEmbedded;
  final VoidCallback? onSharePressed;

  const VitrinPremiumIdentityCard({
    super.key,
    required this.storeData,
    required this.preset,
    required this.radius,
    required this.isEmbedded,
    this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = isEmbedded;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 24),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 18 : 28),
        decoration: BoxDecoration(
          color: preset.qrBackground,
          borderRadius: BorderRadius.circular(isCompact ? 20 : radius),
          border: Border.all(
            color: preset.qrForeground.withValues(alpha: 0.14),
            width: isCompact ? 1.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: isCompact ? 24 : 40,
              offset: Offset(0, isCompact ? 8 : 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 14),
                  decoration: BoxDecoration(
                    color: preset.qrForeground.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: isCompact ? 34 : 54,
                    color: preset.qrForeground,
                  ),
                ),
                SizedBox(width: isCompact ? 14 : 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeData.name.isEmpty
                            ? 'VitrinX Kart'
                            : storeData.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isCompact ? 16 : 20,
                          color: preset.qrForeground,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                      Text(
                        'TÜM BİLGİLERİM TEK QR İLE BURADA',
                        style: TextStyle(
                          fontSize: isCompact ? 8 : 10,
                          color: preset.qrForeground.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w900,
                          letterSpacing: isCompact ? 0.8 : 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 18 : 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSharePressed ?? () {},
                icon: Icon(Icons.share_rounded, size: isCompact ? 16 : 20),
                label: Text(
                  'PROFİLİ PAYLAŞ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isCompact ? 11 : 13,
                    letterSpacing: isCompact ? 1 : 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: preset.accent,
                  foregroundColor: preset.buttonText,
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
