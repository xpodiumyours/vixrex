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

class XrexQualityItem {
  final String id;
  final String label;
  final int points;
  final bool completed;
  final XrexAction action;

  const XrexQualityItem({
    required this.id,
    required this.label,
    required this.points,
    required this.completed,
    required this.action,
  });
}

class XrexQualityReport {
  final int score;
  final List<XrexQualityItem> items;

  const XrexQualityReport({required this.score, required this.items});

  XrexQualityItem? get nextImprovement {
    for (final item in items) {
      if (!item.completed) return item;
    }
    return null;
  }
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
      XrexJourneyPhase.improve => _improvementRecommendation(
        qualityReportFor(snapshot: snapshot, hasShared: hasShared),
      ),
    };
  }

  static XrexQualityReport qualityReportFor({
    required XrexProfileSnapshot? snapshot,
    required bool hasShared,
  }) {
    final items = <XrexQualityItem>[
      XrexQualityItem(
        id: 'name',
        label: 'İşletme adı',
        points: 10,
        completed: snapshot?.nameCompleted ?? false,
        action: XrexAction.scrollToName,
      ),
      XrexQualityItem(
        id: 'whatsapp',
        label: 'WhatsApp numarası',
        points: 10,
        completed: snapshot?.whatsappCompleted ?? false,
        action: XrexAction.scrollToWhatsapp,
      ),
      XrexQualityItem(
        id: 'address',
        label: 'Adres ve konum',
        points: 10,
        completed: snapshot?.addressCompleted ?? false,
        action: XrexAction.scrollToAddress,
      ),
      XrexQualityItem(
        id: 'legal',
        label: 'Yayınlama onayları',
        points: 10,
        completed: snapshot?.legalCompleted ?? false,
        action: XrexAction.scrollToLegal,
      ),
      XrexQualityItem(
        id: 'cover',
        label: 'Kapak görseli',
        points: 15,
        completed: snapshot?.coverCompleted ?? false,
        action: XrexAction.scrollToCover,
      ),
      XrexQualityItem(
        id: 'description',
        label: 'İşletme açıklaması',
        points: 10,
        completed: snapshot?.descriptionCompleted ?? false,
        action: XrexAction.scrollToDesc,
      ),
      XrexQualityItem(
        id: 'gallery',
        label: 'Vitrin galerisi',
        points: 10,
        completed: snapshot?.galleryCompleted ?? false,
        action: XrexAction.scrollToGallery,
      ),
      XrexQualityItem(
        id: 'catalog',
        label: 'Ürün veya hizmetler',
        points: 10,
        completed: snapshot?.catalogCompleted ?? false,
        action: XrexAction.scrollToProducts,
      ),
      XrexQualityItem(
        id: 'published',
        label: 'Vitrini yayınlama',
        points: 10,
        completed: snapshot?.isPublished ?? false,
        action: XrexAction.openVitrim,
      ),
      XrexQualityItem(
        id: 'shared',
        label: 'Vitrini duyurma',
        points: 5,
        completed: (snapshot?.isPublished ?? false) && hasShared,
        action: XrexAction.shareWhatsapp,
      ),
    ];
    final score = items
        .where((item) => item.completed)
        .fold<int>(0, (total, item) => total + item.points);
    return XrexQualityReport(score: score, items: items);
  }

  static String _buttonLabelForId(String id) {
    switch (id) {
      case 'name':
        return 'İşletme Adı Ekle';
      case 'whatsapp':
        return 'WhatsApp Ekle';
      case 'address':
        return 'Adres Ekle';
      case 'legal':
        return 'Onayları İncele';
      case 'cover':
        return 'Kapak Görseli Ekle';
      case 'description':
        return 'Açıklama Ekle';
      case 'products':
        return 'Ürün Ekle';
      case 'gallery':
        return 'Fotoğraf Ekle';
      default:
        return 'Beni götür';
    }
  }

  static XrexRecommendation _improvementRecommendation(
    XrexQualityReport report,
  ) {
    final next = report.nextImprovement;
    if (next == null) {
      return const XrexRecommendation(
        id: 'improve_complete',
        phase: XrexJourneyPhase.improve,
        title: 'Vitrinin güçlü görünüyor',
        description: 'Kalite kontrolündeki tüm adımlar tamamlandı.',
        buttonLabel: 'Vitrinime git',
        action: XrexAction.openVitrim,
      );
    }
    return XrexRecommendation(
      id: 'improve_${next.id}',
      phase: XrexJourneyPhase.improve,
      title: '${next.label} adımını geliştir',
      description:
          'Vitrin puanın ${report.score}/100. En önemli eksik: ${next.label}.',
      buttonLabel: _buttonLabelForId(next.id),
      action: next.action,
    );
  }

  static XrexRecommendation _setupRecommendation(XrexNextStep step) {
    return switch (step) {
      XrexNextStep.name => const XrexRecommendation(
        id: 'setup_name',
        phase: XrexJourneyPhase.setup,
        title: 'İşletme adını ekle',
        description: 'Müşterilerinin seni tanıması için işletme adını tamamla.',
        buttonLabel: 'İşletme Adı Ekle',
        action: XrexAction.scrollToName,
      ),
      XrexNextStep.whatsapp => const XrexRecommendation(
        id: 'setup_whatsapp',
        phase: XrexJourneyPhase.setup,
        title: 'WhatsApp numaranı ekle',
        description: 'Müşterilerinin sana doğrudan ulaşabilmesini sağla.',
        buttonLabel: 'WhatsApp Ekle',
        action: XrexAction.scrollToWhatsapp,
      ),
      XrexNextStep.address => const XrexRecommendation(
        id: 'setup_address',
        phase: XrexJourneyPhase.setup,
        title: 'Adresini ve konumunu tamamla',
        description: 'Müşterilerinin işletmeni kolayca bulmasına yardımcı ol.',
        buttonLabel: 'Adres Ekle',
        action: XrexAction.scrollToAddress,
      ),
      XrexNextStep.legal => const XrexRecommendation(
        id: 'setup_legal',
        phase: XrexJourneyPhase.setup,
        title: 'Yayınlama onaylarını tamamla',
        description:
            'Vitrinini güvenli şekilde yayınlamak için onayları incele.',
        buttonLabel: 'Onayları İncele',
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
