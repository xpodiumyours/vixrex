import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hesap bağlama nöbetçisi (docs/kok-neden-arastirmasi.md — kimlik kökü).
///
/// Uygulama açılışta anonim oturum kuruyor; vitrin ilk andan sahipli
/// oluyor. Ama anonim hesap CİHAZA bağlıdır — esnaf telefonunu
/// değiştirse ya da tarayıcı verisini silse vitrinine bir daha erişemez.
void main() {
  final kok = Directory.current.path;
  String oku(String yol) => File('$kok/$yol').readAsStringSync();

  test('bağlama mevcut hesabı KORUYOR, yenisine geçirmiyor', () {
    final servis = oku('lib/services/auth_service.dart');
    final govde = servis.substring(
      servis.indexOf('Future<Result<void>> hesabiGoogleaBagla()'),
      servis.indexOf('Future<Result<AuthResponse>> signInWithGoogle()'),
    );

    // signInWithIdToken YENİ hesaba geçirir; anonim hesaptaki vitrin
    // sahipsiz kalır. Bağlama linkIdentityWithIdToken kullanmalı.
    expect(govde, contains('linkIdentityWithIdToken'));
    expect(
      govde.contains('signInWithIdToken'),
      isFalse,
      reason: 'Bağlama yeni hesaba geçirirse vitrin sahipsiz kalır.',
    );

    // Zaten kalıcı hesabı olana tekrar sorulmamalı.
    expect(govde, contains('!kullanici.isAnonymous'));
  });

  test('bağlama adımı yayından SONRA çıkıyor', () {
    final chat = oku('lib/screens/vixrex_onboarding_chat_screen.dart');
    // Kurulumun başında değil, done adımında. Yayına kadar korunacak
    // bir şey yok; kimseyi formla karşılamayız.
    final doneBlok = chat.substring(
      chat.indexOf('if (_step == _OnboardingStep.done)'),
    );
    expect(doneBlok, contains('_hesapKorumasiz'));
    expect(doneBlok, contains('Google ile bağla'));
  });
}
