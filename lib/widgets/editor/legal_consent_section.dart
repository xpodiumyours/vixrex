import 'package:flutter/material.dart';
import 'package:vixrex/screens/legal_screen.dart';
import 'package:vixrex/theme/app_colors.dart';
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

  void _privacyChanged(bool? value) {
    onPrivacyChanged(value ?? false);
  }

  void _termsChanged(bool? value) {
    onTermsChanged(value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final isAllAccepted =
        privacyNoticeAcknowledged && termsAccepted;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isAllAccepted
                    ? const Color(0xFF0EA5E9).withAlpha(160)
                    : AppColors.border,
            width: isAllAccepted ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
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
              'Aydınlatma bildirimi ve kullanım şartları yayınlama için gereklidir. Genel açık rıza istenmez.',
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
            const SizedBox(height: 14),
            CheckboxListTile(
              key: const ValueKey('privacy-notice-checkbox'),
              value: privacyNoticeAcknowledged,
              onChanged: canAccept ? _privacyChanged : null,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF0EA5E9),
              title: TextButton(
                onPressed: () => onOpenLegalPage(LegalPageType.privacy),
                child: const Text('Aydınlatma Metni'),
              ),
              subtitle: const Text('Okudum ve bilgilendirildim.'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const ValueKey('terms-acceptance-checkbox'),
              value: termsAccepted,
              onChanged: canAccept ? _termsChanged : null,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF0EA5E9),
              title: TextButton(
                onPressed: () => onOpenLegalPage(LegalPageType.terms),
                child: const Text('Kullanım Şartları'),
              ),
              subtitle: const Text('Kabul ediyorum.'),
            ),
          ],
        ),
      ),
    );
  }
}
