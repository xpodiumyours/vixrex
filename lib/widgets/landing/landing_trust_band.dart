import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class LandingTrustBand extends StatelessWidget {
  const LandingTrustBand({super.key});

  static const Color brandBlue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.credit_card_off_rounded, 'Kredi kartı gerekmez'),
      (Icons.percent_rounded, 'Satıştan komisyon alınmaz'),
      (Icons.code_off_rounded, 'Kodsuz kurulum'),
      (Icons.qr_code_2_rounded, 'Link ve QR kod hazırdır'),
      (Icons.chat_bubble_rounded, 'WhatsApp ile doğrudan iletişim'),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.bgLight,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'Başlarken sürpriz yok',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children:
                    items
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(item.$1, color: brandBlue, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  item.$2,
                                  style: const TextStyle(
                                    color: AppColors.darkText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
