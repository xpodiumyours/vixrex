import 'package:flutter/material.dart';

class VitrinFormSection extends StatelessWidget {
  final bool hasPublished;
  final bool isPublishing;
  final bool isLegalPublishReady;
  final BoxDecoration cardDecoration;
  final VoidCallback onPublish;
  final Widget coverPicker;
  final Widget galleryRow;
  final Widget nameField;
  final Widget whatsappField;
  final Widget locationField;
  final Widget descriptionField;
  final Widget categoryField;
  final Widget themePicker;
  final Widget? bookingSettingsSection;
  final Widget statusField;
  final Widget instagramField;
  final Widget productManagementCard;
  final Widget? instagramSyncSection;
  final Widget publicWebsiteLinkCard;
  final Widget googleReviewField;
  final Widget marketplaceSection;
  final Widget legalConsentSection;

  const VitrinFormSection({
    super.key,
    required this.hasPublished,
    required this.isPublishing,
    required this.isLegalPublishReady,
    required this.cardDecoration,
    required this.onPublish,
    required this.coverPicker,
    required this.galleryRow,
    required this.nameField,
    required this.whatsappField,
    required this.locationField,
    required this.descriptionField,
    required this.categoryField,
    required this.themePicker,
    required this.bookingSettingsSection,
    required this.statusField,
    required this.instagramField,
    required this.productManagementCard,
    required this.instagramSyncSection,
    required this.publicWebsiteLinkCard,
    required this.googleReviewField,
    required this.marketplaceSection,
    required this.legalConsentSection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                hasPublished ? 'VitrinX Düzenle' : 'VitrinX Oluştur',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront_rounded, color: Colors.black, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'VitrinX ile',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hasPublished
              ? 'Düzenledikten sonra kaydet, linkin ve QR kodun güncellenir.'
              : 'Ad, WhatsApp ve konumunu gir — vitrin hazır. Diğer detayları sonra ekleyebilirsin.',
          style: const TextStyle(
            color: Color(0xFFA1A1AA),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              coverPicker,
              const SizedBox(height: 10),
              galleryRow,
              const SizedBox(height: 18),
              nameField,
              const SizedBox(height: 14),
              whatsappField,
              const SizedBox(height: 14),
              locationField,
              const SizedBox(height: 14),
              descriptionField,
              const SizedBox(height: 14),
              categoryField,
              const SizedBox(height: 14),
              themePicker,
              const SizedBox(height: 14),
              if (bookingSettingsSection != null) ...[
                bookingSettingsSection!,
                const SizedBox(height: 14),
              ],
              statusField,
              const SizedBox(height: 14),
              instagramField,
              productManagementCard,
              const SizedBox(height: 14),
              if (instagramSyncSection != null) ...[
                instagramSyncSection!,
                const SizedBox(height: 14),
              ],
              publicWebsiteLinkCard,
              const SizedBox(height: 14),
              googleReviewField,
              const SizedBox(height: 14),
              marketplaceSection,
              const SizedBox(height: 24),
              legalConsentSection,
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      isPublishing || !isLegalPublishReady ? null : onPublish,
                  icon: isPublishing
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
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
                  color: Color(0xFFA1A1AA),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
