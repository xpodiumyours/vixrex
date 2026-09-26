import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/services/invoice_catalog/catalog_invoice_trace_resolver.dart';
import 'package:vixrex/services/invoice_catalog/invoice_draft_decision_engine.dart';

// ASIL BUG BURADA KANITLANIYOR: eski zincirde InvoiceOcrDraftAdapter
// supplierIdentityStrength'i her zaman `weak` yazıyordu
// (invoice_ocr_draft_adapter.dart:69) ve InvoiceDraftDecisionEngine bu
// yüzden kapıyı hiç açmıyordu — telefon ne kadar iyi okursa okusun taslak
// bile hazırlanmıyordu.
//
// Bu test, gerçek üretici kataloğunda BULUNAN bir satırın, ağdan gelen
// gerçek yanıtla `strong` kanıta yükseltildiğini ve kapının GERÇEKTEN
// açıldığını kanıtlar.

InvoiceProductDraft zayifTaslak({required String model}) {
  final now = DateTime.now().toUtc();
  return InvoiceProductDraft(
    id: 'draft-1',
    rawSourceLine: '$model ürün adı 137,00 TL',
    rawName: EvidenceValue(
      value: 'Elit Erkek Elastan Sıfır Yaka',
      sourceType: EvidenceSourceType.invoice,
      sourceReference: 'draft-1',
      strength: EvidenceStrength.partial,
      verifiedAt: now,
    ),
    modelCode: EvidenceValue(
      value: model,
      sourceType: EvidenceSourceType.invoice,
      sourceReference: 'draft-1',
      strength: EvidenceStrength.partial,
      verifiedAt: now,
    ),
    // Eski zincirdeki HATALI başlangıç durumu: kod okunsa bile tedarikçi
    // izi hep zayıf, ürün izi en fazla partial.
    supplierIdentityStrength: EvidenceStrength.weak,
    productIdentityStrength: EvidenceStrength.partial,
  );
}

void main() {
  group('CatalogInvoiceTraceResolver — gerçek kapı açılıyor mu', () {
    test(
      'katalogda bulunan kod: kanıt strong olur, imageCandidates gelir',
      () async {
        final resolver = CatalogInvoiceTraceResolver(
          storeSlug: 'deneme-vitrin',
          editToken: 'token-1',
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient((request) async {
            final govde = jsonDecode(request.body) as Map;
            expect(govde['slug'], 'deneme-vitrin');
            expect(govde['editToken'], 'token-1');
            final satirlar = govde['satirlar'] as List;
            expect((satirlar.first as Map)['model'], 'ELT1302');

            return http.Response(
              jsonEncode({
                'tamam': true,
                'katalogEslesmesi': 1,
                'satirlar': [
                  {
                    'model': 'ELT1302',
                    'katalog': {
                      'firma': 'Seher Mensucat',
                      'dayanak': 'kod',
                      'izinDurumu': 'bekliyor',
                      'resmiAd':
                          'ELT1302 Elit Erkek Elastan Sıfır Yaka Uzun Kol',
                      'marka': 'Tutku Elit',
                      'aciklama': '',
                      'gorseller': [
                        'https://cdn.myikas.com/1.webp',
                        'https://cdn.myikas.com/2.webp',
                        'https://cdn.myikas.com/3.webp',
                      ],
                      'kaynak': 'https://sehermensucat.com/elt1302',
                    },
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );

        final sonuc = await resolver.resolve([zayifTaslak(model: 'ELT1302')]);
        final guncellenen = sonuc.single;

        // ASIL KANIT: eskiden hiçbir zaman strong olmayan alanlar şimdi strong.
        expect(guncellenen.supplierIdentityStrength, EvidenceStrength.strong);
        expect(guncellenen.productIdentityStrength, EvidenceStrength.strong);
        expect(guncellenen.normalizedName?.value, contains('ELT1302'));
        expect(guncellenen.brand?.value, 'Tutku Elit');
        expect(guncellenen.imageCandidates, hasLength(3));

        // İzin henüz "bekliyor" olduğu için görsel kullanılabilir değil —
        // izin kapısı bozulmadı.
        expect(
          guncellenen.imageCandidates.first.rightsStatus,
          isNot(RightsStatus.verifiedSupplierPermission),
        );
      },
    );

    test(
      'uçtan uca: fiyat + esnaf onayı + kanıt birlikte gerçekten yayına açar',
      () async {
        final resolver = CatalogInvoiceTraceResolver(
          storeSlug: 'deneme-vitrin',
          editToken: 'token-1',
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'satirlar': [
                  {
                    'model': 'ELT1302',
                    'katalog': {
                      'firma': 'Seher Mensucat',
                      'dayanak': 'kod',
                      'izinDurumu': 'var', // izin verilmiş senaryosu
                      'resmiAd':
                          'ELT1302 Elit Erkek Elastan Sıfır Yaka Uzun Kol',
                      'marka': 'Tutku Elit',
                      'aciklama': '',
                      'gorseller': ['https://cdn.myikas.com/1.webp'],
                      'kaynak': 'https://sehermensucat.com/elt1302',
                    },
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );

        final eslesen = await resolver.resolve([zayifTaslak(model: 'ELT1302')]);
        final tasarim = eslesen.single.copyWith(
          merchantApproved: true,
          salePrice: 199,
        );

        final karar = const InvoiceDraftDecisionEngine().evaluate(tasarim);

        // Bu satır eski kodda ASLA true olamazdı — supplierIdentityStrength
        // hep weak olduğu için evaluate() ilk kontrolde stopNoGuess dönerdi.
        expect(karar.canPublish, isTrue);
        expect(karar.decision, AutomationDecision.readyForPublish);
      },
    );

    test(
      'katalogda bulunmayan kod: kanıt zayıf kalır, kapı yine kapalı',
      () async {
        final resolver = CatalogInvoiceTraceResolver(
          storeSlug: 'deneme-vitrin',
          editToken: 'token-1',
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'satirlar': [
                  {'model': 'BILINMEYEN999', 'katalog': null},
                ],
              }),
              200,
            );
          }),
        );

        final zayif = zayifTaslak(model: 'BILINMEYEN999');
        final sonuc = await resolver.resolve([zayif]);
        final degismeyen = sonuc.single;

        expect(degismeyen.supplierIdentityStrength, EvidenceStrength.weak);
        final karar = const InvoiceDraftDecisionEngine().evaluate(degismeyen);
        expect(karar.canPublish, isFalse);
        expect(
          karar.canPrepareDraft,
          isFalse,
        ); // uydurma yok — taslak bile açılmaz
      },
    );

    test('ağ hatasında satır olduğu gibi kalır, tahmin edilmez', () async {
      final resolver = CatalogInvoiceTraceResolver(
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient(
          (request) async => http.Response('sunucu hatasi', 500),
        ),
      );

      final zayif = zayifTaslak(model: 'ELT1302');
      final sonuc = await resolver.resolve([zayif]);

      expect(sonuc.single.supplierIdentityStrength, EvidenceStrength.weak);
      expect(sonuc.single.normalizedName, isNull);
    });

    test(
      'mağaza henüz yayınlanmadıysa (slug/editToken boş) ağa hiç çıkmaz',
      () async {
        var cagrildi = false;
        final resolver = CatalogInvoiceTraceResolver(
          storeSlug: '',
          editToken: '',
          httpClient: MockClient((request) async {
            cagrildi = true;
            return http.Response('{}', 200);
          }),
        );

        final zayif = zayifTaslak(model: 'ELT1302');
        final sonuc = await resolver.resolve([zayif]);

        expect(cagrildi, isFalse);
        expect(sonuc.single, same(zayif));
      },
    );
  });
}
