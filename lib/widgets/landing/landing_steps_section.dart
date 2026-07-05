import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class LandingStepsSection extends StatelessWidget {
  const LandingStepsSection({super.key});

  static const Color brandBlue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgLight,
      padding: const EdgeInsets.symmetric(vertical: 76, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Üç adımda dijital vitrininiz hazır',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                  letterSpacing: 0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 56),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;
                  final steps = [
                    _buildStepTimeline(
                      1,
                      'Vitrininizi kurun',
                      'İşletme bilgilerinizi, görsellerinizi, ürün ve hizmetlerinizi ekleyin.',
                    ),
                    _buildStepTimeline(
                      2,
                      'Yayınlayın',
                      'Bilgilerinizi kontrol edin; vitrin linkinizi ve QR kodunuzu hazır edin.',
                    ),
                    _buildStepTimeline(
                      3,
                      'Müşterilerinize duyurun',
                      'Linkinizi WhatsApp, sosyal medya veya işletmenizdeki QR kod ile paylaşın.',
                    ),
                  ];

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps.map((e) => Expanded(child: e)).toList(),
                    );
                  }
                  return Column(
                    children:
                        steps.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: e,
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepTimeline(int step, String title, String description) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: brandBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: brandBlue.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: const TextStyle(
              color: brandBlue,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
