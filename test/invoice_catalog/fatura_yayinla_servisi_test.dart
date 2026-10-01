import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vixrex/services/invoice_catalog/fatura_yayinla_servisi.dart';

// Telefonun ayrı Yayınla çağrısı: web'in sonuç ekranıyla AYNI uç
// (/api/fatura-yayinla), AYNI kimlik deseni (slug + editToken). Taslak
// sunucuda tekrar okunur; kapı kapalıysa telefonda "yayınlandı" yazmaz.

void main() {
  group('FaturaYayinlaServisi — telefonun ayrı Yayınla çağrısı', () {
    test(
      'taslak id listesini slug ve jetonla /api/fatura-yayinla ucuna gönderir',
      () async {
        late http.BaseRequest yakalanan;
        final servis = FaturaYayinlaServisi(
          originOverride: 'https://vixrex-test.local',
          httpClient: MockClient((request) async {
            yakalanan = request;
            return http.Response(
              jsonEncode({
                'tamam': true,
                'yayinda': 1,
                'taslak': 1,
                'satirlar': [
                  {'id': 'urun-1', 'durum': 'yayinda'},
                  {
                    'id': 'urun-2',
                    'durum': 'taslak',
                    'sebep': 'Satış fiyatı girilmedi.',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );

        final sonuc = await servis.yayinla(
          productIds: ['urun-1', 'urun-2'],
          storeSlug: 'deneme-vitrin',
          editToken: 'token-1',
        );

        expect(yakalanan.method, 'POST');
        expect(yakalanan.url.path, '/api/fatura-yayinla');
        final govde = jsonDecode((yakalanan as http.Request).body) as Map;
        expect(govde['slug'], 'deneme-vitrin');
        expect(govde['editToken'], 'token-1');
        expect(govde['productIds'], ['urun-1', 'urun-2']);

        expect(sonuc.isSuccess, isTrue);
        final ozet = sonuc.data!;
        expect(ozet.yayinda, 1);
        expect(ozet.taslak, 1);
        expect(ozet.satirlar, hasLength(2));
        expect(ozet.satirlar[0].yayinda, isTrue);
        expect(ozet.satirlar[1].yayinda, isFalse);
        expect(ozet.satirlar[1].sebep, contains('Satış fiyatı'));
      },
    );

    test('vitrin yayınlanmamışsa ağa hiç çıkmaz', () async {
      var cagrildi = false;
      final servis = FaturaYayinlaServisi(
        httpClient: MockClient((request) async {
          cagrildi = true;
          return http.Response('{}', 200);
        }),
      );

      final sonuc = await servis.yayinla(
        productIds: ['urun-1'],
        storeSlug: '',
        editToken: '',
      );

      expect(cagrildi, isFalse);
      expect(sonuc.isFailure, isTrue);
    });

    test('ürün seçilmediyse ağa hiç çıkmaz', () async {
      var cagrildi = false;
      final servis = FaturaYayinlaServisi(
        httpClient: MockClient((request) async {
          cagrildi = true;
          return http.Response('{}', 200);
        }),
      );

      final sonuc = await servis.yayinla(
        productIds: [],
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      expect(cagrildi, isFalse);
      expect(sonuc.isFailure, isTrue);
    });

    test('sunucu hata dönerse anlaşılır mesajla başarısız olur', () async {
      final servis = FaturaYayinlaServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'hata': 'Oturumun geçersiz veya süresi dolmuş.'}),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final sonuc = await servis.yayinla(
        productIds: ['urun-1'],
        storeSlug: 'deneme-vitrin',
        editToken: 'eski-jeton',
      );

      expect(sonuc.isFailure, isTrue);
      expect(sonuc.failure?.message, contains('Oturumun'));
    });

    test('ağ hatasında çökmez, anlaşılır hata döner', () async {
      final servis = FaturaYayinlaServisi(
        httpClient: MockClient(
          (request) async => throw Exception('bağlantı yok'),
        ),
      );

      final sonuc = await servis.yayinla(
        productIds: ['urun-1'],
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      expect(sonuc.isFailure, isTrue);
    });
  });
}
