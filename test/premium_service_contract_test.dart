import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;

  String read(String path) => File('$root/$path').readAsStringSync();

  test('purchasePremium istemciden premium yazamaz (kaldırıldı)', () {
    // Spec PR #6: "yalnız doğrulanmış PayTR callback'i premium yazar" —
    // istemciden premium yazan yöntem olmamalı (eski açık: profiles'tan
    // is_premium/premium_expires_at'i doğrudan güncelliyordu).
    final service = read('lib/services/premium_service.dart');
    expect(service, isNot(contains('purchasePremium')));
    expect(service, isNot(contains("from('profiles')")));
    // Okuma tarafında json['is_premium'] anahtarı meşrudur; yazma tarafı
    // (profile güncelleme) yasaktır.
    expect(service, isNot(contains("'is_premium': true")));
    expect(service, isNot(contains('.update(')));
  });

  test('premium durumu vitrin bazlı, edit_token kanıtlı RPC ile okunur', () {
    final service = read('lib/services/premium_service.dart');
    expect(service, contains('getPremiumStatus'));
    expect(service, contains('get_store_premium_status'));
    expect(service, contains('p_edit_token'));
    expect(service, contains('StorePremiumStatus'));
  });

  test(
    'edit_token asla SELECT/from zincirine girmez, yalnız RPC parametresi',
    () {
      final service = read('lib/services/premium_service.dart');
      expect(service, isNot(contains(".eq('edit_token'")));
      expect(service, isNot(contains("select('edit_token'")));
      expect(
        service,
        contains("params: {'p_slug': slug, 'p_edit_token': editToken}"),
      );
    },
  );

  test('OCR yardımcıları korunur (ayrı özellik, kapsam dışı)', () {
    final service = read('lib/services/premium_service.dart');
    expect(service, contains('checkAndIncrementOcrUsage'));
    expect(service, contains('saveOcrHistory'));
  });
}
