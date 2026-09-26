import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/services/invoice_catalog/invoice_draft_decision_engine.dart';

void main() {
  const engine = InvoiceDraftDecisionEngine();
  final now = DateTime.utc(2026, 9, 22);

  EvidenceValue<String> textEvidence(
    String value, {
    EvidenceStrength strength = EvidenceStrength.strong,
    EvidenceSourceType source = EvidenceSourceType.invoice,
  }) {
    return EvidenceValue<String>(
      value: value,
      sourceType: source,
      sourceReference: 'fixture',
      strength: strength,
      verifiedAt: now,
    );
  }

  group('InvoiceDraftDecisionEngine', () {
    test('guclu urunu hazirlar ama izin bilinmiyorsa yayinlamaz', () {
      final draft = InvoiceProductDraft(
        id: 'ter0101',
        rawSourceLine:
            'TER0101 TUT ERK PEN ATLET 8680508918131 18 AD 63,50 1143,00',
        supplierName: textEvidence('Seher Mensucat'),
        rawName: textEvidence('TUT ERK PEN ATLET'),
        normalizedName: textEvidence(
          'Tutku Erkek Penye Atlet',
          source: EvidenceSourceType.officialProductPage,
        ),
        gtinBarcode: textEvidence('8680508918131'),
        modelCode: textEvidence('TER0101'),
        supplierIdentityStrength: EvidenceStrength.strong,
        productIdentityStrength: EvidenceStrength.strong,
        rightsStatus: RightsStatus.unknown,
      );

      final result = engine.evaluate(draft);

      expect(result.decision, AutomationDecision.autoPrepareDraft);
      expect(result.canPrepareDraft, isTrue);
      expect(result.canPublish, isFalse);
      expect(result.externalMediaBlocked, isTrue);
      expect(
        result.questions.any((q) => q.contains('kullanma yetkiniz')),
        isTrue,
      );
    });

    test('zayif urun izinde tahmin etmez', () {
      final draft = InvoiceProductDraft(
        id: 'unknown-line',
        rawSourceLine: '2 x 180 = 360',
        supplierIdentityStrength: EvidenceStrength.strong,
        productIdentityStrength: EvidenceStrength.weak,
      );

      final result = engine.evaluate(draft);

      expect(result.decision, AutomationDecision.stopNoGuess);
      expect(result.canPrepareDraft, isFalse);
      expect(result.canPublish, isFalse);
    });

    test('kismi urun izinde eksik bilgiyi sorar', () {
      final draft = InvoiceProductDraft(
        id: 'jumbo-erkek',
        rawSourceLine: 'JUMBO ERKEK 5 AD 300,00 1500,00',
        rawName: textEvidence(
          'JUMBO ERKEK',
          strength: EvidenceStrength.partial,
        ),
        supplierIdentityStrength: EvidenceStrength.strong,
        productIdentityStrength: EvidenceStrength.partial,
      );

      final result = engine.evaluate(draft);

      expect(result.decision, AutomationDecision.askMissing);
      expect(result.canPrepareDraft, isFalse);
      expect(result.questions, isNotEmpty);
    });

    test('guclu iz + izin + esnaf onayi + satis fiyati yayina hazirdir', () {
      final draft = InvoiceProductDraft(
        id: 'ready',
        rawSourceLine: 'TER0101 ...',
        supplierName: textEvidence('Seher Mensucat'),
        normalizedName: textEvidence(
          'Tutku Erkek Penye Atlet',
          source: EvidenceSourceType.officialProductPage,
        ),
        supplierIdentityStrength: EvidenceStrength.strong,
        productIdentityStrength: EvidenceStrength.strong,
        rightsStatus: RightsStatus.verifiedSupplierPermission,
        merchantApproved: true,
        salePrice: 149.90,
      );

      final result = engine.evaluate(draft);

      expect(result.decision, AutomationDecision.readyForPublish);
      expect(result.canPrepareDraft, isTrue);
      expect(result.canPublish, isTrue);
      expect(result.externalMediaBlocked, isFalse);
    });
  });
}
