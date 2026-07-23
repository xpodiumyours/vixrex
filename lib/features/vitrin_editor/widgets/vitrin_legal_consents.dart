import 'package:flutter/material.dart';
import 'package:vitrinx/config/app_router.dart';
import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/models/legal_document.dart';
import 'package:vitrinx/screens/legal_screen.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/theme/app_text_styles.dart';

/// Yasal bilgilendirme ve yayınlama onayı bölümü.
/// Üç ayrı onay kutusu (Aydınlatma Metni, Kullanım Şartları, Açık Rıza) içerir.
class VitrinLegalConsents extends StatelessWidget {
  final bool privacyNoticeAcknowledged;
  final bool termsAccepted;
  final bool publicationConsentAccepted;
  final PublishingLegalDocuments? legalDocuments;
  final bool isLoadingLegalDocuments;
  final String? legalDocumentsError;
  final void Function(bool) onPrivacyChanged;
  final void Function(bool) onTermsChanged;
  final void Function(bool) onConsentChanged;
  final VoidCallback onRetryLoad;

  static const Color _primaryColor = AppColors.primary;
  static const Color _cardBorder = AppColors.cardBorderDark;

  const VitrinLegalConsents({
    super.key,
    required this.privacyNoticeAcknowledged,
    required this.termsAccepted,
    required this.publicationConsentAccepted,
    required this.legalDocuments,
    required this.isLoadingLegalDocuments,
    required this.legalDocumentsError,
    required this.onPrivacyChanged,
    required this.onTermsChanged,
    required this.onConsentChanged,
    required this.onRetryLoad,
  });

  bool get _canAccept =>
      !isLoadingLegalDocuments &&
      legalDocuments != null &&
      LegalConfig.hasCompleteDataControllerIdentity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: _primaryColor,
                size: 21,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yasal Bilgilendirme ve Yayınlama Onayı',
                  style: AppTextStyles.subTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Taslağınızı onay vermeden düzenleyebilirsiniz. Bu beyanlar yalnızca herkese açık yayınlama için gereklidir.',
            style: AppTextStyles.caption,
          ),
          if (!LegalConfig.hasCompleteDataControllerIdentity) ...[
            const SizedBox(height: 12),
            const Text(
              'Xpodiumyours resmî unvan ve adres bilgileri tamamlanmadığı için yayınlama geçici olarak kapalıdır.',
              style: AppTextStyles.errorText,
            ),
          ] else if (isLoadingLegalDocuments) ...[
            const SizedBox(height: 14),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ] else if (legalDocumentsError != null) ...[
            const SizedBox(height: 12),
            Text(legalDocumentsError!, style: AppTextStyles.errorText),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onRetryLoad,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Belgeleri Tekrar Yükle'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          CheckboxListTile(
            key: const ValueKey('privacy-notice-checkbox'),
            value: privacyNoticeAcknowledged,
            onChanged:
                _canAccept ? (value) => onPrivacyChanged(value ?? false) : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Aydınlatma Metni'ni okudum ve bilgilendirildim.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(
            context: context,
            label: 'Aydınlatma Metni',
            type: LegalPageType.privacy,
          ),
          CheckboxListTile(
            key: const ValueKey('terms-checkbox'),
            value: termsAccepted,
            onChanged:
                _canAccept ? (value) => onTermsChanged(value ?? false) : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Kullanım Şartları'nı kabul ediyorum.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(
            context: context,
            label: 'Kullanım Şartları',
            type: LegalPageType.terms,
          ),
          CheckboxListTile(
            key: const ValueKey('publication-consent-checkbox'),
            value: publicationConsentAccepted,
            onChanged:
                _canAccept
                    ? (value) => onConsentChanged(value ?? false)
                    : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Verilerimin dijital vitrinimde kamuya açık yayınlanmasına açık rıza veriyorum.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(
            context: context,
            label: 'Açık Rıza Beyanı',
            type: LegalPageType.consent,
          ),
        ],
      ),
    );
  }

  Widget _legalLink({
    required BuildContext context,
    required String label,
    required LegalPageType type,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => AppRouter.navigateToLegal(context, type),
        icon: const Icon(Icons.open_in_new_rounded, size: 15),
        label: Text(label),
      ),
    );
  }
}
