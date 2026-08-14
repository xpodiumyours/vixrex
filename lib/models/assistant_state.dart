import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// VixRex'in "sırada ne var" kararının tek biçimi.
///
/// Faz E (Tek Asistan planı): bugün aynı soruyu üç ayrı tip yanıtlıyor —
/// `VixRexProfileSnapshot` (doluluk), `VixRexRecommendation` (öneri),
/// `VixRexQualityReport` (kalite puanı). Bu tip onları BİRLEŞTİRMEZ; bu
/// fazın kuralı "karar değişmez, kararın biçimi tekilleşir" — asıl birleşme
/// Faz F'de. `AssistantState.fromSnapshot` yalnız mevcut ikisinin
/// (`snapshot` + `VixRexGuidanceService.recommendationFor`) sonucunu tek bir
/// nesneye kopyalar; kendi kararını üretmez.
///
/// [mesajAnahtari] not: Faz B'nin `shared/vixrex_mesajlar.json` kataloğu şu
/// an yalnız sohbet-niyeti yanıtlarını taşıyor (bkz. `chatbot_config.dart`),
/// rehberlik önerilerinin başlık/açıklamasını değil. Bu alan bugün
/// `VixRexRecommendation.id` değerini taşır — zaten kararlı, benzersiz bir
/// anahtar. Bu id'leri Next.js'in de okuyabileceği JSON'a taşımak (metnin
/// TEK yerde yaşaması) Faz G3'ün işi; burada yapılmadı, kapsam dışı
/// bırakıldı.
class AssistantState {
  const AssistantState({
    required this.asama,
    required this.sonrakiEksikAlan,
    required this.sonrakiAdim,
    required this.mesajAnahtari,
    required this.eylemler,
    required this.doluluk,
    required this.doluAlan,
    required this.toplamAlan,
  });

  /// VixRex'in şu anki rehberlik aşaması (kurulum / yayın / paylaşım /
  /// geliştirme).
  final VixRexJourneyPhase asama;

  /// Sıradaki eksik ZORUNLU alan — şemadan, sırası da şemadan. `null` ise
  /// zorunlu alan eksiği yok (yasal onay veya yayın aşamasında olabilir).
  final VitrinAlani? sonrakiEksikAlan;

  /// Akış aşaması dâhil sıradaki adım (`legal`/`publish`/`share` alan
  /// değildir, zorunlu-alan kümesinin ötesindeki akış duraklarıdır).
  final VixRexNextStep sonrakiAdim;

  /// Öneri metninin anahtarı — bkz. sınıf başı not.
  final String mesajAnahtari;

  /// Sıralı eylem listesi, ilki birincil. Bugünkü `VixRexRecommendation`
  /// tek eylem taşıdığı için bu liste her zaman tek elemanlı; çoklu eylem
  /// desteği eklendiğinde imza değişmeden genişler.
  final List<AssistantAction> eylemler;

  /// 0-100 arası doluluk yüzdesi — zorunlu alan + yasal onay kümesi
  /// üzerinden.
  final int doluluk;

  /// Tamamlanan zorunlu adım sayısı.
  final int doluAlan;

  /// Toplam zorunlu adım sayısı.
  final int toplamAlan;

  /// Mevcut `VixRexProfileSnapshot` + `VixRexGuidanceService` çıktısını tek
  /// nesneye kopyalar. `snapshot` null olabilir (henüz hiç veri yok) —
  /// `VixRexGuidanceService.recommendationFor` zaten bu durumu biliyor,
  /// burada tekrar dallanmaz.
  factory AssistantState.fromSnapshot(
    VixRexProfileSnapshot? snapshot, {
    required bool hasShared,
  }) {
    final rec = VixRexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: hasShared,
    );
    final toplamAlan =
        snapshot?.totalRequiredStepCount ?? (zorunluAlanlar.length + 1);
    final doluAlan = snapshot?.completedRequiredStepCount ?? 0;

    return AssistantState(
      asama:
          snapshot?.journeyPhase(hasShared: hasShared) ??
          VixRexJourneyPhase.setup,
      sonrakiEksikAlan: snapshot?.sonrakiEksikZorunluAlan,
      sonrakiAdim: snapshot?.nextMissingField ?? VixRexNextStep.name,
      mesajAnahtari: rec.id,
      eylemler: [
        AssistantAction(
          action: rec.action,
          label: rec.buttonLabel,
          primary: true,
        ),
      ],
      doluluk:
          toplamAlan == 0
              ? 0
              : ((doluAlan / toplamAlan) * 100).round().clamp(0, 100),
      doluAlan: doluAlan,
      toplamAlan: toplamAlan,
    );
  }
}

/// [AssistantState.eylemler] öğesi — `VixRexAction`'ı ekranın çizeceği
/// etiketle birlikte taşır.
class AssistantAction {
  const AssistantAction({
    required this.action,
    required this.label,
    this.primary = false,
  });

  final VixRexAction action;
  final String label;
  final bool primary;
}
