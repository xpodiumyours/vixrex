import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/services/invoice_catalog/fatura_islem_servisi.dart';
import 'package:vixrex/services/invoice_catalog/fatura_oku_servisi.dart';

Map<String, dynamic> invoice() => {
  'tamam': true,
  'islemKimligi': '11111111-1111-4111-8111-111111111111',
  'tedarikci': 'Toptanci',
  'satirlar': [
    {
      'ad': 'Gercek urun',
      'model': '16747',
      'adet': 8,
      'alisBirimFiyat': 450,
      'sonuc': 'kanitli',
      'urunId': '22222222-2222-4222-8222-222222222222',
      'katalog': {
        'resmiAd': 'Gercek urun',
        'firma': 'uretici',
        'kaynak': 'https://uretici.example/16747',
        'izinDurumu': 'denied',
        'gorseller': ['https://uretici.example/photo.jpg'],
      },
      'sahipDurumu': {
        'satisFiyati': '1.799,50',
        'stok': '3',
        'stokOnaylandi': true,
        'onayli': true,
        'kategoriId': '33333333-3333-4333-8333-333333333333',
        'esnafGorselleri': ['https://depo.example/merchant.jpg'],
      },
    },
  ],
};

void main() {
  test('web sahip durumu geri acilir, alis adedi satis stogunu ezmez', () {
    final result = const FaturaOkuServisi().cozumle(invoice());
    expect(result.isSuccess, isTrue);
    final product = result.data!.products.single;
    final draft = result.data!.invoiceDrafts.single;
    expect(product.price, 1799.5);
    expect(product.quantity, 3);
    expect(product.documentQuantity, 8);
    expect(product.purchaseUnitPrice, 450);
    expect(product.isApproved, isTrue);
    expect(draft.merchantApproved, isTrue);
    expect(draft.stockConfirmed, isTrue);
    expect(product.databaseEntryId, '22222222-2222-4222-8222-222222222222');
    expect(result.data!.invoiceOwnerStates.single['esnafGorselleri'], [
      'https://depo.example/merchant.jpg',
    ]);
  });

  test('reddedilmis gorsel kullanilmaz, esnafin kendi gorseli korunur', () {
    final result = const FaturaOkuServisi().cozumle(invoice());
    final images = result.data!.invoiceDrafts.single.imageCandidates;
    expect(images.first.rightsStatus, RightsStatus.denied);
    expect(images.first.canUse, isFalse);
    expect(images.last.sourceType, EvidenceSourceType.merchantUpload);
    expect(images.last.canUse, isTrue);
  });

  test('ilk okuma stok ve kart onayini uretmez', () {
    final data = invoice();
    ((data['satirlar'] as List).single as Map).remove('sahipDurumu');
    final result = const FaturaOkuServisi().cozumle(data);
    expect(result.data!.products.single.price, isNull);
    expect(result.data!.products.single.isApproved, isFalse);
    expect(result.data!.invoiceDrafts.single.stockConfirmed, isFalse);
  });

  test('gecersiz satir atilip sonraki satirin kimligi kaydirilmaz', () {
    final data = invoice();
    data['satirlar'] = <dynamic>[null, ...(data['satirlar'] as List)];
    expect(const FaturaOkuServisi().cozumle(data).isFailure, isTrue);
  });

  test('ayni islem kaydina sahip bilgisi tokenla geri yazilir', () async {
    late http.Request captured;
    final service = FaturaIslemServisi(
      originOverride: 'https://vixrex-test.local',
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('{"tamam":true,"kaydedilen":1}', 200);
      }),
    );
    final owner =
        ((invoice()['satirlar'] as List).single as Map)['sahipDurumu'];
    final result = await service.kaydet(
      slug: 'magaza',
      editToken: 'session-token',
      islemKimligi: '11111111-1111-4111-8111-111111111111',
      satirlar: [
        {'satirSirasi': 0, 'sahipDurumu': owner},
      ],
    );
    expect(result.isSuccess, isTrue);
    expect(captured.method, 'PUT');
    expect(captured.url.path, '/api/fatura-islem');
    expect(captured.headers['x-vixrex-edit-token'], 'session-token');
    final body = jsonDecode(captured.body) as Map;
    expect(((body['satirlar'] as List).single as Map)['sahipDurumu'], owner);
  });
}
