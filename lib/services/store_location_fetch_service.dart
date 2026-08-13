import 'package:vixrex/config/turkey_cities_config.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/utils/text_utils.dart';

/// [StoreLocationFetchService.getir]'in dönebileceği sonuç türleri —
/// `store_location_mixin.dart`'taki `StoreLocationStatus`'ın taşınmış hâli
/// (Faz 4, controller parçalama); tek kaynak artık burası.
enum StoreLocationStatus {
  idle,
  loading,
  success,
  approximate,
  permissionDenied,
  serviceDisabled,
  error,
}

/// [StoreLocationFetchService.getir] sonucu. `basarili` true ise
/// konum/adres/il/ilçe alanlarının hepsi doludur.
class LocationFetchSonucu {
  const LocationFetchSonucu._({
    required this.durum,
    required this.mesaj,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.consentAt,
    this.address,
    this.provinceCode,
    this.provinceName,
    this.districtCode,
    this.districtName,
  });

  final StoreLocationStatus durum;
  final String mesaj;

  /// Doğruluk eşiği geçildiyse dolu — adres/il/ilçe çözülemese BİLE
  /// koordinat kaydedilir (orijinal davranış: yalnız doğruluk şartı).
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? consentAt;

  /// Yalnız [basarili] true ise dolu.
  final String? address;
  final String? provinceCode;
  final String? provinceName;
  final String? districtCode;
  final String? districtName;

  bool get basarili => durum == StoreLocationStatus.success;

  /// [latitude]/[longitude]/[accuracy] dolu mu — doğruluk eşiği geçildi mi.
  bool get konumGecerli =>
      latitude != null && longitude != null && accuracy != null;
}

/// `StoreEditorController`'ın (`StoreLocationMixin` üzerinden) GPS konum
/// alma + il/ilçe eşleştirme iş mantığını sahiplenir.
///
/// UI/controller-state'e (`isDisposed`, `notifyListeners`, `_isLocating`
/// gibi) hiç dokunmaz — yalnız [LocationFetchSonucu] döner, ekrana ne
/// yansıtılacağına çağıran karar verir (`ProductCatalogSyncService` ile
/// aynı desen: dar/derin arayüz, controller-state callback'i yok).
///
/// 2026-08-13: `store_location_mixin.dart`'tan (Faz 4, controller
/// parçalama) birebir taşındı. Davranış kasıtlı olarak değiştirilmedi.
class StoreLocationFetchService {
  const StoreLocationFetchService();

  /// GPS'ten mevcut konumu alır, doğruluğu denetler, adresi çözer ve
  /// il/ilçe eşleştirir.
  ///
  /// - 10 metreden kötü doğruluk KAYDEDİLMEZ (bkz. [eslestirIlIlce] altı
  ///   yorum) — `LocationService.maxAcceptedAccuracyMeters`.
  /// - il+ilçe eşleşemezse `provinceCode`/`districtCode` null döner;
  ///   çağıran mevcut manuel adresi KORUMALIDIR, üzerine yazmamalıdır.
  Future<LocationFetchSonucu> getir(LocationService locationService) async {
    try {
      final result = await locationService.getCurrentLocation();
      final pos = result.bestPosition;

      if (pos == null) {
        return LocationFetchSonucu._(
          durum: _basarisizlikDurumu(result.errorMessage),
          mesaj:
              result.errorMessage ?? 'Konum alınamadı. Lütfen tekrar deneyin.',
        );
      }

      // TEK KURAL: 10 metreden kötü konum KAYDEDİLMEZ.
      //
      // Bu kontrol eskiden yalnız location_editor_section.dart'ta vardı;
      // GPS düğmesi ise BU yoldan geçiyordu ve sapma ne olursa olsun
      // koordinatı yazıyordu (yalnız 2 km üstünde adres çözmeyi bırakıyordu).
      // Yani 900 metrelik sapma sessizce kabul ediliyordu.
      //
      // İki ayrı yerde iki ayrı kural olması hatanın kendisiydi. Karar
      // tek yerde: LocationService.maxAcceptedAccuracyMeters.
      //
      // Neden bu kadar katı: vitrinin işi "yakınındaki dükkânı" bulmak.
      // Yanlış pin müşteriyi yanlış sokağa gönderir — yokluğundan beterdir.
      if (pos.accuracy > LocationService.maxAcceptedAccuracyMeters) {
        return LocationFetchSonucu._(
          durum: StoreLocationStatus.error,
          mesaj: LocationService.buildAccuracyMessage(pos.accuracy),
        );
      }

      // Doğruluk eşiği geçildi — koordinat bu andan itibaren kaydedilir,
      // adres/il/ilçe çözülemese bile (orijinal davranış).
      final consentAt = DateTime.now();

      final address = await locationService.getAddressFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (address == null || address.trim().isEmpty) {
        return LocationFetchSonucu._(
          durum: StoreLocationStatus.error,
          mesaj:
              'Koordinat alındı ancak adres çözümlenemedi. '
              'Mevcut adresiniz korundu.',
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          consentAt: consentAt,
        );
      }

      final eslesme = eslestirIlIlce(address);
      if (eslesme.provinceCode == null ||
          eslesme.provinceName == null ||
          eslesme.districtName == null) {
        // Eşleşme başarısız — mevcut adres korunur (çağıran uygular).
        return LocationFetchSonucu._(
          durum: StoreLocationStatus.error,
          mesaj:
              'Adres il ve ilçe olarak doğrulanamadı. Mevcut adresiniz korundu.',
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          consentAt: consentAt,
        );
      }

      return LocationFetchSonucu._(
        durum: StoreLocationStatus.success,
        mesaj:
            result.errorMessage ??
            LocationService.buildAccuracyMessage(pos.accuracy),
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        consentAt: consentAt,
        address: address,
        provinceCode: eslesme.provinceCode,
        provinceName: eslesme.provinceName,
        districtCode: eslesme.districtName,
        districtName: eslesme.districtName,
      );
    } catch (_) {
      return const LocationFetchSonucu._(
        durum: StoreLocationStatus.error,
        mesaj: 'Konum alınırken hata oluştu. Mevcut adresiniz korundu.',
      );
    }
  }

  /// Bir adres metninden il/ilçe eşleştirir — SAF fonksiyon, GPS/ağ
  /// gerektirmez, doğrudan test edilebilir.
  ///
  /// Uzun ilçe adı önce denenir (ör. "Şişli" vs kısa eşleşmeler). İlk
  /// eşleşen il kazanır; il içinde ilçe bulunamazsa yalnız il döner.
  ({String? provinceCode, String? provinceName, String? districtName})
  eslestirIlIlce(String address) {
    final normalizedAddress = TextUtils.normalizeTurkish(address);

    for (final province in turkeyProvinces) {
      final normalizedProvince = TextUtils.normalizeTurkish(province.name);
      if (!normalizedAddress.contains(normalizedProvince)) continue;

      String? matchedDistrict;
      final districts = turkeyDistricts[province.code];
      if (districts != null) {
        final ordered = [...districts]
          ..sort((a, b) => b.length.compareTo(a.length));
        for (final district in ordered) {
          final normalizedDistrict = TextUtils.normalizeTurkish(district);
          if (normalizedAddress.contains(normalizedDistrict)) {
            matchedDistrict = district;
            break;
          }
        }
      }

      return (
        provinceCode: province.code,
        provinceName: province.name,
        districtName: matchedDistrict,
      );
    }

    return (provinceCode: null, provinceName: null, districtName: null);
  }

  StoreLocationStatus _basarisizlikDurumu(String? message) {
    if (message == null) return StoreLocationStatus.error;
    final lower = message.toLowerCase();
    if (lower.contains('reddedildi')) {
      return StoreLocationStatus.permissionDenied;
    }
    if (lower.contains('devre disi') || lower.contains('devre dışı')) {
      return StoreLocationStatus.serviceDisabled;
    }
    return StoreLocationStatus.error;
  }
}
