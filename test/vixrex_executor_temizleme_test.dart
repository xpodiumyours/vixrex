import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_executor.dart';

void main() {
  group('Vixrex Executor isteğe bağlı alan temizleme', () {
    test('isteğe bağlı telefon null ile güvenle temizlenir', () {
      final controller = StoreEditorController();
      controller.updatePhone('02125554433');
      final alan = vixrexNiyetAlanByAnahtar['telefon']!;

      final ok = const VixrexExecutor().execute(
        controller: controller,
        alan: alan,
        deger: null,
      );

      expect(ok, isTrue);
      expect(controller.data.phone, isEmpty);
    });

    test('isteğe bağlı enlem null ile gerçekten kaldırılır', () {
      final controller = StoreEditorController();
      controller.data.latitude = 41.01;
      final alan = vixrexNiyetAlanByAnahtar['enlem']!;

      final ok = const VixrexExecutor().execute(
        controller: controller,
        alan: alan,
        deger: null,
      );

      expect(ok, isTrue);
      expect(controller.data.latitude, isNull);
    });

    test('zorunlu WhatsApp null ile temizlenemez', () {
      final controller = StoreEditorController();
      controller.updateWhatsapp('905325554433');
      final alan = vixrexNiyetAlanByAnahtar['whatsapp']!;

      final ok = const VixrexExecutor().execute(
        controller: controller,
        alan: alan,
        deger: null,
      );

      expect(ok, isFalse);
      expect(controller.data.whatsapp, '905325554433');
    });
  });
}
