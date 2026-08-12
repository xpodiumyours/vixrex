import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  group('Gelişmiş konum alanlarının sahipliği', () {
    final baseLocationSource = _read(
      'lib/widgets/editor/location_editor_section.dart',
    );
    final onboardingSource = _read(
      'lib/screens/vixrex_onboarding_chat_screen.dart',
    );
    final manualFormSource = _read(
      'lib/screens/my_vitrin/sections/vitrin_form_section.dart',
    );
    final advancedFieldsFile = File(
      'lib/widgets/editor/advanced_location_fields.dart',
    );

    test(
      'temel konum modülü gelişmiş alanları veya görünürlük bayrağını taşımaz',
      () {
        for (final forbidden in [
          'showAdvancedFields',
          'heroLocationTextController',
          'mapLabelController',
          'Hero Konum Metni',
          'Harita Kartı Etiketi',
        ]) {
          expect(
            baseLocationSource,
            isNot(contains(forbidden)),
            reason:
                'Temel konum modülü yalnız il, ilçe, adres ve GPS akışına '
                'sahip olmalı: $forbidden',
          );
        }
      },
    );

    test('kurulum sohbeti gelişmiş konum alanlarını sahiplenmez', () {
      for (final forbidden in [
        'showAdvancedFields',
        'heroLocationTextController',
        'mapLabelController',
      ]) {
        expect(
          onboardingSource,
          isNot(contains(forbidden)),
          reason: 'Kurulum akışı yalnız zorunlu konum bilgilerini istemeli.',
        );
      }
    });

    test('gelişmiş alanların küçük sahip modülü manuel panelde kullanılır', () {
      expect(
        advancedFieldsFile.existsSync(),
        isTrue,
        reason: 'Gelişmiş alanların ayrı bir sahip modülü olmalı.',
      );
      if (!advancedFieldsFile.existsSync()) return;

      final advancedFieldsSource = advancedFieldsFile.readAsStringSync();
      expect(advancedFieldsSource, contains('class AdvancedLocationFields'));
      expect(advancedFieldsSource, contains('Hero Konum Metni'));
      expect(advancedFieldsSource, contains('Harita Kartı Etiketi'));
      expect(
        advancedFieldsSource.split('\n').length,
        lessThan(400),
        reason: 'Yeni sahip modül mimari büyüme sınırının altında kalmalı.',
      );
      expect(manualFormSource, contains('AdvancedLocationFields('));
      expect(manualFormSource, contains('FormLocationInfo('));
    });
  });
}
