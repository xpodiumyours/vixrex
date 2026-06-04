import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/services/location_service.dart';

void main() {
  group('LocationResult', () {
    test('failure() isSuccess returns false', () {
      final result = LocationResult.failure('Konum alinamadi.');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Konum alinamadi.');
      expect(result.position, isNull);
    });
  });

  group('LocationService.buildAccuracyMessage', () {
    test('success message for <= 30m', () {
      final message = LocationService.buildAccuracyMessage(30);
      expect(message, contains('30'));
      expect(message, contains('basariyla'));
      expect(message, isNot(contains('hata payi yuksek')));
    });

    test('warning message for > 30m', () {
      final message = LocationService.buildAccuracyMessage(31);
      expect(message, contains('31'));
      expect(message, contains('hata payi yuksek'));
      expect(message, contains('30 metre'));
    });

    test('edge case: 30.1m shows warning message', () {
      final message = LocationService.buildAccuracyMessage(30.1);
      expect(message, contains('hata payi yuksek'));
    });
  });
}
