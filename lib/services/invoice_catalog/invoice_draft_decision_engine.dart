import 'package:vixrex/models/invoice_product_draft.dart';

class InvoiceDraftDecisionResult {
  final AutomationDecision decision;
  final bool canPrepareDraft;
  final bool canPublish;
  final bool externalMediaBlocked;
  final List<String> questions;
  final List<String> warnings;

  const InvoiceDraftDecisionResult({
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
class InvoiceDraftDecisionEngine {
  const InvoiceDraftDecisionEngine();

  InvoiceDraftDecisionResult evaluate(InvoiceProductDraft draft) {
    if (draft.productIdentityStrength == EvidenceStrength.weak) {
      return const InvoiceDraftDecisionResult(
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

    if (draft.supplierIdentityStrength == EvidenceStrength.weak) {
      return const InvoiceDraftDecisionResult(
        decision: AutomationDecision.askMissing,
        canPrepareDraft: false,
        canPublish: false,
        externalMediaBlocked: true,
        questions: [
          'Faturayı kesen tedarikçiyi doğrulayacak şirket veya resmî kaynak bilgisi gerekli.',
        ],
      );
    }

    if (draft.productIdentityStrength == EvidenceStrength.partial ||
        draft.supplierIdentityStrength == EvidenceStrength.partial) {
      final questions = <String>[];

      if (draft.productIdentityStrength == EvidenceStrength.partial) {
        questions.add(
          'Bu ürünün barkodu, model/stok kodu veya tedarikçi kataloğundaki karşılığı nedir?',
        );
      }
      if (draft.supplierIdentityStrength == EvidenceStrength.partial) {
        questions.add(
          'Bu tedarikçinin resmî adı veya ürün kataloğu/feed bağlantısı doğrulanmalı.',
        );
      }

      return InvoiceDraftDecisionResult(
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

    if (!draft.merchantApproved) {
      questions.add('Taslak ürün kartı esnaf tarafından onaylanmalı.');
    }

    final canPublish =
        draft.merchantApproved &&
        draft.hasPositiveSalePrice &&
        !externalMediaBlocked;

    return InvoiceDraftDecisionResult(
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
