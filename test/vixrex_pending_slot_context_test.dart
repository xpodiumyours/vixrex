import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_memory.dart';

void main() {
  group('Vixrex pending slot bağlamı', () {
    test('kaldırma onayı eylemi JSON turunda kaybolmaz', () {
      final slot = VixrexPendingSlot(
        anahtar: 'telefon',
        etiket: 'Telefon',
        tip: 'telefon',
        sorulduAt: DateTime.utc(2026, 9, 10, 12),
        eylem: 'kaldir',
      );

      final geri = VixrexPendingSlot.fromJson(slot.toJson());

      expect(geri.anahtar, 'telefon');
      expect(geri.eylem, 'kaldir');
      expect(geri.sorulduAt, slot.sorulduAt);
    });

    test('eski pending slot kaydı eylem olmadan okunmaya devam eder', () {
      final geri = VixrexPendingSlot.fromJson({
        'anahtar': 'whatsapp',
        'etiket': 'WhatsApp Numarası',
        'tip': 'telefon',
        'sorulduAt': '2026-09-10T12:00:00.000Z',
      });

      expect(geri.anahtar, 'whatsapp');
      expect(geri.eylem, isNull);
    });
  });
}
