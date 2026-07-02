import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/landing/landing_setup_panel.dart';

class LandingComparisonSection extends StatelessWidget {
  const LandingComparisonSection({super.key});

  static const Color brandBlue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    const separateSetupItems = [
      (Icons.language_rounded, 'Domain ve hosting'),
      (Icons.tune_rounded, 'Teknik ayarlar'),
      (Icons.chat_bubble_outline_rounded, 'WhatsApp bağlantısı'),
      (Icons.qr_code_2_rounded, 'QR ve paylaşım süreci'),
      (Icons.support_agent_rounded, 'İçerik güncelleme desteği'),
    ];
    const vitrinxSetupItems = [
      (Icons.storefront_rounded, 'İşletme bilgileri ve fotoğraflar'),
      (Icons.inventory_2_rounded, 'Ürünler ve hizmetler'),
      (Icons.hub_rounded, 'WhatsApp, adres, link ve QR'),
      (Icons.edit_note_rounded, 'Panelden kolay güncelleme'),
      (Icons.forum_rounded, 'Müşteriyle doğrudan iletişim'),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.bgEditor,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Dijital vitrininiz için gerekenler tek yerde',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkText,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Araçları ve kurulumları ayrı ayrı yönetmek yerine işletme bilgilerinizi VitrinX’e ekleyin ve paylaşmaya başlayın.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.mutedText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 820;
                  final separatePanel = LandingSetupPanel(
                    label: 'Ayrı ayrı kurulum',
                    items: separateSetupItems,
                    footer: 'Birden fazla araç ve işlem',
                    highlighted: false,
                  );
                  final vitrinxPanel = LandingSetupPanel(
                    label: 'VitrinX ile',
                    items: vitrinxSetupItems,
                    footer: 'Tek panel, tek link, doğrudan iletişim',
                    highlighted: true,
                  );
                  final direction = Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDesktop
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_downward_rounded,
                      color: brandBlue,
                    ),
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: separatePanel),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: direction,
                        ),
                        Expanded(child: vitrinxPanel),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      separatePanel,
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: direction,
                      ),
                      vitrinxPanel,
                    ],
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
