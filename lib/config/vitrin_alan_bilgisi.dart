import 'package:vixrex/config/vitrin_alanlari.g.dart';

/// Vitrin alanının TEK KAYNAK karşılığı.
///
/// Etiket ve uzunluk sınırı gibi alan bilgileri `shared/vitrin_alanlari.json`
/// içinde yaşar; `lib/config/vitrin_alanlari.g.dart` oradan üretilir. Ekranlar
/// bu bilgileri elle yazmaz — yazdığında şema değişse bile o ekran eskisini
/// göstermeye devam eder ve iki istemci sessizce ayrışır.
///
/// 2026-09-09'da ölçülen örnek: SSS düzenleyicisi etiketleri ("SSS Üst
/// Başlık" vb.) ve uzunluk sınırlarını (40/90/200) elle yazıyordu. Web tarafı
/// aynı bilgileri şemadan okuyordu. Sayılar bugün tesadüfen tutuyordu; şema
/// değişse Flutter eski sınırda kalırdı ve esnaf iki yüzde farklı sınır görürdü.
///
/// Kilidi: `test/vitrin_alan_tek_kaynak_test.dart`
VitrinAlani vitrinAlan(String anahtar) {
  for (final alan in vitrinAlanlari) {
    if (alan.anahtar == anahtar) return alan;
  }
  throw ArgumentError('Vitrin alanı şemada yok: $anahtar');
}

/// Alanın kullanıcıya gösterilen etiketi.
String vitrinAlanEtiketi(String anahtar) => vitrinAlan(anahtar).etiket;

/// Alanın izin verilen en fazla karakter sayısı (şemada tanımlıysa).
int? vitrinAlanMaxUzunluk(String anahtar) => vitrinAlan(anahtar).maxUzunluk;
