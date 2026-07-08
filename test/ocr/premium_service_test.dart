import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/premium_config.dart';

void main() {
  group('PremiumConfig', () {
    test('Ücretsiz OCR limiti 3', () {
      expect(PremiumConfig.freeOcrDailyLimit, 3);
    });

    test('Kullanım limiti altında izin verir', () {
      expect(PremiumConfig.canUseOcr(0), true);
      expect(PremiumConfig.canUseOcr(1), true);
      expect(PremiumConfig.canUseOcr(2), true);
    });

    test('Kullanım limiti üstünde izin vermez', () {
      expect(PremiumConfig.canUseOcr(3), false);
      expect(PremiumConfig.canUseOcr(5), false);
    });

    test('Kalan hakkı doğru hesaplar', () {
      expect(PremiumConfig.remainingFreeOcr(0), 3);
      expect(PremiumConfig.remainingFreeOcr(1), 2);
      expect(PremiumConfig.remainingFreeOcr(2), 1);
      expect(PremiumConfig.remainingFreeOcr(3), 0);
      expect(PremiumConfig.remainingFreeOcr(5), 0);
    });
  });
}
