// shared/business_categories.json → lib/config/business_categories.g.dart
// Çalıştırma: dart run tool/business_categories_uret.dart

import 'dart:convert';
import 'dart:io';

String normalize(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ş', 's')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

String quote(String value) => "'${value.replaceAll("'", r"\'")}'";

void main() {
  final root = Directory.current.path;
  final source = File('$root/shared/business_categories.json');
  final decoded = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
  final categories =
      (decoded['categories'] as List).cast<Map<String, dynamic>>();

  if (categories.length != 19) {
    throw StateError('Kategori sözleşmesi tam 19 kayıt taşımalı.');
  }

  final ids = <String>{};
  final terms = <String, String>{};
  for (var index = 0; index < categories.length; index++) {
    final category = categories[index];
    final id = category['id'] as String;
    final order = category['order'] as int;
    final label = category['label'] as String;
    final aliases = (category['aliases'] as List).cast<String>();
    if (!ids.add(id) || order != index + 1) {
      throw StateError('Kategori ID veya sıra sözleşmesi geçersiz: $id');
    }
    for (final term in [id, label, ...aliases]) {
      final key = normalize(term);
      final owner = terms[key];
      if (owner != null && owner != id) {
        throw StateError('Kategori alias çakışması: $term ($owner / $id)');
      }
      terms[key] = id;
    }
  }

  final output =
      StringBuffer()
        ..writeln('// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.')
        ..writeln('// Kaynak: shared/business_categories.json')
        ..writeln('// Üreten: tool/business_categories_uret.dart')
        ..writeln()
        ..writeln('class BusinessCategoryCore {')
        ..writeln('  final String id;')
        ..writeln('  final int order;')
        ..writeln('  final String label;')
        ..writeln('  final List<String> aliases;')
        ..writeln()
        ..writeln('  const BusinessCategoryCore({')
        ..writeln('    required this.id,')
        ..writeln('    required this.order,')
        ..writeln('    required this.label,')
        ..writeln('    required this.aliases,')
        ..writeln('  });')
        ..writeln('}')
        ..writeln()
        ..writeln('const List<BusinessCategoryCore> businessCategories = [');

  for (final category in categories) {
    final aliases = (category['aliases'] as List)
        .cast<String>()
        .map(quote)
        .join(', ');
    output
      ..writeln('  BusinessCategoryCore(')
      ..writeln('    id: ${quote(category['id'] as String)},')
      ..writeln('    order: ${category['order']},')
      ..writeln('    label: ${quote(category['label'] as String)},')
      ..writeln('    aliases: [$aliases],')
      ..writeln('  ),');
  }

  output
    ..writeln('];')
    ..writeln()
    ..writeln(
      'final Map<String, BusinessCategoryCore> businessCategoryById = {',
    )
    ..writeln(
      '  for (final category in businessCategories) category.id: category,',
    )
    ..writeln('};')
    ..writeln()
    ..writeln('String normalizeBusinessCategoryTerm(String value) => value')
    ..writeln('    .trim()')
    ..writeln('    .toLowerCase()')
    ..writeln("    .replaceAll('ı', 'i')")
    ..writeln("    .replaceAll('ğ', 'g')")
    ..writeln("    .replaceAll('ü', 'u')")
    ..writeln("    .replaceAll('ş', 's')")
    ..writeln("    .replaceAll('ö', 'o')")
    ..writeln("    .replaceAll('ç', 'c');")
    ..writeln()
    ..writeln('final Map<String, String> _businessCategoryTerms = {')
    ..writeln('  for (final category in businessCategories)')
    ..writeln(
      '    for (final term in [category.id, category.label, ...category.aliases])',
    )
    ..writeln('      normalizeBusinessCategoryTerm(term): category.id,')
    ..writeln('};')
    ..writeln()
    ..writeln('String? resolveBusinessCategoryId(String value) {')
    ..writeln('  final normalized = normalizeBusinessCategoryTerm(value);')
    ..writeln('  if (normalized.isEmpty) return null;')
    ..writeln('  final exact = _businessCategoryTerms[normalized];')
    ..writeln('  if (exact != null) return exact;')
    ..writeln('  final partialTerms = _businessCategoryTerms.entries')
    ..writeln('      .where((entry) => normalized.contains(entry.key))')
    ..writeln('      .toList()')
    ..writeln('    ..sort((left, right) {')
    ..writeln('      final position = normalized.indexOf(left.key).compareTo(')
    ..writeln('        normalized.indexOf(right.key),')
    ..writeln('      );')
    ..writeln('      return position != 0')
    ..writeln('          ? position')
    ..writeln('          : right.key.length.compareTo(left.key.length);')
    ..writeln('    });')
    ..writeln('  for (final entry in partialTerms) {')
    ..writeln('    return entry.value;')
    ..writeln('  }')
    ..writeln('  return null;')
    ..writeln('}');

  File(
    '$root/lib/config/business_categories.g.dart',
  ).writeAsStringSync(output.toString());
  stdout.writeln('Üretildi: lib/config/business_categories.g.dart');
}
