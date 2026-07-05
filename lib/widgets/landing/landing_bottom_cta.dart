import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/config/legal_config.dart';
import 'package:vixrex/config/app_router.dart';

class LandingBottomCta extends StatelessWidget {
  final VoidCallback onNavigateToEditor;

  const LandingBottomCta({
    super.key,
    required this.onNavigateToEditor,
  });

  static const Color brandBlue = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBottomCTA(context),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgEditor, brandBlue],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              const Text(
                'İşletmenizi tek linkte müşterilerinizle buluşturun',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.surfaceSoft,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'VixRex’inizi oluşturun; linkinizi, QR kodunuzu ve WhatsApp iletişiminizi paylaşmaya başlayın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.border,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: onNavigateToEditor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 10,
                ),
                child: const Text(
                  'VixRex Oluştur',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgEditor,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text(
            'VITRINX',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: brandBlue.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'İşletmenizin paylaşılabilir dijital vitrini',
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFooterLegalLink(
                context: context,
                label: 'KVKK ve Gizlilik Politikası',
                routePath: LegalConfig.privacyPath,
              ),
              _buildFooterLegalLink(
                context: context,
                label: 'Kullanım Şartları',
                routePath: LegalConfig.termsPath,
              ),
              _buildFooterLegalLink(
                context: context,
                label: 'Veri Silme',
                routePath: LegalConfig.dataDeletionPath,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLegalLink({
    required BuildContext context,
    required String label,
    required String routePath,
  }) {
    return TextButton(
      onPressed: () => AppRouter.push(context, routePath),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mutedText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}
