import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';

/// X-rex ekranı ve sohbeti tarafından ortak kullanılan tek öneri modeli.
class XrexRecommendation {
  final String id;
  final XrexJourneyPhase phase;
  final String title;
  final String description;
  final String buttonLabel;
  final XrexAction action;

  const XrexRecommendation({
    required this.id,
    required this.phase,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.action,
  });
}

/// Vitrin durumundan tek ve öncelikli X-rex önerisi üretir.
/// Depolama veya UI bağımlılığı yoktur.
abstract final class XrexGuidanceService {
  static XrexRecommendation recommendationFor({
    required XrexProfileSnapshot? snapshot,
    required bool hasShared,
  }) {
    if (snapshot == null) {
      return const XrexRecommendation(
        id: 'setup_start',
        phase: XrexJourneyPhase.setup,
        title: 'Vitrinini oluşturmaya başla',
        description:
            'İşletme bilgilerini ekleyerek dijital vitrininin ilk adımını tamamla.',
        buttonLabel: 'Başla',
        action: XrexAction.openVitrim,
      );
    }

    final phase = snapshot.journeyPhase(hasShared: hasShared);
    return switch (phase) {
      XrexJourneyPhase.setup => _setupRecommendation(snapshot.nextMissingField),
      XrexJourneyPhase.publish => const XrexRecommendation(
          id: 'publish_vitrin',
          phase: XrexJourneyPhase.publish,
          title: 'Vitrinin yayına hazır',
          description:
              'Zorunlu bilgiler tamamlandı. Vitrinini kontrol edip yayınlayabilirsin.',
          buttonLabel: 'Yayınlamaya git',
          action: XrexAction.openVitrim,
        ),
      XrexJourneyPhase.share => const XrexRecommendation(
          id: 'share_vitrin',
          phase: XrexJourneyPhase.share,
          title: 'Vitrinini müşterilerine duyur',
          description:
              'Yayındaki vitrininin bağlantısını WhatsApp üzerinden paylaş.',
          buttonLabel: 'WhatsApp’ta paylaş',
          action: XrexAction.shareWhatsapp,
        ),
      XrexJourneyPhase.improve => const XrexRecommendation(
          id: 'improve_vitrin',
          phase: XrexJourneyPhase.improve,
          title: 'Vitrinini güncel tut',
          description:
              'Görsellerini, açıklamanı ve ürünlerini düzenli olarak geliştirebilirsin.',
          buttonLabel: 'Vitrinime git',
          action: XrexAction.openVitrim,
        ),
    };
  }

  static XrexRecommendation _setupRecommendation(XrexNextStep step) {
    return switch (step) {
      XrexNextStep.name => const XrexRecommendation(
          id: 'setup_name',
          phase: XrexJourneyPhase.setup,
          title: 'İşletme adını ekle',
          description: 'Müşterilerinin seni tanıması için işletme adını tamamla.',
          buttonLabel: 'Beni götür',
          action: XrexAction.scrollToName,
        ),
      XrexNextStep.whatsapp => const XrexRecommendation(
          id: 'setup_whatsapp',
          phase: XrexJourneyPhase.setup,
          title: 'WhatsApp numaranı ekle',
          description: 'Müşterilerinin sana doğrudan ulaşabilmesini sağla.',
          buttonLabel: 'Beni götür',
          action: XrexAction.scrollToWhatsapp,
        ),
      XrexNextStep.address => const XrexRecommendation(
          id: 'setup_address',
          phase: XrexJourneyPhase.setup,
          title: 'Adresini ve konumunu tamamla',
          description: 'Müşterilerinin işletmeni kolayca bulmasına yardımcı ol.',
          buttonLabel: 'Beni götür',
          action: XrexAction.scrollToAddress,
        ),
      XrexNextStep.legal => const XrexRecommendation(
          id: 'setup_legal',
          phase: XrexJourneyPhase.setup,
          title: 'Yayınlama onaylarını tamamla',
          description: 'Vitrinini güvenli şekilde yayınlamak için onayları incele.',
          buttonLabel: 'Beni götür',
          action: XrexAction.scrollToLegal,
        ),
      XrexNextStep.publish => const XrexRecommendation(
          id: 'publish_vitrin',
          phase: XrexJourneyPhase.publish,
          title: 'Vitrinin yayına hazır',
          description: 'Bilgilerini kontrol edip vitrinini yayınlayabilirsin.',
          buttonLabel: 'Yayınlamaya git',
          action: XrexAction.openVitrim,
        ),
      XrexNextStep.share => const XrexRecommendation(
          id: 'share_vitrin',
          phase: XrexJourneyPhase.share,
          title: 'Vitrinini müşterilerine duyur',
          description: 'Yayındaki vitrininin bağlantısını paylaş.',
          buttonLabel: 'Paylaş',
          action: XrexAction.shareWhatsapp,
        ),
    };
  }
}
