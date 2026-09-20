// shared/renkler.json → lib/theme/renkler.g.dart
//                     → public_web/src/app/globals.css (--color-lp-* satirlari)
// Çalıştırma: dart run tool/renk_uret.dart

import 'dart:convert';
import 'dart:io';

final RegExp _hexDeseni = RegExp(r'^#[0-9A-F]{6}$');

void main() {
  final root = Directory.current.path;
  final source = File('$root/shared/renkler.json');
  final decoded = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
  final renkler = (decoded['renkler'] as List).cast<Map<String, dynamic>>();

  final anahtarlar = <String>{};
  for (final renk in renkler) {
    final anahtar = renk['anahtar'] as String;
    final hex = renk['hex'] as String;
    if (!anahtarlar.add(anahtar)) {
      throw StateError('Renk anahtarı yinelendi: $anahtar');
    }
    if (!_hexDeseni.hasMatch(hex)) {
      throw StateError('Renk büyük harfli #RRGGBB olmalı: $anahtar = $hex');
    }
  }

  final buffer =
      StringBuffer()
        ..writeln('// shared/renkler.json dosyasından üretildi.')
        ..writeln('// ELLE DÜZENLENMEZ — dart run tool/renk_uret.dart')
        ..writeln()
        ..writeln("import 'package:flutter/material.dart';")
        ..writeln()
        ..writeln(
          '/// Flutter paneli ile Next.js landing yüzeyinin ortak renkleri.',
        )
        ..writeln('abstract final class OrtakRenkler {');
  for (final renk in renkler) {
    final dartAdi = renk['dartAdi'] as String;
    final hex = (renk['hex'] as String).substring(1);
    buffer.writeln('  static const Color $dartAdi = Color(0xFF$hex);');
  }
  buffer.writeln('}');

  File('$root/lib/theme/renkler.g.dart').writeAsStringSync(buffer.toString());

  final cssDosyasi = File('$root/public_web/src/app/globals.css');
  var css = cssDosyasi.readAsStringSync();
  for (final renk in renkler) {
    final degisken = renk['cssDegisken'] as String;
    final hex = renk['hex'] as String;
    final satirDeseni = RegExp(
      '(\\s*)${RegExp.escape(degisken)}:\\s*#[0-9A-Fa-f]{3,8};',
    );
    if (!satirDeseni.hasMatch(css)) {
      throw StateError('globals.css içinde bulunamadı: $degisken');
    }
    css = css.replaceAllMapped(satirDeseni, (m) => '${m[1]}$degisken: $hex;');
  }
  cssDosyasi.writeAsStringSync(css);

  stdout.writeln('ortak renk sayısı: ${renkler.length}');
}
