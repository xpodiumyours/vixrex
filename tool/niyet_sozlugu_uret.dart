// shared/vixrex_niyet_sozlugu.json → lib/config/vixrex_niyet_sozlugu.g.dart
// Çalıştırma: dart run tool/niyet_sozlugu_uret.dart
//
// Amaç: Next.js'in doğrudan okuduğu shared niyet sözlüğü ile Flutter'ın
// generated kopyasının elle ayrışmasını engellemek. Üretim sırasında 46 alanın
// anahtar/tip/etiket/kolon/bölüm sözleşmesi shared/vitrin_alanlari.json ile de
// karşılaştırılır. Runtime davranışı üreticiye taşınmaz; yalnız veri üretilir.

import 'dart:convert';
import 'dart:io';

String _dartString(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll(r'$', r'\$');
  return "'$escaped'";
}

List<Map<String, dynamic>> _alanlar(File file) {
  if (!file.existsSync()) {
    throw StateError('Kaynak bulunamadı: ${file.path}');
  }
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (decoded['alanlar'] as List).cast<Map<String, dynamic>>();
}

void main() {
  final root = Directory.current.path;
  final niyetFile = File('$root/shared/vixrex_niyet_sozlugu.json');
  final fieldFile = File('$root/shared/vitrin_alanlari.json');
  final niyetAlanlari = _alanlar(niyetFile);
  final fieldAlanlari = _alanlar(fieldFile);

  if (niyetAlanlari.length != 46 || fieldAlanlari.length != 46) {
    throw StateError(
      'Vixrex alan sözleşmesi 46 kayıt taşımalı: '
      'niyet=${niyetAlanlari.length}, alan=${fieldAlanlari.length}',
    );
  }

  final fieldByKey = <String, Map<String, dynamic>>{};
  for (final field in fieldAlanlari) {
    final key = field['anahtar'] as String?;
    if (key == null || key.isEmpty || fieldByKey.containsKey(key)) {
      throw StateError('Alan şemasında geçersiz/tekrarlı anahtar: $key');
    }
    fieldByKey[key] = field;
  }

  final seen = <String>{};
  for (final intent in niyetAlanlari) {
    final key = intent['anahtar'] as String?;
    if (key == null || key.isEmpty || !seen.add(key)) {
      throw StateError('Niyet sözlüğünde geçersiz/tekrarlı anahtar: $key');
    }
    final field = fieldByKey[key];
    if (field == null) {
      throw StateError('Niyet anahtarı 46 alan şemasında yok: $key');
    }
    for (final property in ['etiket', 'tip', 'kolon', 'bolum']) {
      if (intent[property] != field[property]) {
        throw StateError(
          '$key için $property drift: '
          'niyet=${intent[property]} alan=${field[property]}',
        );
      }
    }
    final aliases = (intent['esAnlamlar'] as List?)?.cast<String>() ?? const [];
    final examples =
        (intent['ornekIfadeler'] as List?)?.cast<String>() ?? const [];
    if (aliases.isEmpty || examples.isEmpty) {
      throw StateError('$key için esAnlamlar/ornekIfadeler boş olamaz.');
    }
  }

  if (seen.length != fieldByKey.length || !seen.containsAll(fieldByKey.keys)) {
    throw StateError('Niyet sözlüğü ile 46 alan anahtar seti birebir değil.');
  }

  final out = StringBuffer()
    ..writeln('// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.')
    ..writeln('// Kaynak : shared/vixrex_niyet_sozlugu.json')
    ..writeln()
    ..writeln('class VixrexNiyetAlan {')
    ..writeln('  final String anahtar;')
    ..writeln('  final String etiket;')
    ..writeln('  final String tip;')
    ..writeln('  final String kolon;')
    ..writeln('  final String bolum;')
    ..writeln('  final String beklenenVeriTipi;')
    ..writeln('  final List<String> esAnlamlar;')
    ..writeln('  final List<String> ornekIfadeler;')
    ..writeln('  const VixrexNiyetAlan({required this.anahtar,required this.etiket,required this.tip,required this.kolon,required this.bolum,required this.beklenenVeriTipi,required this.esAnlamlar,required this.ornekIfadeler,});')
    ..writeln('}')
    ..writeln('const List<VixrexNiyetAlan> vixrexNiyetSozlugu = [');

  for (final intent in niyetAlanlari) {
    final aliases = (intent['esAnlamlar'] as List).cast<String>();
    final examples = (intent['ornekIfadeler'] as List).cast<String>();
    out
      ..writeln('  VixrexNiyetAlan(')
      ..writeln('    anahtar: ${_dartString(intent['anahtar'] as String)},')
      ..writeln('    etiket: ${_dartString(intent['etiket'] as String)},')
      ..writeln('    tip: ${_dartString(intent['tip'] as String)},')
      ..writeln('    kolon: ${_dartString(intent['kolon'] as String)},')
      ..writeln('    bolum: ${_dartString(intent['bolum'] as String)},')
      ..writeln(
        '    beklenenVeriTipi: ${_dartString(intent['beklenenVeriTipi'] as String)},',
      )
      ..writeln(
        '    esAnlamlar: [${aliases.map(_dartString).join(', ')}],',
      )
      ..writeln(
        '    ornekIfadeler: [${examples.map(_dartString).join(', ')}],',
      )
      ..writeln('  ),');
  }

  out
    ..writeln('];')
    ..write(
      'final Map<String, VixrexNiyetAlan> vixrexNiyetAlanByAnahtar = { for (final a in vixrexNiyetSozlugu) a.anahtar: a, };',
    );

  File('$root/lib/config/vixrex_niyet_sozlugu.g.dart')
      .writeAsStringSync(out.toString());
  stdout.writeln('Üretildi: lib/config/vixrex_niyet_sozlugu.g.dart');
  stdout.writeln('  alan sayısı: ${niyetAlanlari.length}');
}
