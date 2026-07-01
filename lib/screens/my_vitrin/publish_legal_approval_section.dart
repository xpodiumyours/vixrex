import 'package:flutter/material.dart';
import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/models/legal_document.dart';
import 'package:vitrinx/screens/legal_screen.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/theme/app_text_styles.dart';

class PublishLegalApprovalSection extends StatelessWidget {
  final bool isLoadingLegalDocuments;
  final PublishingLegalDocuments? legalDocuments;
  final String? legalDocumentsError;
  final bool privacyNoticeAcknowledged;
  final bool termsAccepted;
  final bool publicationConsentAccepted;
  final bool isPublishing;
  final bool isLegalPublishReady;
  final bool hasPublished;
  final VoidCallback onLoadLegalDocuments;
  final ValueChanged<bool> onPrivacyNoticeChanged;
  final ValueChanged<bool> onTermsAcceptedChanged;
  final ValueChanged<bool> onPublicationConsentChanged;
  final void Function(LegalPageType type) onOpenLegalPage;
  final VoidCallback onPublish;

  const PublishLegalApprovalSection({
    super.key,
    required this.isLoadingLegalDocuments,
    required this.legalDocuments,
    required this.legalDocumentsError,
    required this.privacyNoticeAcknowledged,
    required this.termsAccepted,
    required this.publicationConsentAccepted,
    required this.isPublishing,
    required this.isLegalPublishReady,
    required this.hasPublished,
    required this.onLoadLegalDocuments,
    required this.onPrivacyNoticeChanged,
    required this.onTermsAcceptedChanged,
    required this.onPublicationConsentChanged,
    required this.onOpenLegalPage,
    required this.onPublish,
  });

  static const Color _primaryColor = AppColors.primary;
  static const Color _cardBorder = AppColors.cardBorderDark;
  static const Color _surface = AppColors.surface;
  static const Color _mutedText = AppColors.mutedText;

  @override
  Widget build(BuildContext context) {
    final canAccept =
        !isLoadingLegalDocuments &&
        legalDocuments != null &&
        LegalConfig.hasCompleteDataControllerIdentity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: _primaryColor, size: 21),
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
                    onPressed: onLoadLegalDocuments,
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
                    canAccept ? (value) => onPrivacyNoticeChanged(value ?? false) : null,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Aydınlatma Metni’ni okudum ve bilgilendirildim.',
                  style: AppTextStyles.formLabel,
                ),
              ),
              _LegalLinkButton(
                label: 'Aydınlatma Metni',
                onPressed: () => onOpenLegalPage(LegalPageType.privacy),
              ),
              CheckboxListTile(
                key: const ValueKey('terms-checkbox'),
                value: termsAccepted,
                onChanged:
                    canAccept ? (value) => onTermsAcceptedChanged(value ?? false) : null,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Kullanım Şartları’nı kabul ediyorum.',
                  style: AppTextStyles.formLabel,
                ),
              ),
              _LegalLinkButton(
                label: 'Kullanım Şartları',
                onPressed: () => onOpenLegalPage(LegalPageType.terms),
              ),
              CheckboxListTile(
                key: const ValueKey('publication-consent-checkbox'),
                value: publicationConsentAccepted,
                onChanged:
                    canAccept
                        ? (value) => onPublicationConsentChanged(value ?? false)
                        : null,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Verilerimin dijital vitrinimde kamuya açık yayınlanmasına açık rıza veriyorum.',
                  style: AppTextStyles.formLabel,
                ),
              ),
              _LegalLinkButton(
                label: 'Açık Rıza Beyanı',
                onPressed: () => onOpenLegalPage(LegalPageType.consent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isPublishing || !isLegalPublishReady ? null : onPublish,
            icon:
                isPublishing
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                    : Icon(
                      hasPublished
                          ? Icons.cloud_upload_rounded
                          : Icons.rocket_launch_rounded,
                      size: 19,
                    ),
            label: Text(
              isPublishing
                  ? 'Yayına alınıyor...'
                  : hasPublished
                  ? 'Değişiklikleri Kaydet & Yayına Al'
                  : 'Vitrinimi Yayına Al',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasPublished
              ? 'Mevcut linkin korunur, Keşfet görünümün güncellenir.'
              : 'Linkin oluşur, Keşfet\'te görünürsün.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LegalLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _LegalLinkButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.open_in_new_rounded, size: 15),
        label: Text(label),
      ),
    );
  }
}
