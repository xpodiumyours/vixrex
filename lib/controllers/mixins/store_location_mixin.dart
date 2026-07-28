import 'package:flutter/material.dart';
import 'package:vixrex/config/turkey_cities_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/utils/text_utils.dart';

enum StoreLocationStatus {
  idle,
  loading,
  success,
  approximate,
  permissionDenied,
  serviceDisabled,
  error,
}

/// Konum (GPS) ve Adres (İl/İlçe) işlemlerini yöneten Mixin.
mixin StoreLocationMixin on ChangeNotifier {
  bool get isDisposed;

  // --- States ---
  String? _provinceError;
  String? _districtError;
  String? _addressError;
  String? _locationStatusMessage;
  StoreLocationStatus _locationStatus = StoreLocationStatus.idle;
  bool _isLocating = false;

  // --- Getters ---
  String? get provinceError => _provinceError;
  String? get districtError => _districtError;
  String? get addressError => _addressError;
  String? get locationStatusMessage => _locationStatusMessage;
  StoreLocationStatus get locationStatus => _locationStatus;
  bool get isLocating => _isLocating;

  // --- Methods ---
  void clearLocationErrors() {
    _provinceError = null;
    _districtError = null;
    _addressError = null;
    notifyListeners();
  }

  void updateAddress(StoreData data, String address) {
    data.address = address;
    notifyListeners();
  }

  void selectProvince(StoreData data, String? code, String? name) {
    data.provinceCode = code ?? '';
    data.provinceName = name ?? '';
    notifyListeners();
  }

  void selectDistrict(StoreData data, String? code, String? name) {
    data.districtCode = code ?? '';
    data.districtName = name ?? '';
    notifyListeners();
  }

  void setLocating(bool locating) {
    _isLocating = locating;
    _notifyLocationListeners();
  }

  void setLocationStatusMessage(String? message) {
    _locationStatusMessage = message;
    _notifyLocationListeners();
  }

  void _notifyLocationListeners() {
    if (!isDisposed) notifyListeners();
  }

  /// GPS üzerinden mevcut konumu çeker ve il/ilçe eşleştirmesi yapar.
  ///
  /// Chrome/web sık sık 30 m üstü (yaklaşık) konum döner; editördeki gibi
  /// `bestPosition` kabul edilir. Elle adres yazma yolu buraya bağlı değildir.
  Future<void> fetchLocation({
    required StoreData data,
    required LocationService locationService,
  }) async {
    if (isDisposed) return;
    _isLocating = true;
    _locationStatus = StoreLocationStatus.loading;
    _locationStatusMessage = 'Konum aranıyor...';
    _notifyLocationListeners();

    try {
      final result = await locationService.getCurrentLocation();
      if (isDisposed) return;
      final pos = result.bestPosition;
      if (pos == null) {
        _locationStatus = _failureStatus(result.errorMessage);
        _locationStatusMessage =
            result.errorMessage ?? 'Konum alınamadı. Lütfen tekrar deneyin.';
        return;
      }

      _locationStatus = result.hasApproximatePosition
          ? StoreLocationStatus.approximate
          : StoreLocationStatus.success;
      data.latitude = pos.latitude;
      data.longitude = pos.longitude;
      data.locationAccuracyMeters = pos.accuracy;
      data.locationSource = 'device';
      data.locationConsentAt = DateTime.now();
      _locationStatusMessage =
          result.errorMessage ??
          LocationService.buildAccuracyMessage(pos.accuracy);

      final address = await locationService.getAddressFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (isDisposed) return;
      if (address == null || address.trim().isEmpty) {
        _locationStatus = StoreLocationStatus.error;
        _locationStatusMessage =
            'Koordinat alındı ancak adres çözümlenemedi. '
            'Mevcut adresiniz korundu.';
        return;
      }
      if (address.trim().isNotEmpty) {
        final normalizedAddress = TextUtils.normalizeTurkish(address);
        String? matchedProvinceCode;
        String? matchedProvinceName;
        String? matchedDistrict;

        for (final province in turkeyProvinces) {
          final normalizedProvince =
              TextUtils.normalizeTurkish(province.name);
          if (!normalizedAddress.contains(normalizedProvince)) continue;

          matchedProvinceCode = province.code;
          matchedProvinceName = province.name;
          final districts = turkeyDistricts[province.code];
          if (districts != null) {
            // Uzun ilçe adını önce dene (ör. "Şişli" vs kısa eşleşmeler).
            final ordered = [...districts]
              ..sort((a, b) => b.length.compareTo(a.length));
            for (final district in ordered) {
              final normalizedDistrict =
                  TextUtils.normalizeTurkish(district);
              if (normalizedAddress.contains(normalizedDistrict)) {
                matchedDistrict = district;
                break;
              }
            }
          }
          break;
        }

        if (matchedProvinceCode != null &&
            matchedProvinceName != null &&
            matchedDistrict != null) {
          data.address = address;
          data.provinceCode = matchedProvinceCode;
          data.provinceName = matchedProvinceName;
          data.districtCode = matchedDistrict;
          data.districtName = matchedDistrict;
        } else {
          _locationStatus = StoreLocationStatus.error;
          _locationStatusMessage =
              'Adres il ve ilçe olarak doğrulanamadı. Mevcut adresiniz korundu.';
        }
      }
    } catch (_) {
      if (!isDisposed) {
        _locationStatus = StoreLocationStatus.error;
        _locationStatusMessage =
            'Konum alınırken hata oluştu. Mevcut adresiniz korundu.';
      }
    } finally {
      _isLocating = false;
      _notifyLocationListeners();
    }
  }

  StoreLocationStatus _failureStatus(String? message) {
    final normalized = TextUtils.normalizeTurkish(message ?? '');
    if (normalized.contains('izin') || normalized.contains('izn')) {
      return StoreLocationStatus.permissionDenied;
    }
    if (normalized.contains('servis')) {
      return StoreLocationStatus.serviceDisabled;
    }
    return StoreLocationStatus.error;
  }
}
