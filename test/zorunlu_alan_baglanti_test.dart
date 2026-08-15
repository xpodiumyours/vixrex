import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

/// Faz F (Tek Asistan planı) "sapma testi" — Dart tarafı.
///
/// PLAN.md: "CI'da sapma testi: iki taraf aynı taslak verisine aynı
/// 'sıradaki alan' cevabını vermeli." Dart ve TypeScript aynı süreçte
/// çalışmadığı için gerçek çapraz-dil çağrısı yapılmıyor; bunun yerine
/// her iki taraf ayrı ayrı, KENDİ şema-bağlantısının eksiksiz olduğunu
/// kanıtlıyor. TS tarafındaki eşleniği:
/// `public_web/tests/zorunlu-alan-baglanti.test.ts`.
///
/// Somut risk: `VixRexProfileSnapshot._alanDolu`'nun switch'i, şemada
/// `zorunlu: true` işaretli ama switch'e case olarak eklenmemiş bir alanı
/// SESSİZCE dolu sayar (`default: return true`). Şemaya yeni zorunlu alan
/// eklenip buraya bağlanmazsa, kurulum akışı o alanı hiç sormaz — tam da
/// il/ilçe'nin bu turda düzeltilen hâli. Bu test, şemadaki HER zorunlu
/// alanın gerçekten ayrı ele alındığını — default fallback'e düşmediğini —
/// kanıtlar.
void main() {
  test("şemadaki her zorunlu alan _alanDolu'da ayrı ele alınır, "
      'sessizce dolu sayılmaz', () {
    final tamStore = StoreData().copyWith(
      name: 'Test Store',
      kategori: 'Kuaför',
      whatsapp: '05551234567',
      address: 'Test Adres',
      provinceName: 'Istanbul',
      districtName: 'Kadikoy',
    );

    for (final alan in zorunluAlanlar) {
      final eksikStore = _tekAlaniBosalt(tamStore, alan.anahtar);
      final snapshot = VixRexProfileSnapshot.from(eksikStore, null);

      expect(
        snapshot.sonrakiEksikZorunluAlan?.anahtar,
        alan.anahtar,
        reason:
            '"${alan.anahtar}" alanı boşken sonrakiEksikZorunluAlan onu '
            'döndürmedi — _alanDolu switch\'inde bu alan için ayrı bir '
            "case yok, default (dolu sayılan) fallback'e düşüyor "
            'olabilir. Şemaya yeni zorunlu alan eklerken '
            '_alanDolu ve nextMissingField switch\'lerine de case '
            'eklenmeli.',
      );
    }
  });
}

/// Diğer her şey doluyken yalnız [anahtar]'ı boşaltır.
StoreData _tekAlaniBosalt(StoreData dolu, String anahtar) {
  switch (anahtar) {
    case 'isletmeAdi':
      return dolu.copyWith(name: '');
    case 'kategori':
      return dolu.copyWith(kategori: '');
    case 'whatsapp':
      return dolu.copyWith(whatsapp: '');
    case 'adres':
      return dolu.copyWith(address: '');
    case 'il':
      return dolu.copyWith(provinceName: '');
    case 'ilce':
      return dolu.copyWith(districtName: '');
    default:
      throw StateError(
        '"$anahtar" için _tekAlaniBosalt bilmiyor — bu test dosyası yeni '
        'zorunlu alanla birlikte güncellenmeli (bkz. dosya başı notu: '
        'sessiz "dolu sayma" riskini bu test yakalar, ama yeni alanı '
        "burada boşaltmayı bilmezse testin kendisi anlamsızlaşır).",
      );
  }
}
