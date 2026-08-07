import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/location_service.dart';

/// GPS → adres nöbetçisi (bulgu 2).
///
/// Casper 2026-08-07: "Koordinat kaydedildi diyor ama İl, İlçe ve Açık
/// Adres boş kalıyor." İki ayrı sebep vardı, ikisi de bizim yaptığımız
/// düzeltmelerden çıkmıştı:
///
/// 1) Koordinat, sapma eşiği kontrolünden ÖNCE yazılıyordu. Kontrol
///    başarısız olunca akış duruyor ama koordinat kayıtlı kalıyordu.
///    Ekran "kaydedildi" diyor, adres hiç çözülmüyordu.
///
/// 2) Eşik 10 metreydi. O değer yalnız yerel GPS donanımıyla tutturulur;
///    tarayıcı konumu telefonda bile 20-60 metre sapar. Yani kapı hiç
///    açılmıyordu.
void main() {
  final kok = Directory.current.path;

  test('sapma eşiği tarayıcıdan ulaşılabilir', () {
    // 10 metre tarayıcıda imkânsız; 100 metre gerçekçi ve masaüstündeki
    // kilometrelerce sapmayı hâlâ eliyor.
    expect(LocationService.maxAcceptedAccuracyMeters, greaterThanOrEqualTo(50));
    expect(LocationService.maxAcceptedAccuracyMeters, lessThanOrEqualTo(150));
  });

  test('sapma büyükse adres yine doldurulur, yalnız iğne bekletilir', () {
    // 2026-08-07 ikinci düzeltme. İlk düzeltmede koordinat eşikten sonra
    // yazılıyordu ama eşik geçilmezse HİÇBİR ŞEY yapılmıyordu — ne adres,
    // ne il, ne ilçe. Casper: "gps yine çalışmıyor, koordinatı da
    // bulamıyor... şimdi hiç bulamadı."
    //
    // 300 metre sapmayla bile il, ilçe ve mahalle DOĞRU çıkar. Müşteriyi
    // yanlış sokağa gönderen şey harita iğnesidir, adres metni değil.
    final kaynak =
        File(
          '$kok/lib/widgets/editor/location_editor_section.dart',
        ).readAsStringSync();

    expect(kaynak, contains('igneKabul'));
    // İğne koşullu, adres koşulsuz.
    expect(kaynak, contains('igneKabul ? position.latitude : null'));
    expect(kaynak, contains('address: newAddress'));
    // Eşiğe takılıp AKIŞTAN ÇIKAN eski kalıp geri gelmemeli.
    // (if (!mounted) return; ayrı bir şey — widget yaşam döngüsü koruması.)
    expect(
      RegExp(
        r'accuracy > LocationService\.maxAcceptedAccuracyMeters\)\s*\{'
        r'[^}]*return;',
        multiLine: true,
      ).hasMatch(kaynak),
      isFalse,
      reason:
          'Eşik geçilmeyince akıştan çıkılırsa adres hiç çözülmez, '
          'esnaf boş ekrana bakar.',
    );
  });

  test('adres çözümleme her iki GPS yolunda da çağrılıyor', () {
    for (final yol in [
      'lib/widgets/editor/location_editor_section.dart',
      'lib/controllers/mixins/store_location_mixin.dart',
    ]) {
      final kaynak = File('$kok/$yol').readAsStringSync();
      expect(
        kaynak,
        contains('getAddressFromCoordinates'),
        reason:
            '$yol adres çözümlemiyor; koordinat yalnız başına '
            'esnafa hiçbir şey ifade etmez.',
      );
    }
  });
}
