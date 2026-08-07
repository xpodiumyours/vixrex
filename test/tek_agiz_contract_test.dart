import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tek ağız nöbetçisi — Flutter tarafı.
///
/// 2026-08-06'da "her yerde SEN" kararı verildi ve Next.js tarafı
/// çevrildi (public_web/tests/asistan-ton-contract.test.ts). Flutter
/// karşılama ekranı "siz" kipinde kaldı: aynı Vixrex, iki farklı ağız.
///
/// Casper 2026-08-07'de fark etti. 14 metin çevrildi; bu test kaymayı
/// yakalar.
void main() {
  final kok = Directory.current.path;

  /// "Siz" kipinin yaygın ekleri.
  final kaliplar = <String, RegExp>{
    '-iniz/-ınız (vitrininiz, bilgileriniz)': RegExp(
      r'[a-zçğıöşü](iniz|ınız|unuz|ünüz)\b',
    ),
    '-in/-ın emir kipi (ekleyin, paylaşın)': RegExp(
      r'[a-zçğıöşü](ayın|eyin|ıyın|iyin)\b',
    ),
    'misiniz / mısınız': RegExp(r'm[iı]s[iı]n[iı]z\b'),
    '-ebilirsiniz': RegExp(r'ebilirsiniz\b'),
  };

  /// Kullanıcıya gösterilen metinler: tek tırnaklı, boşluk içeren diziler.
  List<String> metinler(String kaynak) {
    return RegExp(
      r"'[^'\n]{12,}'",
    ).allMatches(kaynak).map((m) => m.group(0)!).where((m) {
      final i = m.substring(1, m.length - 1);
      if (i.startsWith('package:') || i.startsWith('assets/')) return false;
      if (i.startsWith('/') || i.startsWith('http')) return false;
      if (!i.contains(' ')) return false;
      return RegExp(r'[a-zçğıöşüA-ZÇĞİÖŞÜ]').hasMatch(i);
    }).toList();
  }

  final dosyalar = <File>[
    File('$kok/lib/screens/landing_screen.dart'),
    ...Directory(
      '$kok/lib/widgets/landing',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart')),
  ];

  for (final dosya in dosyalar) {
    final ad = dosya.uri.pathSegments.last;
    test('$ad içinde "siz" kipi yok', () {
      final kaynak = dosya.readAsStringSync();
      for (final metin in metinler(kaynak)) {
        for (final giris in kaliplar.entries) {
          expect(
            giris.value.hasMatch(metin),
            isFalse,
            reason:
                '"siz" kipi bulundu (${giris.key}):\n  $metin\n'
                'Vixrex her yerde "sen" der. Bkz. docs/tek-asistan-plani.md',
          );
        }
      }
    });
  }
}
