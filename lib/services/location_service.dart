import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult._({this.position, this.errorMessage});

  factory LocationResult.success(Position position) =>
      LocationResult._(position: position);

  factory LocationResult.failure(String message) =>
      LocationResult._(errorMessage: message);

  final Position? position;
  final String? errorMessage;

  bool get isSuccess => position != null;
}

class LocationAccuracyException implements Exception {
  const LocationAccuracyException(this.accuracyMeters);

  final double accuracyMeters;

  @override
  String toString() => 'LocationAccuracyException($accuracyMeters)';
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
      return LocationResult.success(position);
    } on TimeoutException {
      return LocationResult.failure(
        'Konum alinamadi. Lutfen tekrar deneyin veya adresi elle yazin.',
      );
    } on LocationAccuracyException catch (error) {
      return LocationResult.failure(buildAccuracyMessage(error.accuracyMeters));
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
    return 'Konum bulundu ama hata payi yuksek: $accuracyText m. '
        '30 metre alti dogruluk icin acik alanda tekrar deneyin.';
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

    if (resolvedPosition.accuracy > maxAcceptedAccuracyMeters) {
      throw LocationAccuracyException(resolvedPosition.accuracy);
    }

    return resolvedPosition;
  }
}
