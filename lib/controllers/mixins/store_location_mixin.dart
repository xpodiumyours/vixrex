import 'package:flutter/material.dart';
import 'package:vixrex/config/turkey_cities_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/utils/text_utils.dart';

/// Konum (GPS) ve Adres (İl/İlçe) işlemlerini yöneten Mixin.
mixin StoreLocationMixin on ChangeNotifier {
  // --- States ---
  String? _provinceError;
  String? _districtError;
  String? _addressError;
  String? _locationStatusMessage;
  bool _isLocating = false;

  // --- Getters ---
  String? get provinceError => _provinceError;
  String? get districtError => _districtError;
  String? get addressError => _addressError;
  String? get locationStatusMessage => _locationStatusMessage;
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
    notifyListeners();
  }

  void setLocationStatusMessage(String? message) {
    _locationStatusMessage = message;
    notifyListeners();
  }

  /// GPS üzerinden mevcut konumu çeker ve il/ilçe eşleştirmesi yapar.
  ///
  /// Chrome/web sık sık 30 m üstü (yaklaşık) konum döner; editördeki gibi
  /// `bestPosition` kabul edilir. Elle adres yazma yolu buraya bağlı değildir.
  Future<void> fetchLocation({
    required StoreData data,
    required LocationService locationService,
  }) async {
    _isLocating = true;
    _locationStatusMessage = 'Konum aranıyor...';
    notifyListeners();

    try {
      final result = await locationService.getCurrentLocation();
      final pos = result.bestPosition;
      if (pos == null) {
        _locationStatusMessage =
            result.errorMessage ?? 'Konum alınamadı. Lütfen tekrar deneyin.';
        return;
      }

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
      if (address != null && address.trim().isNotEmpty) {
        data.address = address;
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
          data.provinceCode = matchedProvinceCode;
          data.provinceName = matchedProvinceName;
          data.districtCode = matchedDistrict;
          data.districtName = matchedDistrict;
        }
      }
    } catch (_) {
      _locationStatusMessage =
          'Konum alınırken hata oluştu. Mevcut adresiniz korundu.';
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }
}
