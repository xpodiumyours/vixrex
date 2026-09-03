import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Akış 2 paritesi (2026-09-03): kiralama TEK köprüden gider.
///
/// Karar: `/rent-demo` web köprüsü kanonik kiralama yoludur (orada zaten
/// var — reCAPTCHA + sahip-oturumu zinciriyle). Flutter'a ikinci bir
/// kiralama yazılmaz: karttaki "Kirala" yalnız köprüye delege eder,
/// hesaplı yol bile backend RPC'dir (`rent_demo_for_account`), UI değil.
///
/// Bunlar DAVRANIŞ değil VARLIK testleridir (bkz.
/// kurulum_akisi_contract_test.dart): biri köprüyü atlayıp Flutter'a
/// paralel bir kiralama gömerse test kırmızı olur.
void main() {
  final root = Directory.current.path;
  String read(String path) => File('$root/$path').readAsStringSync();

  late final String explore = read('lib/screens/explore_screen.dart');
  late final String kart = read('lib/widgets/vitrin_store_card.dart');
  late final String router = read('lib/config/app_router.dart');
  late final String kopru = read('lib/config/public_site_config.dart');
  late final String servis = read('lib/services/demo_rental_service.dart');
  late final String depo = read(
    'lib/repositories/vitrin_sahiplik_repository.dart',
  );

  group('Kirala tek kapıdan köprüye gider', () {
    test('karttaki Kirala yalnız geri-cagirir, kendi kiralamaz', () {
      expect(kart, contains("'Kirala'"));
      expect(kart, contains('onRentPressed'));
      // Kart RPC bilmez, URL kurmaz, captcha sormaz.
      expect(kart, isNot(contains('rent_demo_for_account')));
      expect(kart, isNot(contains('navigateToRentDemo')));
      expect(kart, isNot(contains('buildRentDemoLink')));
      expect(kart, isNot(contains('recaptcha')));
    });

    test('kesfet kirala dokunusunu kopru yonlendiricisine verir', () {
      expect(explore, contains('onRentPressed'));
      expect(explore, contains('navigateToRentDemo'));
      // Keşfet'te kiralama mantığı yok — yalnız kiralık şablonlarda kapı açılır.
      expect(explore, contains('store.isRentalTemplate'));
      expect(explore, isNot(contains('rent_demo_for_account')));
      expect(explore, isNot(contains('recaptcha')));
    });

    test('kopru URL tek builderdan kurulur, hardcode dagilmaz', () {
      expect(kopru, contains("'/rent-demo'"));
      expect(kopru, contains('buildRentDemoLink'));
      // Yönlendirici URL'yi elle yazmaz — builder kullanır.
      expect(router, contains('buildRentDemoLink'));
      expect(router, isNot(contains("'/rent-demo'")));
    });

    test('misafir kopruye, hesapli RPC + duzenleyici linkine gider', () {
      // Misafir: giriş zorlanmaz, köprü sayfasına taşınır.
      expect(router, contains('buildRentDemoLink'));
      // Hesaplı: klon sahipli doğar, düzenleyici linki yine web'tedir.
      expect(router, contains('hesabaKirala'));
      expect(router, contains('duzenleyiciUrl'));
    });
  });

  group('Flutter kiralama servisi ince kalir (UI yok)', () {
    test('servis backend cagirir, widget bilmez', () {
      expect(servis, contains('rentDemoForAccount'));
      expect(servis, isNot(contains('package:flutter/material.dart')));
      expect(servis, isNot(contains('package:flutter/widgets.dart')));
      expect(servis, isNot(contains('BuildContext')));
      expect(servis, isNot(contains('recaptcha')));
    });

    test('kanonik zincir tek depoda (Flutter + Next.js ortak)', () {
      expect(depo, contains('rent_demo_canonical'));
    });
  });
}
