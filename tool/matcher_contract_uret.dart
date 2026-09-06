// shared/vixrex_matcher_contract.json → lib/config/vixrex_matcher_contract.g.dart
// Çalıştırma: dart run tool/matcher_contract_uret.dart

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

void main() {
  final root = Directory.current.path;
  final source = File('$root/shared/vixrex_matcher_contract.json');
  if (!source.existsSync()) {
    throw StateError('Kaynak bulunamadı: ${source.path}');
  }

  final decoded = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
  final minLen = decoded['minInflectedAliasLength'] as int?;
  final suffixes =
      (decoded['safeSuffixes'] as List?)?.cast<String>() ?? const <String>[];
  final exactRaw =
      (decoded['exactFormsByField'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};

  if (minLen == null || minLen < 1) {
    throw StateError('minInflectedAliasLength geçersiz.');
  }
  if (suffixes.isEmpty || suffixes.toSet().length != suffixes.length) {
    throw StateError('safeSuffixes boş veya tekrarlı.');
  }

  final exact = <String, List<String>>{};
  for (final entry in exactRaw.entries) {
    final values = (entry.value as List?)?.cast<String>() ?? const <String>[];
    if (entry.key.trim().isEmpty ||
        values.isEmpty ||
        values.any((v) => v.trim().isEmpty)) {
      throw StateError('exactFormsByField geçersiz: ${entry.key}');
    }
    exact[entry.key] = values;
  }

  final out =
      StringBuffer()
        ..writeln('// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.')
        ..writeln('// Kaynak: shared/vixrex_matcher_contract.json')
        ..writeln()
        ..writeln('const int vixrexMatcherMinInflectedAliasLength = $minLen;')
        ..writeln(
          'const List<String> vixrexMatcherSafeSuffixes = [${suffixes.map(_dartString).join(', ')}];',
        )
        ..writeln(
          'const Map<String, List<String>> vixrexMatcherExactFormsByField = {',
        );

  for (final entry in exact.entries) {
    out.writeln(
      '  ${_dartString(entry.key)}: [${entry.value.map(_dartString).join(', ')}],',
    );
  }
  out.writeln('};');

  final output = File('$root/lib/config/vixrex_matcher_contract.g.dart');
  output.writeAsStringSync(out.toString());
  final formatResult = Process.runSync('dart', ['format', output.path]);
  if (formatResult.exitCode != 0) {
    throw StateError('Üretilen matcher kontratı biçimlendirilemedi: ${formatResult.stderr}');
  }
  stdout.writeln('Üretildi: lib/config/vixrex_matcher_contract.g.dart');
}
