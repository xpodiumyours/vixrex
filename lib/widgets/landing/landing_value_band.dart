import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class LandingValueBand extends StatelessWidget {
  const LandingValueBand({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgLight,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 820;
              final copy = Column(
                crossAxisAlignment:
                    isDesktop
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                children: [
                  Text(
                    'Müşterileriniz ihtiyaç duyduğu her bilgiye tek linkten ulaşsın',
                    textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Vitrin linkinizi WhatsApp, sosyal medya, Google İşletme, kartvizit, paket veya işletme içi QR kod üzerinden paylaşın.',
                    textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.darkTextAlt,
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                ],
              );
              final chips = Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: isDesktop ? WrapAlignment.end : WrapAlignment.center,
                children:
                    const [
                      'WhatsApp',
                      'Sosyal medya',
                      'Google İşletme',
                      'QR kod',
                      'Vitrin linki',
                    ].map((text) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: AppColors.darkTextAlt,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }).toList(),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: copy),
                    const SizedBox(width: 48),
                    Expanded(flex: 4, child: chips),
                  ],
                );
              }

              return Column(
                children: [copy, const SizedBox(height: 24), chips],
              );
            },
          ),
        ),
      ),
    );
  }
}
