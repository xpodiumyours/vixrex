import 'package:vixrex/config/turkey_cities_config.dart';
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
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? consentAt;
  final String? address;
  final String? provinceCode;
  final String? provinceName;
  final String? districtCode;
  final String? districtName;

  bool get basarili => durum == StoreLocationStatus.success;
  bool get konumGecerli =>
      latitude != null && longitude != null && accuracy != null;
}

class StoreLocationFetchService {
  const StoreLocationFetchService();

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

      if (pos.accuracy > LocationService.maxAcceptedAccuracyMeters) {
        return LocationFetchSonucu._(
          durum: StoreLocationStatus.error,
          mesaj: LocationService.buildAccuracyMessage(pos.accuracy),
        );
      }

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

  /// Next `turkeyPlaceMatcher` ile aynı güvenlik ilkesi:
  /// - alt-dize değil kelime/sınır eşleşmesi,
  /// - benzersiz ilçe kendi ilini belirleyebilir,
  /// - açıkça yazılan il ile çelişen benzersiz ilçe kabul edilmez,
  /// - birden fazla ilde bulunan ilçe (örn. Kemer) il açıkça doğrulanmadan
  ///   seçilmez,
  /// - `Merkez` tek başına il çıkarmak için kullanılmaz.
  ({String? provinceCode, String? provinceName, String? districtName})
  eslestirIlIlce(String address) {
    final normalizedAddress = TextUtils.normalizeTurkish(address);

    final provinceByCode = <String, Province>{
      for (final province in turkeyProvinces) province.code: province,
    };
    final districtCandidates =
        <String, List<({Province province, String district})>>{};

    for (final entry in turkeyDistricts.entries) {
      final province = provinceByCode[entry.key];
      if (province == null) continue;
      for (final district in entry.value) {
        if (district == 'Merkez') continue;
        final normalizedDistrict = TextUtils.normalizeTurkish(district);
        districtCandidates.putIfAbsent(normalizedDistrict, () => []).add((
          province: province,
          district: district,
        ));
      }
    }

    final provinceMatches = <({int position, Province province})>[];
    for (final province in turkeyProvinces) {
      final normalizedProvince = TextUtils.normalizeTurkish(province.name);
      final position = _boundedTermPosition(
        normalizedAddress,
        normalizedProvince,
      );
      if (position >= 0) {
        provinceMatches.add((position: position, province: province));
      }
    }
    provinceMatches.sort((a, b) => a.position.compareTo(b.position));
    final explicitProvince =
        provinceMatches.length == 1 ? provinceMatches.single.province : null;

    final districtMatches =
        <
          ({
            int position,
            String term,
            List<({Province province, String district})> candidates,
          })
        >[];

    for (final entry in districtCandidates.entries) {
      final position = _boundedTermPosition(normalizedAddress, entry.key);
      if (position < 0) continue;
      districtMatches.add((
        position: position,
        term: entry.key,
        candidates: entry.value,
      ));
    }
    districtMatches.sort(
      (a, b) =>
          a.position != b.position
              ? a.position.compareTo(b.position)
              : b.term.length.compareTo(a.term.length),
    );

    for (final match in districtMatches) {
      if (match.candidates.length == 1) {
        final candidate = match.candidates.single;
        if (explicitProvince != null &&
            candidate.province.code != explicitProvince.code) {
          continue;
        }
        return (
          provinceCode: candidate.province.code,
          provinceName: candidate.province.name,
          districtName: candidate.district,
        );
      }

      final verified =
          match.candidates.where((candidate) {
            final normalizedProvince = TextUtils.normalizeTurkish(
              candidate.province.name,
            );
            return _boundedTermPosition(
                  normalizedAddress,
                  normalizedProvince,
                ) >=
                0;
          }).toList();

      if (verified.length == 1) {
        final candidate = verified.single;
        return (
          provinceCode: candidate.province.code,
          provinceName: candidate.province.name,
          districtName: candidate.district,
        );
      }
    }

    if (provinceMatches.isNotEmpty) {
      final province = provinceMatches.first.province;
      return (
        provinceCode: province.code,
        provinceName: province.name,
        districtName: null,
      );
    }

    return (provinceCode: null, provinceName: null, districtName: null);
  }

  int _boundedTermPosition(String text, String term) {
    if (term.isEmpty) return -1;
    final pattern = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(term)}(?=\$|[^a-z0-9])',
    );
    final match = pattern.firstMatch(text);
    if (match == null) return -1;
    return match.start + (match.group(1)?.length ?? 0);
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
