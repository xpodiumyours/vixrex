import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/landing/landing_value_card.dart';

class LandingFeaturesSection extends StatelessWidget {
  const LandingFeaturesSection({super.key});

  static const Color brandBlue = AppColors.primary;
  static const Color mint = AppColors.landingMint;
  static const Color blueAccent = AppColors.landingBlueAccent;
  static const Color pinkAccent = AppColors.landingPinkAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgLight,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Dijital vitrininizi kolayca hazırlayın',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Müşterilerinizin ihtiyaç duyduğu bilgileri tek vitrinde toplayın, panelden yönetin ve istediğiniz yerde paylaşın.',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.darkTextAlt,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 1040;
                  final isTablet = constraints.maxWidth > 680;
                  final cardWidth =
                      isDesktop
                          ? (constraints.maxWidth - 54) / 4
                          : isTablet
                          ? (constraints.maxWidth - 18) / 2
                          : constraints.maxWidth;
                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    alignment: WrapAlignment.center,
                    children:
                        [
                          LandingValueCard(
                            icon: Icons.bolt_rounded,
                            color: brandBlue,
                            title: 'Dakikalar içinde yayına alın',
                            desc:
                                'Temel bilgilerinizi ekleyin ve vitrininizi oluşturun.',
                            isHorizontal: !isTablet,
                            enableHover: isDesktop,
                          ),
                          LandingValueCard(
                            icon: Icons.contact_phone_rounded,
                            color: mint,
                            title: 'Müşteriler size doğrudan ulaşsın',
                            desc:
                                'WhatsApp, adres ve yol tarifi seçeneklerini tek yerde sunun.',
                            isHorizontal: !isTablet,
                            enableHover: isDesktop,
                          ),
                          LandingValueCard(
                            icon: Icons.share_rounded,
                            color: pinkAccent,
                            title: 'Her kanalda aynı vitrini paylaşın',
                            desc:
                                'Linkinizi sosyal medyada, QR kodunuzu işletmenizde kullanın.',
                            isHorizontal: !isTablet,
                            enableHover: isDesktop,
                          ),
                          LandingValueCard(
                            icon: Icons.edit_note_rounded,
                            color: blueAccent,
                            title: 'Bilgilerinizi panelden güncelleyin',
                            desc:
                                'Fotoğraf, ürün, hizmet ve iletişim bilgilerinizi istediğiniz zaman düzenleyin.',
                            isHorizontal: !isTablet,
                            enableHover: isDesktop,
                          ),
                        ].map((widget) => SizedBox(width: cardWidth, child: widget)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
