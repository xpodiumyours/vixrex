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

  test('adres onaylanmadan hiçbir alana yazılmıyor', () {
    // 2026-08-08. Bu noktada iki kez yanlış yapıldı:
    //   1) Eşik 10 metre yapıldı → her şey reddedildi, esnaf boş ekrana
    //      baktı ("koordinatı da bulamıyor").
    //   2) Eşik gevşetilip adres koşulsuz yazıldı → 20 KM sapmalı adres
    //      vitrine düştü (Çekmeköy'deyken Ümraniye).
    //
    // Sabit eşik bu işi çözmüyor: tarayıcı bazen 30 metre bazen 20 km
    // sapıyor, hangisi olduğu önceden bilinemiyor. Karar esnafa ait.
    final kaynak =
        File(
          '$kok/lib/widgets/editor/location_editor_section.dart',
        ).readAsStringSync();

    expect(kaynak, contains('_bekleyenOneri'));
    expect(kaynak, contains('Burası mı?'));
    expect(kaynak, contains('Evet, burası'));
    expect(kaynak, contains('Hayır, elle yazayım'));

    // Alanlar YALNIZ onay eyleminde yazılmalı.
    final kabul = kaynak.substring(
      kaynak.indexOf('void _oneriyiKabulEt()'),
      kaynak.indexOf('void _oneriyiReddet()'),
    );
    expect(kabul, contains('address: o.adres'));
    expect(kabul, contains('latitude: o.enlem'));

    // Red eyleminde hiçbir alan yazılmamalı — yanlış adres, boş
    // adresten beterdir.
    final red = kaynak.substring(
      kaynak.indexOf('void _oneriyiReddet()'),
      kaynak.indexOf('Widget build(BuildContext context)'),
    );
    expect(red.contains('address:'), isFalse);
    expect(red.contains('latitude:'), isFalse);
  });

  test('mahalle eki tekrarlanmıyor', () {
    // OpenStreetMap mahalle adını "... Mahallesi" diye veriyor; koda
    // bir de "Mah." eklenince vitrinde "Adem Yavuz Mahallesi.," çıktı.
    final servis =
        File('$kok/lib/services/location_service.dart').readAsStringSync();
    expect(servis, contains("endsWith('mahallesi')"));
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
