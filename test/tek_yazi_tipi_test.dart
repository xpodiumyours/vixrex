import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Yazı tipi tutarlılığının bekçisi.
///
/// 2026-08-07: uygulama teması 'Helvetica' diyordu ama o yazı tipi
/// uygulamayla GELMİYORDU — her cihaz kendi bulduğuna düşüyordu
/// (Android'de Roboto, tarayıcıda Arial). Vitrin tarafı (Next.js) zaten
/// Outfit kullanıyordu. Aynı ürünün iki yüzü iki ayrı marka gibi
/// görünüyordu.
///
/// Casper: "her ekranda aynı tarz yazı tipi olmalı".
void main() {
  final kok = Directory.current.path;
  String oku(String yol) => File('$kok/$yol').readAsStringSync();

  test('yazı tipi tek yerde tanımlı ve uygulamayla geliyor', () {
    final main = oku('lib/main.dart');
    expect(main, contains("fontFamily: 'Outfit'"));

    // Yalnız temada tanımlı olmalı; ekranlar kendi yazı tipini seçmemeli.
    final ekranlar = Directory('$kok/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('main.dart'));

    final sapanlar = <String>[];
    for (final dosya in ekranlar) {
      if (dosya.readAsStringSync().contains('fontFamily')) {
        sapanlar.add(dosya.path.split('lib').last);
      }
    }
    expect(
      sapanlar,
      isEmpty,
      reason:
          'Bu dosyalar kendi yazı tipini belirliyor; tema dışına '
          'çıkmamalı: ${sapanlar.join(", ")}',
    );
  });

  test('Outfit dosyaları depoda ve pubspec\'te kayıtlı', () {
    final pubspec = oku('pubspec.yaml');
    expect(pubspec, contains('family: Outfit'));

    for (final agirlik in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final dosya = File('$kok/assets/fonts/Outfit-$agirlik.ttf');
      expect(dosya.existsSync(), isTrue, reason: '$agirlik dosyası yok');
      // Boş ya da hata sayfası indirilmiş olmasın.
      expect(dosya.lengthSync(), greaterThan(10000));
    }
  });
}
