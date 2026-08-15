import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';

/// ADR 0001 madde 4'ün sınırını kilitler: Flutter'ın 5 kalite kalemi ile
/// şemadaki 7 `kalite` alanı BİLİNÇLİ olarak birleştirilmedi — "meşru
/// uzmanlaşma". Bu test o sınırın kazara bozulmadığını (ör. bir kalem
/// sessizce şemayla aynı anahtarı kullanmaya başlarsa veya "cover"ın tek
/// gerçek örtüşmesi bozulursa) yakalar.
///
/// Faz F (Tek Asistan planı) — bkz. lib/services/vixrex_guidance_service.dart
/// başındaki eşleme tablosu ve docs/adr/0001-vixrex-core-omurga-ve-uzman-beyinler.md.
void main() {
  test('kalite kalemi anahtarları şemanın alan anahtarlarıyla ÇAKIŞMAZ', () {
    // "cover" ve "kapakGorseli" farklı anahtarlar (id vs şema anahtarı) —
    // bu bilinçli; testin amacı gallery/catalog/auto_fill/description gibi
    // Flutter'a özgü kalemlerin şemada AYNI ANAHTARLA yeniden ortaya
    // çıkmamasını doğrulamak. Çıkarsa, biri diğerini bilmeden aynı kavramı
    // iki kez tanımlamış demektir — tam ADR 0001'in uyardığı risk.
    final kaliteKalemleriAnahtarlari =
        VixRexGuidanceService.qualityItems(null).map((k) => k.id).toSet();
    final semaAnahtarlari = vitrinAlanlari.map((a) => a.anahtar).toSet();

    final cakisanlar = kaliteKalemleriAnahtarlari.intersection(semaAnahtarlari);
    expect(
      cakisanlar,
      isEmpty,
      reason:
          'Kalite kalemi id\'leri (${kaliteKalemleriAnahtarlari.join(", ")}) '
          've şema anahtarları (${semaAnahtarlari.join(", ")}) çakışıyor: '
          '${cakisanlar.join(", ")}. Bu, ADR 0001\'in belgelediği eşleme '
          'tablosunun güncellenmesi gerektiği anlamına gelebilir.',
    );
  });

  test('kalite kalemi sayısı beşte sabit — değişirse belge güncellenmeli', () {
    // Sayı elle kilitlenir çünkü bu liste, aksine, ŞEMADAN türemiyor
    // (bilinçli tasarım kararı gereği) — artması/azalması sessiz
    // olmamalı, vixrex_guidance_service.dart'taki eşleme tablosu da
    // güncellenmeli.
    expect(VixRexGuidanceService.qualityItems(null), hasLength(5));
  });
}
