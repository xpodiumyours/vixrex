import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hakkımızda / SSS nöbetçisi.
///
/// 2026-08-08 tespiti: manuel panelde Hakkımızda ve SSS doldurulup
/// yayınlanıyor ama vitrinde görünmüyordu. Zincir şurada kopuyordu:
///
///   Flutter modeli          → alanlar var
///   Panel formu             → düzenleme ekranı var
///   Yayın yükü              → about_title, faq_items gönderiliyor
///   create_store_with_token → BU SÜTUNLARI YAZMIYOR   ← kopma
///   update_store_with_token → yazıyor
///   Vitrin çizimi           → about_title boşsa bölümü hiç çizmiyor
///
/// İlk yayında girilen veri sessizce kayboluyordu.
void main() {
  final kok = Directory.current.path;

  test('ilk yayından sonra bölümler ayrıca yazılıyor', () {
    final servis =
        File('$kok/lib/services/store_publish_service.dart').readAsStringSync();

    final olusturma = servis.substring(
      servis.indexOf("'create_store_with_token'"),
      servis.indexOf('} on PostgrestException catch'),
    );

    expect(
      olusturma,
      contains('_updateStoreWithToken(client, data, slug, editToken)'),
      reason:
          'İlk yayından sonra güncelleme çağrılmazsa Hakkımızda ve '
          'SSS sessizce kaybolur.',
    );
  });

  test('yayın yükü bölüm alanlarını taşıyor', () {
    final yuk =
        File(
          '$kok/lib/services/store_publish_payload_builder.dart',
        ).readAsStringSync();

    for (final alan in [
      'about_title',
      'about_kicker',
      'about_values',
      'faq_items',
      'gallery_section_title',
    ]) {
      expect(
        yuk,
        contains("'$alan'"),
        reason: '$alan yükte yoksa hiçbir yol onu yazamaz.',
      );
    }
  });
}
