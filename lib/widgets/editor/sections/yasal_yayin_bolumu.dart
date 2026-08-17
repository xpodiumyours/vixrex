import 'package:flutter/material.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/legal_consent_section.dart';
import 'package:vixrex/widgets/google_business_guide_card.dart';

/// Yasal-yayın bölümü — sabit blok, akordeona girmez.
///
/// Faz 0 kalanı (Tek Asistan planı): altı bölüm dosyasından altıncısı.
/// Diğer beşi [FormAccordionSection] içinde açılıp kapanırken bu blok
/// orijinalde de her zaman açık ve formun en altında sabitti — bu davranış
/// burada da korunuyor (vitrin_form_section.dart yalnız bu widget'ı çağırır,
/// bir akordeona sarmaz).
class YasalYayinBolumu extends StatelessWidget {
  const YasalYayinBolumu({
    super.key,
    required this.controller,
    required this.state,
    required this.hasPublished,
    this.onPublished,
  });

  final StoreEditorController controller;
  final MyVitrinState state;
  final bool hasPublished;
  final VoidCallback? onPublished;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: state.legalKey,
          child: LegalConsentSection(
            canAccept: !controller.isLoadingLegalDocuments,
            isLoading: controller.isLoadingLegalDocuments,
            errorText: controller.legalDocumentsError,
            privacyNoticeAcknowledged: controller.privacyNoticeAcknowledged,
            termsAccepted: controller.termsAccepted,
            publicationConsentAccepted: controller.publicationConsentAccepted,
            onPrivacyChanged: controller.setPrivacyNoticeAcknowledged,
            onTermsChanged: controller.setTermsAccepted,
            onPublicationChanged: controller.setPublicationConsentAccepted,
            onReloadDocuments: controller.reloadLegalDocuments,
            onOpenLegalPage: (type) => AppRouter.navigateToLegal(context, type),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed:
                controller.isPublishing || !controller.isLegalPublishReady
                    ? null
                    : () => state.handlePublish(context, onPublished),
            icon:
                controller.isPublishing
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                    : Icon(
                      hasPublished
                          ? Icons.cloud_upload_rounded
                          : Icons.rocket_launch_rounded,
                      size: 19,
                    ),
            label: Text(
              controller.isPublishing
                  ? 'Yayına alınıyor...'
                  : hasPublished
                  ? 'Değişiklikleri Kaydet & Yayına Al'
                  : 'Vitrinimi Yayına Al',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radius16),
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
            color: AppColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hasPublished) ...[
          const SizedBox(height: 16),
          GoogleBusinessGuideCard(
            publishedLink: controller.publishedInfo?.publicLink ?? '',
          ),
        ],
      ],
    );
  }
}
