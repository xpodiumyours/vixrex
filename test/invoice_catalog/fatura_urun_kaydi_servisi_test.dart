import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vixrex/services/invoice_catalog/fatura_urun_kaydi_servisi.dart';

// Telefonun taslak kaydı: web ile AYNI sunucu kapısı (/api/products/batch),
// jeton ile kimlik. Ürün burada yayınlanmaz; yayın ayrı eylemdir.

FaturaKaydiSatiri ornekSatir({bool stokOnayli = true}) {
  return FaturaKaydiSatiri(
    satirSirasi: 0,
    islemKimligi: '11111111-1111-4111-8111-111111111111',
    ad: 'IŞILAY 16747 İnterlok Penye Erkek Takım',
    aciklama: 'Pamuklu',
    fiyatMetni: '499 TL',
    kategoriId: '22222222-2222-4222-8222-222222222222',
    gorseller: const ['https://depo.example/a.jpg'],
    gorselKaynagi: 'https://isilay.example/urun/16747',
    marka: 'Işılay',
    barkod: null,
    model: '16747',
    varyant: 'Siyah',
    beden: 'L',
    stok: stokOnayli ? 8 : null,
    stokOnaylandi: stokOnayli,
    kartDurumu: 'kanitli',
    disKimlik: '1234567890:16747',
    alisFiyati: 450,
  );
}

void main() {
  group('FaturaUrunKaydiServisi — telefonun taslak kaydı', () {
    test('satırı slug ve jetonla /api/products/batch ucuna taslak olarak gönderir',
        () async {
      late http.BaseRequest yakalanan;
      final servis = FaturaUrunKaydiServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          yakalanan = request;
          return http.Response(
            jsonEncode({
              'tamam': true,
              'yayinda': 0,
              'taslak': 1,
              'hatali': 0,
              'satirlar': [
                {
                  'sira': 0,
                  'ad': 'IŞILAY 16747',
                  'durum': 'taslak',
                  'id': 'urun-1',
                  'kayit': 'yeni',
                  'sebep': 'Yayın onayı verilmedi; ürün taslak kaydedildi.',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final sonuc = await servis.taslakKaydet(
        satirlar: [ornekSatir()],
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      expect(yakalanan.method, 'POST');
      expect(yakalanan.url.path, '/api/products/batch');
      final govde = jsonDecode((yakalanan as http.Request).body) as Map;
      expect(govde['slug'], 'deneme-vitrin');
      expect(govde['editToken'], 'token-1');
      final urun = (govde['products'] as List).first as Map;
      expect(urun['sourceType'], 'invoice');
      expect(urun['yayinIstegi'], false);
      expect(urun['ownerApproved'], true);
      expect(urun['kartDurumu'], 'kanitli');
      expect(urun['stokOnaylandi'], true);
      expect(urun['stockQuantity'], 8);
      expect(urun['islemKimligi'], '11111111-1111-4111-8111-111111111111');
      expect(urun['satirSirasi'], 0);
      expect(urun['gorselKaynagi'], 'https://isilay.example/urun/16747');
      expect(urun['externalProductId'], '1234567890:16747');
      expect(urun['purchasePriceAmount'], 450);

      expect(sonuc.isSuccess, isTrue);
      final ozet = sonuc.data!;
      expect(ozet.taslak, 1);
      expect(ozet.yayinda, 0);
      expect(ozet.satirlar.single.kayit, 'yeni');
      expect(ozet.yayinlanabilirTaslakIdleri, ['urun-1']);
    });

    test('stok onaylanmadıysa stok gönderilmez', () async {
      late http.BaseRequest yakalanan;
      final servis = FaturaUrunKaydiServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          yakalanan = request;
          return http.Response(
            jsonEncode({'tamam': true, 'taslak': 1, 'satirlar': []}),
            200,
          );
        }),
      );

      await servis.taslakKaydet(
        satirlar: [ornekSatir(stokOnayli: false)],
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      final govde = jsonDecode((yakalanan as http.Request).body) as Map;
      final urun = (govde['products'] as List).first as Map;
      expect(urun['stockQuantity'], isNull);
      expect(urun['stokOnaylandi'], false);
    });

    test('sunucu reddederse hata mesajı telefona olduğu gibi döner', () async {
      final servis = FaturaUrunKaydiServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({'hata': 'Oturumun geçersiz veya süresi dolmuş.'}),
            401,
          );
        }),
      );

      final sonuc = await servis.taslakKaydet(
        satirlar: [ornekSatir()],
        storeSlug: 'deneme-vitrin',
        editToken: 'kotu',
      );

      expect(sonuc.isFailure, isTrue);
      expect(sonuc.failure!.message, contains('Oturumun geçersiz'));
    });

    test('vitrin yayınlanmamışsa ya da satır yoksa ağa hiç çıkmaz', () async {
      var cagriSayisi = 0;
      final servis = FaturaUrunKaydiServisi(
        originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async {
          cagriSayisi++;
          return http.Response('{}', 200);
        }),
      );

      final jetonsuz = await servis.taslakKaydet(
        satirlar: [ornekSatir()],
        storeSlug: '',
        editToken: '',
      );
      final satirsiz = await servis.taslakKaydet(
        satirlar: const [],
        storeSlug: 'deneme-vitrin',
        editToken: 'token-1',
      );

      expect(jetonsuz.isFailure, isTrue);
      expect(satirsiz.isFailure, isTrue);
      expect(cagriSayisi, 0);
    });
  });
}
