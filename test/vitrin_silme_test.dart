import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Vitrin silme nöbetçisi.
///
/// 2026-08-07: silme önce buluttaki kaydı siliyordu ve slug yoksa hata
/// fırlatıp yerel veriyi HİÇ temizlemiyordu. Hiç yayınlanmamış ya da
/// bulutta zaten silinmiş bir vitrin uygulamadan silinemiyordu;
/// karşılama ekranı sonsuza kadar "Kayıtlı Vitrinimi Düzenle" diyordu.
void main() {
  test('bulutta karşılığı olmayan vitrin yerelden silinebilir', () {
    final kaynak =
        File(
          '${Directory.current.path}/lib/controllers/store_editor_controller.dart',
        ).readAsStringSync();

    final silme = kaynak.substring(
      kaynak.indexOf('Future<void> deleteVitrin()'),
      kaynak.indexOf('void addGalleryUrl('),
    );

    // Slug yoksa hata fırlatılmamalı — bulutta silinecek bir şey yok.
    expect(
      silme.contains("throw 'Silinecek vitrin bilgisi bulunamadı.'"),
      isFalse,
      reason: 'Slug yokken hata fırlatılırsa yerel kayıt asla temizlenmez.',
    );

    // Bulut silme yalnız slug varken denenmeli.
    expect(silme, contains('if (slug.isNotEmpty)'));

    // Yerel temizlik her iki yolda da çalışmalı.
    expect(silme, contains('storage.clearVitrinData()'));
  });
}
