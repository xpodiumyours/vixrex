import 'package:flutter/gestures.dart';
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

  @override
  Widget build(BuildContext context) {
    final isAllAccepted = privacyNoticeAcknowledged &&
        termsAccepted &&
        publicationConsentAccepted;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isAllAccepted
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
            const SizedBox(height: 14),
            // Master Consent Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    key: const ValueKey('privacy-notice-checkbox'),
                    value: isAllAccepted,
                    activeColor: const Color(0xFF0EA5E9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: canAccept
                        ? (value) {
                            final newValue = value ?? false;
                            onPrivacyChanged(newValue);
                            onTermsChanged(newValue);
                            onPublicationChanged(newValue);
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Aydınlatma Metni',
                          style: const TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => onOpenLegalPage(LegalPageType.privacy),
                        ),
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: 'Kullanım Şartları',
                          style: const TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => onOpenLegalPage(LegalPageType.terms),
                        ),
                        const TextSpan(text: ' ve '),
                        TextSpan(
                          text: 'Açık Rıza Beyanı',
                          style: const TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => onOpenLegalPage(LegalPageType.consent),
                        ),
                        const TextSpan(
                          text: '\'nı okudum, anladım ve kabul ediyorum.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

