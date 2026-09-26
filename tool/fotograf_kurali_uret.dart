// shared/product_image_policy.json → lib/config/product_image_policy.g.dart
// Çalıştırma: dart run tool/fotograf_kurali_uret.dart
//
// NEDEN VAR
// Ürün fotoğrafı sayıları iki yerde ayrı ayrı tutuluyordu: Next.js'te
// productImagePolicy.ts sabitleri, Flutter'da ProductImagePolicy sabitleri.
// Aynı kural için iki farklı "doğru sayı" cevabı. Artık tek kaynak var:
// shared/product_image_policy.json. Bu betik oradan Dart üretir.
// Web tarafı doğrudan JSON'u okur (productAttributeSchema.ts desenindeki gibi).
//
// Üretilen dosya ELLE DÜZENLENMEZ. Sayı değişince önce JSON güncellenir,
// sonra bu betik tekrar çalıştırılır.

import 'dart:convert';
import 'dart:io';

void main() {
  final kok = Directory.current.path;
  final kaynak = File('$kok/shared/product_image_policy.json');
  if (!kaynak.existsSync()) {
    stderr.writeln('shared/product_image_policy.json yok.');
    exit(1);
  }

  final veri = jsonDecode(kaynak.readAsStringSync()) as Map<String, dynamic>;

  int sayi(Object? deger, String ad) {
    if (deger is! int || deger <= 0) {
      stderr.writeln('product_image_policy.json: "$ad" pozitif sayi olmali.');
      exit(1);
    }
    return deger;
  }

  final minImages = sayi(veri['minImages'], 'minImages');
  final maxImages = sayi(veri['maxImages'], 'maxImages');
  final maxSourceMegabytes = sayi(
    veri['maxSourceMegabytes'],
    'maxSourceMegabytes',
  );
  final minSourceShortEdge = sayi(
    veri['minSourceShortEdge'],
    'minSourceShortEdge',
  );
  if (minImages > maxImages) {
    stderr.writeln(
      'product_image_policy.json: minImages, maxImages tan buyuk olamaz.',
    );
    exit(1);
  }

  final tampon =
      StringBuffer()
        ..writeln('// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.')
        ..writeln('//')
        ..writeln('// Kaynak : shared/product_image_policy.json')
        ..writeln('// Üreten : tool/fotograf_kurali_uret.dart')
        ..writeln('//')
        ..writeln(
          '// Ürün fotoğrafı sayıları ve kaynak kalite sınırları (tek kaynak).',
        )
        ..writeln('')
        ..writeln('class ProductImagePolicyValues {')
        ..writeln('  const ProductImagePolicyValues._();')
        ..writeln('')
        ..writeln('  static const int minImages = $minImages;')
        ..writeln('  static const int maxImages = $maxImages;')
        ..writeln(
          '  static const int maxSourceMegabytes = $maxSourceMegabytes;',
        )
        ..writeln(
          '  static const int maxSourceBytes = maxSourceMegabytes * 1024 * 1024;',
        )
        ..writeln(
          '  static const int minSourceShortEdge = $minSourceShortEdge;',
        )
        ..writeln('}');

  final hedef = File('$kok/lib/config/product_image_policy.g.dart');
  hedef.writeAsStringSync(tampon.toString());
  stdout.writeln('Üretildi: lib/config/product_image_policy.g.dart');
  stdout.writeln('  en az     : $minImages');
  stdout.writeln('  en fazla  : $maxImages');
  stdout.writeln('  kaynak MB : $maxSourceMegabytes');
  stdout.writeln('  kisa kenar: $minSourceShortEdge px');
}
