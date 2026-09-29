import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/services/invoice_catalog/fatura_oku_servisi.dart';

// Vixrex'in telefon tarafındaki TEK okuma ucu çağrısı: bu servis artık
// cihaz üstü OCR/eski yerel zincir yerine doğrudan /api/fatura-oku'yu
// çağırıyor — web'in kullandığı AYNI uç.

void main() {
  group('FaturaOkuServisi — telefonun tek okuma ucu çağrısı', () {
    test('fotoğrafı multipart olarak /api/fatura-oku uçuna gönderir', () async {
      late http.BaseRequest yakalanan;
      final servis = FaturaOkuServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          yakalanan = request;
          return http.Response(
            jsonEncode({
              'tamam': true,
              'tedarikci': 'Seher Mensucat',
              'tedarikciVergiNo': '1234567890',
              'tedarikciAdres': 'İstanbul Güngören',
              'tedarikciSite': 'sehermensucat.com',
              'satirlar': [
                {
                  'hamSatir':
                      'ELT1302 Elit Erkek Elastan Sıfır Yaka 8681128321677 2 137,00 274,00',
                  'model': 'ELT1302',
                  'ad': 'Elit Erkek Elastan Sıfır Yaka',
                  'barkod': '8681128321677',
                  'varyant': 'Siyah',
                  'beden': 'L',
                  'adet': 2,
                  'alisBirimFiyat': 137,
                  'satirToplam': 274,
                  'guven': 0.9,
                  'katalog': {
                    'firma': 'Seher Mensucat',
                    'dayanak': 'kod',
                    'izinDurumu': 'bekliyor',
                    'resmiAd': 'ELT1302 Elit Erkek Elastan Sıfır Yaka Uzun Kol',
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

      final sonuc = await servis.oku(
        imageBytes: Uint8List.fromList([1, 2, 3, 4]),
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      expect(yakalanan.method, 'POST');
      expect(yakalanan.url.path, '/api/fatura-oku');
      expect(
        yakalanan.headers['content-type'] ?? '',
        contains('multipart/form-data'),
      );
      // MockClient gönderilen isteği düz bir http.Request'e dönüştürüyor;
      // multipart gövdesi ham baytlarda kalıyor — alan adları ve dosya
      // alanının varlığı metin içinde aranarak doğrulanır.
      final govdeMetni = (yakalanan as http.Request).body;
      expect(govdeMetni, contains('name="slug"'));
      expect(govdeMetni, contains('deneme-vitrin'));
      expect(govdeMetni, contains('name="editToken"'));
      expect(govdeMetni, contains('token-1'));
      expect(govdeMetni, contains('name="dosya"'));

      expect(sonuc.isSuccess, isTrue);
      final katalog = sonuc.data!;
      expect(katalog.products, hasLength(1));
      expect(katalog.invoiceDrafts, hasLength(1));
      final taslak = katalog.invoiceDrafts.single;
      expect(taslak.rawSourceLine, contains('137,00'));
      expect(taslak.supplierName?.value, 'Seher Mensucat');
      expect(taslak.supplierTaxOrTradeIdentifier?.value, '1234567890');
      expect(taslak.supplierAddress?.value, 'İstanbul Güngören');
      expect(taslak.supplierOfficialDomain?.value, 'sehermensucat.com');
    });

    test(
      'katalogda bulunan satır GERÇEKTEN strong kanıtla gelir — cihaz üstü OCR'
      ' yolundaki eski hata (hep weak) burada tekrar etmez',
      () async {
        final servis = FaturaOkuServisi(
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'tedarikci': 'Seher Mensucat',
                'satirlar': [
                  {
                    'model': 'ELT1302',
                    'ad': 'Elit Erkek',
                    'barkod': '8681128321677',
                    'guven': 0.9,
                    'katalog': {
                      'firma': 'Seher Mensucat',
                      'dayanak': 'kod',
                      'izinDurumu': 'var',
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

        final sonuc = await servis.oku(
          imageBytes: Uint8List.fromList([1]),
          storeSlug: 'deneme-vitrin',
          editToken: 'token-1',
        );

        final taslak = sonuc.data!.invoiceDrafts.single;
        expect(taslak.supplierIdentityStrength, EvidenceStrength.strong);
        expect(taslak.productIdentityStrength, EvidenceStrength.strong);
        expect(taslak.normalizedName?.value, contains('ELT1302'));
        expect(taslak.imageCandidates, hasLength(1));
        expect(taslak.rightsStatus, RightsStatus.verifiedSupplierPermission);

        final urun = sonuc.data!.products.single;
        expect(urun.isInvoiceSource, isTrue);
        expect(urun.name, contains('ELT1302'));
      },
    );

    test('katalogda bulunamayan satır zayıf kalır, tahmin edilmez', () async {
      final servis = FaturaOkuServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'satirlar': [
                {
                  'model': 'BILINMEYEN999',
                  'ad': 'Bilinmeyen ürün',
                  'guven': 0.4,
                  'katalog': null,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final sonuc = await servis.oku(
        imageBytes: Uint8List.fromList([1]),
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      final taslak = sonuc.data!.invoiceDrafts.single;
      expect(taslak.supplierIdentityStrength, EvidenceStrength.weak);
      expect(taslak.productIdentityStrength, EvidenceStrength.weak);
      expect(taslak.normalizedName, isNull);
    });

    test(
      'vitrin yayınlanmamışsa (slug/editToken boş) ağa hiç çıkmaz',
      () async {
        var cagrildi = false;
        final servis = FaturaOkuServisi(
          httpClient: MockClient((request) async {
            cagrildi = true;
            return http.Response('{}', 200);
          }),
        );

        final sonuc = await servis.oku(
          imageBytes: Uint8List.fromList([1]),
          storeSlug: '',
          editToken: '',
        );

        expect(cagrildi, isFalse);
        expect(sonuc.isFailure, isTrue);
      },
    );

    test('sunucu hata dönerse anlaşılır mesajla başarısız olur', () async {
      final servis = FaturaOkuServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'hata': 'Bu fotoğrafta ürün satırı bulunamadı.'}),
            422,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final sonuc = await servis.oku(
        imageBytes: Uint8List.fromList([1]),
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      expect(sonuc.isFailure, isTrue);
      expect(sonuc.failure?.message, contains('ürün satırı bulunamadı'));
    });

    test(
      'sunucunun kart hali, celiskisi ve islem kimligi telefonda aynen tasinir',
      () async {
        final servis = FaturaOkuServisi(
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'tamam': true,
                'islemKimligi': 'islem-42',
                'satirlar': [
                  {
                    'model': 'TER0117',
                    'ad': 'Tutku Erkek Atlet',
                    'guven': 0.9,
                    'sonuc': 'celiski',
                    'katalog': null,
                    'celiski': {
                      'dayanak': 'barkod',
                      'adaylar': [
                        {
                          'ad': 'Tutku Erkek Atlet Siyah L',
                          'kaynak': 'https://sehermensucat.com/a',
                        },
                        {
                          'ad': 'Tutku Erkek Atlet Siyah XL',
                          'kaynak': 'https://sehermensucat.com/b',
                        },
                      ],
                    },
                  },
                  {
                    'model': 'YOK999',
                    'ad': 'Bilinmeyen ürün',
                    'guven': 0.9,
                    'sonuc': 'iz-yok',
                    'katalog': null,
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );

        final sonuc = await servis.oku(
          imageBytes: Uint8List.fromList([1]),
          storeSlug: 'deneme-vitrin',
          editToken: 'token-1',
        );

        final katalog = sonuc.data!;
        // Aynı belge, aynı işlem: web ile telefon aynı kimliği taşır.
        expect(katalog.islemKimligi, 'islem-42');

        final celiskili = katalog.invoiceDrafts[0];
        expect(celiskili.etkinKartDurumu, KartDurumu.celiski);
        expect(celiskili.celiskiAdaylari, hasLength(2));
        expect(celiskili.celiskiDayanak, 'barkod');
        expect(celiskili.islemKimligi, 'islem-42');

        final izsiz = katalog.invoiceDrafts[1];
        expect(izsiz.etkinKartDurumu, KartDurumu.izYok);

        // Faturadaki adet öneridir; hiçbir taslak kendiliğinden stok onaylı değil.
        expect(
          katalog.invoiceDrafts.every((taslak) => !taslak.stockConfirmed),
          isTrue,
        );
      },
    );

    test('ağ hatasında çökmez, anlaşılır hata döner', () async {
      final servis = FaturaOkuServisi(
        httpClient: MockClient(
          (request) async => throw Exception('bağlantı yok'),
        ),
      );

      final sonuc = await servis.oku(
        imageBytes: Uint8List.fromList([1]),
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      expect(sonuc.isFailure, isTrue);
    });
  });
}
