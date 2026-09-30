import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vixrex/services/invoice_catalog/fatura_yayinla_servisi.dart';

void main() {
  for (final verified in [false, true]) {
    test('consumer verification is retained when $verified', () async {
      final service = FaturaYayinlaServisi(originOverride: 'https://vixrex-test.local',
        httpClient: MockClient((request) async => http.Response(jsonEncode({
          'tamam': true, 'yayinda': 1, 'taslak': 0,
          'satirlar': [{'id': 'product-1', 'durum': 'yayinda'}],
          'tuketiciDogrulamasi': verified ? 'tamam' : 'yapilamadi',
        }), 200)));
      final result = await service.yayinla(productIds: ['product-1'], storeSlug: 'magaza', editToken: 'session-token');
      expect(result.isSuccess, isTrue);
      expect(result.data!.satirlar.single.yayinda, isTrue);
      expect(result.data!.tuketiciDogrulandi, verified);
    });
  }
  test('missing verification is not treated as a verified consumer result', () {
    const result = FaturaYayinlaSonucu(yayinda: 1, taslak: 0,
      satirlar: [YayinlananSatir(id: 'product-1', yayinda: true)]);
    expect(result.tuketiciDogrulandi, isFalse);
  });
}
