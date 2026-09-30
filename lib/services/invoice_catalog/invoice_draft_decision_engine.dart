import 'package:vixrex/models/invoice_product_draft.dart';

class InvoiceDraftDecisionResult {
  /// Kartın ekranda görünen hâli: kanıtlı / eksik / çelişki / iz bulunamadı.
  final KartDurumu kartDurumu;
  final AutomationDecision decision;
  final bool canPrepareDraft;
  final bool canPublish;
  final bool externalMediaBlocked;
  final List<String> questions;
  final List<String> warnings;

  const InvoiceDraftDecisionResult({
    required this.kartDurumu,
    required this.decision,
    required this.canPrepareDraft,
    required this.canPublish,
    required this.externalMediaBlocked,
    this.questions = const [],
    this.warnings = const [],
  });
}

/// Kilitli kural:
/// güçlü iz -> taslak hazırla
/// kısmi iz -> yalnız eksik kritik bilgiyi sor
/// zayıf ürün izi -> tahmin etme
///
/// Ek kilitli kurallar (web tarafıyla aynı):
/// çelişki -> eşleşme kurma, esnafa seçtir
/// faturadaki adet -> stok önerisi, esnaf onaylamadan stok değil
class InvoiceDraftDecisionEngine {
  const InvoiceDraftDecisionEngine();

  InvoiceDraftDecisionResult evaluate(InvoiceProductDraft draft) {
    final kartDurumu = draft.etkinKartDurumu;

    if (kartDurumu == KartDurumu.celiski) {
      final adaylar = draft.celiskiAdaylari
          .map((aday) => aday.ad.trim())
          .where((ad) => ad.isNotEmpty)
          .toList(growable: false);
      final dayanak = draft.celiskiDayanak == 'barkod' ? 'barkod' : 'ürün kodu';
      return InvoiceDraftDecisionResult(
        kartDurumu: kartDurumu,
        decision: AutomationDecision.askMissing,
        canPrepareDraft: false,
        canPublish: false,
        externalMediaBlocked: true,
        questions: [
          adaylar.isEmpty
              ? 'Aynı $dayanak birden çok ürüne düşüyor; hangi ürün olduğunu sen seçmelisin.'
              : 'Aynı $dayanak ${adaylar.length} farklı ürüne düşüyor '
                  '(${adaylar.take(3).join(', ')}). Hangisi olduğunu sen seçmelisin.',
        ],
        warnings: ['Eşleşme kurulmadı; Vixrex bu satırda tahmin yapmaz.'],
      );
    }

    if (kartDurumu == KartDurumu.izYok) {
      return const InvoiceDraftDecisionResult(
        kartDurumu: KartDurumu.izYok,
        decision: AutomationDecision.stopNoGuess,
        canPrepareDraft: false,
        canPublish: false,
        externalMediaBlocked: true,
        questions: [
          'Ürünü doğrulayacak barkod, model/stok kodu veya tedarikçi katalog bilgisi gerekli.',
        ],
        warnings: [
          'Ürün kimliği zayıf olduğu için Vixrex ürün adı veya görsel tahmin etmez.',
        ],
      );
    }

    if (kartDurumu == KartDurumu.eksik) {
      final questions = <String>[];

      if (draft.productIdentityStrength == EvidenceStrength.partial) {
        questions.add(
          'Bu ürünün barkodu, model/stok kodu veya tedarikçi kataloğundaki karşılığı nedir?',
        );
      }
      if (draft.productIdentityStrength == EvidenceStrength.weak ||
          draft.supplierIdentityStrength != EvidenceStrength.strong) {
        questions.add(
          'Faturayı kesen tedarikçiyi doğrulayacak şirket veya resmî kaynak bilgisi gerekli.',
        );
      }

      return InvoiceDraftDecisionResult(
        kartDurumu: kartDurumu,
        decision: AutomationDecision.askMissing,
        canPrepareDraft: false,
        canPublish: false,
        externalMediaBlocked: true,
        questions: questions,
      );
    }

    // Buraya yalnız güçlü tedarikçi + güçlü ürün izi gelir.
    final questions = <String>[];
    final warnings = <String>[];

    var externalMediaBlocked = false;

    for (final image in draft.selectedExternalImages) {
      if (!image.canUse) {
        externalMediaBlocked = true;
        if (image.rightsStatus == RightsStatus.denied) {
          warnings.add(
            'Seçili harici görsel için kullanım izni yok; bu görsel kullanılmayacak.',
          );
        } else {
          questions.add(
            'Seçili üretici/tedarikçi görselini kullanma yetkisi doğrulanmalı.',
          );
        }
      }
    }

    final dataRightsMissing =
        draft.rightsStatus == RightsStatus.unknown ||
        draft.rightsStatus == RightsStatus.denied;

    if (dataRightsMissing) {
      externalMediaBlocked = true;
      if (draft.rightsStatus == RightsStatus.denied) {
        warnings.add(
          'Üretici/tedarikçi dijital verisi için kullanım izni yok; yalnız izinli veya esnafın kendi verisi kullanılabilir.',
        );
      } else {
        questions.add(
          'Bu üreticinin ürün verilerini ve görsellerini vitrinde kullanma yetkiniz var mı?',
        );
      }
    }

    if (!draft.hasPositiveSalePrice) {
      questions.add('Satış fiyatı esnaf tarafından belirlenmeli.');
    }

    // Faturadaki adet ALIŞ adedidir, raf stoğu değildir. Esnaf onaylamadan
    // stok sayılmaz; kartta da yalnız öneri olarak görünür.
    final stokOnayli = draft.stockConfirmed;
    if (!stokOnayli) {
      questions.add(
        'Faturadaki adet öneridir; satış stoğunu kontrol edip onayla.',
      );
    }

    if (!draft.merchantApproved) {
      questions.add('Taslak ürün kartı esnaf tarafından onaylanmalı.');
    }

    final canPublish =
        draft.merchantApproved &&
        draft.hasPositiveSalePrice &&
        stokOnayli &&
        !externalMediaBlocked;

    return InvoiceDraftDecisionResult(
      kartDurumu: kartDurumu,
      decision:
          canPublish
              ? AutomationDecision.readyForPublish
              : AutomationDecision.autoPrepareDraft,
      canPrepareDraft: true,
      canPublish: canPublish,
      externalMediaBlocked: externalMediaBlocked,
      questions: questions,
      warnings: warnings,
    );
  }
}
