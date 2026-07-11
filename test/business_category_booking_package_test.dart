import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/business_category_config.dart';

void main() {
  group('supportsBookingPackage', () {
    test('kuaför / güzellik açık', () {
      expect(BusinessCategoryConfig.supportsBookingPackage('Kuaför'), isTrue);
      expect(BusinessCategoryConfig.supportsBookingPackage('güzellik'), isTrue);
    });

    test('butik / giyim kapalı', () {
      expect(BusinessCategoryConfig.supportsBookingPackage('Butik'), isFalse);
      expect(BusinessCategoryConfig.supportsBookingPackage('Giyim'), isFalse);
    });

    test('boş veya yoksa kapalı', () {
      expect(BusinessCategoryConfig.supportsBookingPackage(null), isFalse);
      expect(BusinessCategoryConfig.supportsBookingPackage(''), isFalse);
    });
  });
}
