import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kimlik kökü nöbetçisi (docs/kok-neden-arastirmasi.md).
///
/// 2026-08-07 sayımı: buluttaki 128 vitrinin 128'i sahipsizdi. Sahiplik
/// politikaları veritabanında doğru yazılmıştı ama hiç eşleşmiyordu;
/// kimlik gerçekte tarayıcının hafızasındaydı. Hayalet vitrin, silinemeyen
/// vitrin ve sahipsiz çöp kayıtlar hep bu delikten çıkıyordu.
///
/// Uygulama artık açılışta oturum güvenceye alıyor.
void main() {
  final kok = Directory.current.path;
  final main = File('$kok/lib/main.dart').readAsStringSync();

  test('açılışta oturum güvenceye alınıyor', () {
    expect(main, contains('_oturumuGuvenceyeAl()'));
    expect(main, contains('signInAnonymously()'));
  });

  test('mevcut oturum varsa yenisi açılmıyor', () {
    // Her açılışta yeni anonim kullanıcı yaratılırsa esnaf her seferinde
    // başka biri olur ve vitrinine erişemez.
    expect(main, contains('if (auth.currentSession != null) return;'));
  });

  test('oturum kurulamazsa uygulama çalışmaya devam ediyor', () {
    final govde = main.substring(
      main.indexOf('Future<void> _oturumuGuvenceyeAl()'),
    );
    // Bu adım bir kapı değil: hata yutulur, akış durmaz.
    expect(govde.contains('catch'), isTrue);
    expect(
      govde.substring(0, govde.indexOf('\n}')).contains('throw'),
      isFalse,
      reason: 'Oturum kurulamazsa uygulama açılmamazlık etmemeli.',
    );
  });
}
