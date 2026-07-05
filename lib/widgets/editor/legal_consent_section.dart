import 'package:flutter/material.dart';
import 'package:vixrex/screens/legal_screen.dart';
import 'package:vixrex/theme/app_text_styles.dart';

class LegalConsentSection extends StatelessWidget {
  final bool canAccept;
  final bool isLoading;
  final String? errorText;
  final bool privacyNoticeAcknowledged;
  final bool termsAccepted;
  final bool publicationConsentAccepted;
  final ValueChanged<bool> onPrivacyChanged;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPublicationChanged;
  final VoidCallback onReloadDocuments;
  final ValueChanged<LegalPageType> onOpenLegalPage;

  const LegalConsentSection({
    super.key,
    required this.canAccept,
    required this.isLoading,
    required this.errorText,
    required this.privacyNoticeAcknowledged,
    required this.termsAccepted,
    required this.publicationConsentAccepted,
    required this.onPrivacyChanged,
    required this.onTermsChanged,
    required this.onPublicationChanged,
    required this.onReloadDocuments,
    required this.onOpenLegalPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13151A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2B313E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Color(0xFF00F0FF), size: 21),
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
          if (isLoading) ...[
            const SizedBox(height: 14),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ] else if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(errorText!, style: AppTextStyles.errorText),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onReloadDocuments,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Belgeleri Tekrar Yükle'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          CheckboxListTile(
            key: const ValueKey('privacy-notice-checkbox'),
            value: privacyNoticeAcknowledged,
            onChanged: canAccept ? (value) => onPrivacyChanged(value ?? false) : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Aydınlatma Metni’ni okudum ve bilgilendirildim.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(
            label: 'Aydınlatma Metni',
            type: LegalPageType.privacy,
          ),
          CheckboxListTile(
            key: const ValueKey('terms-checkbox'),
            value: termsAccepted,
            onChanged: canAccept ? (value) => onTermsChanged(value ?? false) : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Kullanım Şartları’nı kabul ediyorum.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(
            label: 'Kullanım Şartları',
            type: LegalPageType.terms,
          ),
          CheckboxListTile(
            key: const ValueKey('publication-consent-checkbox'),
            value: publicationConsentAccepted,
            onChanged: canAccept ? (value) => onPublicationChanged(value ?? false) : null,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Verilerimin dijital vitrinimde kamuya açık yayınlanmasına açık rıza veriyorum.',
              style: AppTextStyles.formLabel,
            ),
          ),
          _legalLink(
            label: 'Açık Rıza Beyanı',
            type: LegalPageType.consent,
          ),
        ],
      ),
    );
  }

  Widget _legalLink({required String label, required LegalPageType type}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => onOpenLegalPage(type),
        icon: const Icon(Icons.open_in_new_rounded, size: 15),
        label: Text(label),
      ),
    );
  }
}
