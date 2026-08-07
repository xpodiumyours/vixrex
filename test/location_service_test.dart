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

    // 2026-08-07: esik 10'dan 100 metreye cikti. 10 metre yalniz yerel
    // GPS donanimiyla tutturulur; tarayici konumu telefonda bile 20-60
    // metre sapar. Eski esikle adres cozumleme adimina HIC ulasilamiyordu.
    test('warning message beyond the accepted threshold', () {
      final message = LocationService.buildAccuracyMessage(320);
      expect(message, contains('320'));
      expect(message, contains('yeterince kesin degil'));
      expect(message, contains('TELEFONDAN'));
    });

    test('edge case: just past the threshold shows warning', () {
      final message = LocationService.buildAccuracyMessage(
        LocationService.maxAcceptedAccuracyMeters + 0.1,
      );
      expect(message, contains('yeterince kesin degil'));
    });

    test('browser-grade accuracy is accepted', () {
      // Telefon tarayicisindan gelen tipik deger. Eskiden reddediliyordu.
      final message = LocationService.buildAccuracyMessage(45);
      expect(message, contains('basariyla'));
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
