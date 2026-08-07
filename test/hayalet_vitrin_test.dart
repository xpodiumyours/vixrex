import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hayalet vitrin nöbetçisi (bulgu 17).
///
/// 2026-08-07: karşılama ekranı "vitrinin var mı" sorusunu yalnız
/// tarayıcının hafızasına soruyordu. Bulutta silinmiş ya da hiç
/// oluşmamış bir vitrin uygulamada sonsuza kadar görünüyordu; esnaf
/// "Kayıtlı Vitrinimi Düzenle" ile karşılanıyor ama ortada vitrin yoktu.
///
/// Casper: "kayıtlı vitrinini düzenle diyerek karşılıyor, vitrin yok
/// ortada, vitrini sil diyorum ama silinmiyor".
void main() {
  final kok = Directory.current.path;
  String oku(String yol) => File('$kok/$yol').readAsStringSync();

  test('karşılama ekranı yayın iddiasını buluta doğrulatıyor', () {
    final landing = oku('lib/screens/landing_screen.dart');
    expect(landing, contains('yayindaMi('));
    expect(
      landing,
      contains('varMi == false'),
      reason: 'Bulut KESİN olarak yok demedikçe yerel kayıt silinmemeli.',
    );
  });

  test('bilinmeyen durumda yerel kayıt korunuyor', () {
    final servis = oku('lib/services/store_publish_service.dart');
    final govde = servis.substring(
      servis.indexOf('Future<bool?> yayindaMi('),
      servis.indexOf('Future<Result<StorePublishResult>> publishStore('),
    );

    // Üç cevap şart: var / yok / bilinmiyor. İki cevaba düşerse
    // internet yokken esnafın vitrini silinir.
    expect(govde, contains('Future<bool?>'));
    expect(govde, contains('return null;'));
    expect(govde, contains('catch'));
  });
}
