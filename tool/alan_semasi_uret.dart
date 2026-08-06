// shared/vitrin_alanlari.json → lib/config/vitrin_alanlari.g.dart
//
// NEDEN VAR
// Alan tanımı iki yerde ayrı ayrı tutuluyordu: Next.js'te 44 alanlık şema,
// Flutter'da 6 adımlık elle yazılmış liste. Aynı vitrin için iki farklı
// tanım, iki farklı "sırada ne var" cevabı. Kategori sorulmamasının sebebi
// de buydu — Flutter'ın listesinde kategori yoktu.
//
// Artık tek kaynak var: public_web/src/lib/vitrinFieldSchema.ts
// Oradan shared/vitrin_alanlari.json çıkar, buradan Dart üretilir.
//
// ÇALIŞTIRMA
//   dart run tool/alan_semasi_uret.dart
//
// Üretilen dosya ELLE DÜZENLENMEZ. Değişiklik şemaya yazılır, sonra bu
// betik tekrar çalıştırılır. Sözleşme testi ikisinin ayrışmasını yakalar.

import 'dart:convert';
import 'dart:io';

void main() {
  final kok = Directory.current.path;
  final kaynak = File('$kok/shared/vitrin_alanlari.json');

  if (!kaynak.existsSync()) {
    stderr.writeln('shared/vitrin_alanlari.json yok.');
    stderr.writeln('Önce: cd public_web && npx tsx ../tool/sema_disa_aktar.ts');
    exit(1);
  }

  final veri = jsonDecode(kaynak.readAsStringSync()) as Map<String, dynamic>;
  final alanlar = (veri['alanlar'] as List).cast<Map<String, dynamic>>();

  final tampon = StringBuffer()
    ..writeln('// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.')
    ..writeln('//')
    ..writeln('// Kaynak : public_web/src/lib/vitrinFieldSchema.ts')
    ..writeln('// Üreten : tool/alan_semasi_uret.dart')
    ..writeln('//')
    ..writeln('// Vitrinin düzenlenebilir alanlarının tek tanımı. Next.js ve')
    ..writeln('// Flutter aynı listeyi kullanır; "sırada ne var" sorusuna iki')
    ..writeln('// taraf da buradan cevap verir.')
    ..writeln('')
    ..writeln('class VitrinAlani {')
    ..writeln('  final String anahtar;')
    ..writeln('  final String tip;')
    ..writeln('  final String etiket;')
    ..writeln('  final String kolon;')
    ..writeln('  final String bolum;')
    ..writeln('  final bool zorunlu;')
    ..writeln('  final int? minUzunluk;')
    ..writeln('  final int? maxUzunluk;')
    ..writeln('  final List<String>? secenekler;')
    ..writeln('  final String? ipucu;')
    ..writeln('')
    ..writeln('  const VitrinAlani({')
    ..writeln('    required this.anahtar,')
    ..writeln('    required this.tip,')
    ..writeln('    required this.etiket,')
    ..writeln('    required this.kolon,')
    ..writeln('    required this.bolum,')
    ..writeln('    this.zorunlu = false,')
    ..writeln('    this.minUzunluk,')
    ..writeln('    this.maxUzunluk,')
    ..writeln('    this.secenekler,')
    ..writeln('    this.ipucu,')
    ..writeln('  });')
    ..writeln('}')
    ..writeln('')
    ..writeln('const List<VitrinAlani> vitrinAlanlari = [');

  String? metin(Object? d) =>
      d == null ? null : "'${d.toString().replaceAll("'", r"\'")}'";

  for (final a in alanlar) {
    tampon.writeln('  VitrinAlani(');
    tampon.writeln("    anahtar: ${metin(a['anahtar'])},");
    tampon.writeln("    tip: ${metin(a['tip'])},");
    tampon.writeln("    etiket: ${metin(a['etiket'])},");
    tampon.writeln("    kolon: ${metin(a['kolon'])},");
    tampon.writeln("    bolum: ${metin(a['bolum'])},");
    if (a['zorunlu'] == true) tampon.writeln('    zorunlu: true,');
    if (a['minUzunluk'] != null) {
      tampon.writeln("    minUzunluk: ${a['minUzunluk']},");
    }
    if (a['maxUzunluk'] != null) {
      tampon.writeln("    maxUzunluk: ${a['maxUzunluk']},");
    }
    if (a['secenekler'] != null) {
      final ler = (a['secenekler'] as List).map(metin).join(', ');
      tampon.writeln('    secenekler: [$ler],');
    }
    if (a['ipucu'] != null) tampon.writeln("    ipucu: ${metin(a['ipucu'])},");
    tampon.writeln('  ),');
  }

  tampon
    ..writeln('];')
    ..writeln('')
    ..writeln('/// Yayın için doldurulması ZORUNLU alanlar — şemadan gelir.')
    ..writeln('/// Elle liste tutulmaz; şemada zorunlu işaretlemek yeter.')
    ..writeln('final List<VitrinAlani> zorunluAlanlar =')
    ..writeln('    vitrinAlanlari.where((a) => a.zorunlu).toList();')
    ..writeln('')
    ..writeln('/// Anahtardan alana hızlı erişim.')
    ..writeln('final Map<String, VitrinAlani> alanAnahtarla = {')
    ..writeln('  for (final a in vitrinAlanlari) a.anahtar: a,')
    ..writeln('};');

  final hedef = File('$kok/lib/config/vitrin_alanlari.g.dart');
  hedef.writeAsStringSync(tampon.toString());

  final zorunlu = alanlar.where((a) => a['zorunlu'] == true).length;
  stdout.writeln('Üretildi: lib/config/vitrin_alanlari.g.dart');
  stdout.writeln('  alan sayısı : ${alanlar.length}');
  stdout.writeln('  zorunlu     : $zorunlu');
}
