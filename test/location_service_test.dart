import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/services/location_service.dart';

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
    test('success message for <= 10m', () {
      final message = LocationService.buildAccuracyMessage(10);
      expect(message, contains('10'));
      expect(message, contains('basariyla'));
      expect(message, isNot(contains('hata payi yuksek')));
    });

    test('warning message for > 10m', () {
      final message = LocationService.buildAccuracyMessage(31);
      expect(message, contains('31'));
      expect(message, contains('yeterince kesin degil'));
      expect(message, contains('TELEFONDAN'));

    });

    test('edge case: 10.1m shows warning message', () {
      final message = LocationService.buildAccuracyMessage(10.1);
      expect(message, contains('yeterince kesin degil'));
    });

    test('builds free Google Maps search uri', () {
      final uri = LocationService.buildGoogleMapsSearchUri(41.01, 29.02);
      expect(uri.toString(), contains('www.google.com/maps/search'));
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['query'], '41.01,29.02');
    });

    test('builds free Google Maps directions uri', () {
      final uri = LocationService.buildGoogleMapsDirectionsUri(41.01, 29.02);
      expect(uri.toString(), contains('www.google.com/maps/dir'));
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '41.01,29.02');
    });
  });
}
