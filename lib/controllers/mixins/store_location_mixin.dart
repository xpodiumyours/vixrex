import 'package:flutter/material.dart';
import 'package:vixrex/config/turkey_cities_config.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/location_service.dart';

/// Konum (GPS) ve Adres (İl/İlçe) işlemlerini yöneten Mixin.
mixin StoreLocationMixin on ChangeNotifier {
  // --- States ---
  String? _provinceError;
  String? _districtError;
  String? _addressError;
  bool _isLocating = false;

  // --- Getters ---
  String? get provinceError => _provinceError;
  String? get districtError => _districtError;
  String? get addressError => _addressError;
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

  /// GPS üzerinden mevcut konumu çeker ve il/ilçe eşleştirmesi yapar.
  Future<void> fetchLocation({
    required StoreData data,
    required LocationService locationService,
  }) async {
    _isLocating = true;
    notifyListeners();

    final result = await locationService.getCurrentLocation();
    if (result.isSuccess && result.position != null) {
      final pos = result.position!;
      data.latitude = pos.latitude;
      data.longitude = pos.longitude;
      data.locationAccuracyMeters = pos.accuracy;
      data.locationSource = 'device';
      data.locationConsentAt = DateTime.now();

      final address = await locationService.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (address != null && address.trim().isNotEmpty) {
        data.address = address;
        // İl/İlçe otomatik tespiti
        for (final province in turkeyProvinces) {
          if (address.toLowerCase().contains(province.name.toLowerCase())) {
            data.provinceCode = province.code;
            data.provinceName = province.name;
            final districts = turkeyDistricts[province.code];
            if (districts != null) {
              for (final district in districts) {
                if (address.toLowerCase().contains(district.toLowerCase())) {
                  data.districtCode = district;
                  data.districtName = district;
                  break;
                }
              }
            }
            break;
          }
        }
      }
    }
    _isLocating = false;
    notifyListeners();
  }
}
