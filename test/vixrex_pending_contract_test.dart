import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_memory.dart';

void main() {
  group('Vixrex pending envelope v1', () {
    test('v1 JSON legacy uyum alanlarını da taşır', () {
      final slot = VixrexPendingSlot(
        anahtar: 'telefon',
        etiket: 'Telefon',
        tip: 'telefon',
        sorulduAt: DateTime.parse('2026-09-05T12:00:00.000Z'),
      );

      final json = slot.toJson();
      expect(json['schemaVersion'], 1);
      expect(json['domain'], 'storefront');
      expect(json['kind'], 'missing_value');
      expect(json['fieldKey'], 'telefon');
      expect(json['anahtar'], 'telefon');
      expect(json['tip'], 'telefon');
      expect(json['deneme'], 1);
    });

    test('eski pending kaydını v1 olarak normalize eder', () {
      final slot = VixrexPendingSlot.fromJson({
        'anahtar': 'adres',
        'etiket': 'Açık Adres',
        'tip': 'uzunMetin',
        'sorulduAt': '2026-09-05T12:00:00.000Z',
        'deneme': 2,
      });

      expect(slot.schemaVersion, 1);
      expect(slot.domain, 'storefront');
      expect(slot.kind, 'missing_value');
      expect(slot.anahtar, 'adres');
      expect(slot.tip, 'uzunMetin');
      expect(slot.deneme, 2);
    });

    test('Supabase yokken SharedPrefs yalnız cache olarak devam eder', () async {
      SharedPreferences.setMockInitialValues({});
      const memory = VixrexConversationMemory();
      final slot = VixrexPendingSlot(
        anahtar: 'telefon',
        etiket: 'Telefon',
        tip: 'telefon',
        sorulduAt: DateTime.parse('2026-09-05T12:00:00.000Z'),
      );

      await memory.savePendingSlot(slot, scope: 'test-store');
      final loaded = await memory.loadPendingSlot(scope: 'test-store');
      expect(loaded?.anahtar, 'telefon');

      await memory.clearPendingSlot(scope: 'test-store');
      expect(
        await memory.loadPendingSlot(scope: 'test-store'),
        isNull,
      );
    });
  });
}
