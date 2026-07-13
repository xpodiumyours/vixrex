import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  const LocationResult._({
    this.position,
    this.approximatePosition,
    this.errorMessage,
  });

  factory LocationResult.success(Position position) =>
      LocationResult._(position: position);

  factory LocationResult.approximate(Position position, String message) =>
      LocationResult._(approximatePosition: position, errorMessage: message);

  factory LocationResult.failure(String message) =>
      LocationResult._(errorMessage: message);

  final Position? position;
  final Position? approximatePosition;
  final String? errorMessage;

  bool get isSuccess => position != null;
  bool get hasApproximatePosition => approximatePosition != null;
  Position? get bestPosition => position ?? approximatePosition;
}

class LocationService {
  const LocationService();

  static const double maxAcceptedAccuracyMeters = 30.0;
  static const Duration _streamWaitDuration = Duration(seconds: 10);
  static const Duration _totalTimeout = Duration(seconds: 12);

  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure(
        'Konum servisleri devre disi. Lutfen cihazinizda konumu acin.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.failure(
          'Konum izni reddedildi. Konum almak icin izin vermelisiniz.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure(
        'Konum izinleri kalici olarak reddedildi. '
        'Tarayici ayarlarindan izin verin.',
      );
    }

    try {
      final position = await _fetchBestPosition(_buildLocationSettings());
      if (position.accuracy <= maxAcceptedAccuracyMeters) {
        return LocationResult.success(position);
      }
      return LocationResult.approximate(
        position,
        buildAccuracyMessage(position.accuracy),
      );
    } on TimeoutException {
      return LocationResult.failure(
        'Konum alinamadi. Lutfen tekrar deneyin veya adresi elle yazin.',
      );
    } catch (error) {
      final errorText = error.toString().toLowerCase();
      if (errorText.contains('timeout') || errorText.contains('time out')) {
        return LocationResult.failure(
          'Konum alinamadi. Lutfen tekrar deneyin veya adresi elle yazin.',
        );
      }
      return LocationResult.failure('Konum alinirken hata olustu: $error');
    }
  }

  static String buildAccuracyMessage(double accuracyMeters) {
    final accuracyText = accuracyMeters.toStringAsFixed(0);
    if (accuracyMeters <= maxAcceptedAccuracyMeters) {
      return 'Konum basariyla alindi. Hata payi: yaklasik $accuracyText m.';
    }
    return 'Konum yaklasik bulundu. Hata payi: yaklasik $accuracyText m. '
        '30 metre alti dogruluk icin acik alanda bekleyin, Wi-Fi acik deneyin '
        'veya Google Maps uzerinden kontrol edin.';
  }

  static Uri buildGoogleMapsSearchUri(double latitude, double longitude) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
  }

  static Uri buildGoogleMapsDirectionsUri(double latitude, double longitude) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
    });
  }

  LocationSettings _buildLocationSettings() {
    if (kIsWeb) {
      return WebSettings(
        accuracy: LocationAccuracy.best,
        maximumAge: Duration.zero,
        timeLimit: _totalTimeout,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      timeLimit: _totalTimeout,
    );
  }

  Future<Position> _fetchBestPosition(LocationSettings settings) async {
    Position? bestPosition;
    final completer = Completer<Position?>();

    final subscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        if (bestPosition == null ||
            position.accuracy < bestPosition!.accuracy) {
          bestPosition = position;
        }

        if (position.accuracy <= maxAcceptedAccuracyMeters &&
            !completer.isCompleted) {
          completer.complete(position);
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    Future<void>.delayed(_streamWaitDuration, () {
      if (!completer.isCompleted) {
        completer.complete(bestPosition);
      }
    });

    Position? position;
    try {
      position = await completer.future.timeout(_totalTimeout);
    } finally {
      await subscription.cancel();
    }

    final resolvedPosition =
        position ??
        await Geolocator.getCurrentPosition(locationSettings: settings);

    return resolvedPosition;
  }

  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );

      final response = await http
          .get(
            url,
            headers: {
              'User-Agent': 'Vixrex-Flutter-App',
              'Accept-Language': 'tr-TR,tr;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final addressData = data['address'] as Map<String, dynamic>?;

        if (addressData != null) {
          final road = addressData['road'] ?? addressData['street'] ?? '';
          final suburb =
              addressData['suburb'] ?? addressData['neighbourhood'] ?? '';
          final town =
              addressData['town'] ??
              addressData['city_district'] ??
              addressData['district'] ??
              '';
          final city = addressData['city'] ?? addressData['province'] ?? '';

          final parts = <String>[];
          if (suburb.isNotEmpty) parts.add('$suburb Mah.');
          if (road.isNotEmpty) parts.add(road.toString());
          if (town.isNotEmpty) parts.add(town.toString());
          if (city.isNotEmpty && city != town) parts.add(city.toString());

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        return data['display_name'] as String?;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Reverse geocode error: $e');
    }
    return null;
  }
}
