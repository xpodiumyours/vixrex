import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/services/store_location_fetch_service.dart';

export 'package:vixrex/services/store_location_fetch_service.dart'
    show StoreLocationStatus;

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

  void updateHeroLocationText(StoreData data, String value) {
    data.heroLocationText = value;
    notifyListeners();
  }

  void updateMapLabel(StoreData data, String value) {
    data.mapLabel = value;
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

  void _notifyLocationListeners() {
    if (!isDisposed) notifyListeners();
  }

  /// GPS üzerinden mevcut konumu çeker ve il/ilçe eşleştirmesi yapar.
  ///
  /// - il+ilçe eşleşirse adres güncellenir.
  /// - Eşleşemezse mevcut manuel adres **korunur**, kullanıcıya mesaj gösterilir.
  /// - Editör dispose edilmişse setState yapılmaz.
  ///
  /// Gerçek iş (GPS çağrısı, doğruluk denetimi, adres çözme, il/ilçe
  /// eşleştirme) `StoreLocationFetchService`'te (Faz 4, controller
  /// parçalama, birebir taşındı); burada yalnız dispose/loading state'i ve
  /// sonucun `data`'ya uygulanması kalıyor. Tek gözlemlenebilir fark:
  /// eskiden `isDisposed` her `await` sonrası ayrıca kontrol edilip erken
  /// dönülüyordu (ör. dispose sonrası adres çözme hiç başlamazdı); artık
  /// servis zinciri tek seferde tamamlanıyor, `isDisposed` yalnız sonunda
  /// kontrol ediliyor — dispose sonrası bir ağ isteği daha gidebilir ama
  /// hiçbir state/`notifyListeners` dispose sonrası tetiklenmez.
  Future<void> fetchLocation({
    required StoreData data,
    required LocationService locationService,
    StoreLocationFetchService fetchService = const StoreLocationFetchService(),
  }) async {
    if (isDisposed) return;
    _isLocating = true;
    _locationStatus = StoreLocationStatus.loading;
    _locationStatusMessage = 'Konum aranıyor...';
    _notifyLocationListeners();

    final sonuc = await fetchService.getir(locationService);
    if (isDisposed) return;

    _locationStatus = sonuc.durum;
    _locationStatusMessage = sonuc.mesaj;

    // Doğruluk eşiği geçildiyse koordinat kaydedilir — adres/il/ilçe
    // çözülemese BİLE (orijinal davranış, bkz. servisin kendi notu).
    if (sonuc.konumGecerli) {
      data.latitude = sonuc.latitude;
      data.longitude = sonuc.longitude;
      data.locationAccuracyMeters = sonuc.accuracy;
      data.locationSource = 'device';
      data.locationConsentAt = sonuc.consentAt;
    }

    if (sonuc.basarili) {
      data.address = sonuc.address!;
      data.provinceCode = sonuc.provinceCode!;
      data.provinceName = sonuc.provinceName!;
      data.districtCode = sonuc.districtCode!;
      data.districtName = sonuc.districtName!;
    }

    _isLocating = false;
    _notifyLocationListeners();
  }
}
