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

    test(
      'guclu iz + izin + esnaf onayi + satis fiyati + stok onayi yayina hazirdir',
      () {
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
          stockConfirmed: true,
          merchantApproved: true,
          salePrice: 149.90,
        );

        final result = engine.evaluate(draft);

        expect(result.kartDurumu, KartDurumu.kanitli);
        expect(result.decision, AutomationDecision.readyForPublish);
        expect(result.canPrepareDraft, isTrue);
        expect(result.canPublish, isTrue);
        expect(result.externalMediaBlocked, isFalse);
      },
    );

    test(
      'faturadaki adet tek basina stok yerine gecmez: stok onayi yoksa yayin yok',
      () {
        final draft = InvoiceProductDraft(
          id: 'stok-onaysiz',
          rawSourceLine: 'TER0101 ... 18 AD 63,50 1143,00',
          supplierName: textEvidence('Seher Mensucat'),
          normalizedName: textEvidence('Tutku Erkek Penye Atlet'),
          quantity: EvidenceValue<num>(
            value: 18,
            sourceType: EvidenceSourceType.invoice,
            sourceReference: 'TER0101',
            strength: EvidenceStrength.partial,
            verifiedAt: now,
          ),
          supplierIdentityStrength: EvidenceStrength.strong,
          productIdentityStrength: EvidenceStrength.strong,
          rightsStatus: RightsStatus.verifiedSupplierPermission,
          merchantApproved: true,
          salePrice: 149.90,
        );

        final result = engine.evaluate(draft);

        expect(result.kartDurumu, KartDurumu.kanitli);
        expect(result.canPrepareDraft, isTrue);
        expect(result.canPublish, isFalse);
        expect(
          result.questions.any((q) => q.contains('öneri')),
          isTrue,
          reason: 'Faturadaki adedin oneri oldugu ve onaylanmasi soylenmeli',
        );
        expect(draft.canUseQuantityAsStock, isFalse);
        expect(
          draft.copyWith(stockConfirmed: true).canUseQuantityAsStock,
          isTrue,
        );
      },
    );

    test('ayni kod iki urune duserse eslesme kurulmaz, celiski gosterilir', () {
      final draft = InvoiceProductDraft(
        id: 'celiski',
        rawSourceLine: 'TER0117 ...',
        normalizedName: textEvidence('Tutku Erkek Penye Atlet'),
        supplierIdentityStrength: EvidenceStrength.strong,
        productIdentityStrength: EvidenceStrength.strong,
        rightsStatus: RightsStatus.verifiedSupplierPermission,
        kartDurumu: KartDurumu.celiski,
        celiskiDayanak: 'barkod',
        celiskiAdaylari: const [
          InvoiceConflictCandidate(
            ad: 'Tutku Erkek Atlet Siyah L',
            kaynak: 'https://sehermensucat.com/a',
          ),
          InvoiceConflictCandidate(
            ad: 'Tutku Erkek Atlet Siyah XL',
            kaynak: 'https://sehermensucat.com/b',
          ),
        ],
        merchantApproved: true,
        salePrice: 149.90,
        stockConfirmed: true,
      );

      final result = engine.evaluate(draft);

      expect(result.kartDurumu, KartDurumu.celiski);
      expect(result.decision, AutomationDecision.askMissing);
      expect(result.canPrepareDraft, isFalse);
      expect(result.canPublish, isFalse);
      expect(result.questions.single, contains('barkod'));
    });

    test('sunucu hicbir durum vermezse durum kanit gucunden turetilir', () {
      InvoiceProductDraft taslak({required String id}) => InvoiceProductDraft(
        id: id,
        rawSourceLine: 'satir',
        supplierIdentityStrength: EvidenceStrength.strong,
        productIdentityStrength: EvidenceStrength.strong,
      );

      expect(taslak(id: 'a').etkinKartDurumu, KartDurumu.kanitli);
      expect(
        taslak(id: 'b')
            .copyWith(productIdentityStrength: EvidenceStrength.partial)
            .etkinKartDurumu,
        KartDurumu.eksik,
      );
      expect(
        taslak(id: 'c')
            .copyWith(productIdentityStrength: EvidenceStrength.weak)
            .etkinKartDurumu,
        KartDurumu.izYok,
      );
    });
  });
}
