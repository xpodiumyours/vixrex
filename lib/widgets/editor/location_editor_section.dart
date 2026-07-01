import 'package:flutter/material.dart';
import 'package:vitrinx/config/turkey_cities_config.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/services/location_service.dart';

class LocationEditorSection extends StatefulWidget {
  final String? selectedProvinceCode;
  final String? selectedProvinceName;
  final String? selectedDistrictCode;
  final String? selectedDistrictName;
  final String? provinceError;
  final String? districtError;
  final String? addressError;
  final TextEditingController addressController;

  final double? latitude;
  final double? longitude;
  final double? locationAccuracyMeters;
  final String? locationStatusMessage;
  final bool isLocating;

  final void Function(String? provinceCode, String? provinceName) onProvinceChanged;
  final void Function(String? districtCode, String? districtName) onDistrictChanged;
  final void Function({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? statusMessage,
    String? address,
    String? provinceCode,
    String? provinceName,
    String? districtCode,
    String? districtName,
  }) onLocationUpdated;
  final void Function(bool locating) onLocatingStateChanged;

  const LocationEditorSection({
    super.key,
    required this.selectedProvinceCode,
    required this.selectedProvinceName,
    required this.selectedDistrictCode,
    required this.selectedDistrictName,
    required this.provinceError,
    required this.districtError,
    required this.addressError,
    required this.addressController,
    required this.latitude,
    required this.longitude,
    required this.locationAccuracyMeters,
    required this.locationStatusMessage,
    required this.isLocating,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onLocationUpdated,
    required this.onLocatingStateChanged,
  });

  @override
  State<LocationEditorSection> createState() => _LocationEditorSectionState();
}

class _LocationEditorSectionState extends State<LocationEditorSection> {
  static const Color primaryColor = AppColors.primary;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;
  static const Color softText = AppColors.softText;
  static const Color cardBorder = AppColors.cardBorderDark;
  static const Color inputBg = AppColors.inputBg;

  String _normalizeTurkish(String text) {
    return text
        .toLowerCase()
        .replaceAll('i', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  Future<void> _getCurrentLocation() async {
    widget.onLocatingStateChanged(true);
    widget.onLocationUpdated(statusMessage: 'Konum aranıyor...');

    final result = await const LocationService().getCurrentLocation();
    if (!mounted) return;

    if (!result.isSuccess && !result.hasApproximatePosition) {
      widget.onLocatingStateChanged(false);
      widget.onLocationUpdated(statusMessage: result.errorMessage);
      return;
    }

    final position = result.position ?? result.approximatePosition!;
    widget.onLocationUpdated(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      statusMessage: 'Adres çözümleniyor...',
    );

    final geoAddress = await const LocationService().getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (!mounted) return;

    String? updatedProvinceCode = widget.selectedProvinceCode;
    String? updatedProvinceName = widget.selectedProvinceName;
    String? updatedDistrictCode = widget.selectedDistrictCode;
    String? updatedDistrictName = widget.selectedDistrictName;
    String? newAddress = geoAddress;

    if (geoAddress != null && geoAddress.isNotEmpty) {
      // Auto-detect Province and District
      final normalizedAddress = _normalizeTurkish(geoAddress);
      Province? matchedProvince;
      for (final province in turkeyProvinces) {
        final normalizedProvince = _normalizeTurkish(province.name);
        if (normalizedAddress.contains(normalizedProvince)) {
          matchedProvince = province;
          break;
        }
      }

      if (matchedProvince != null) {
        updatedProvinceCode = matchedProvince.code;
        updatedProvinceName = matchedProvince.name;

        final districts = turkeyDistricts[matchedProvince.code] ?? [];
        String? matchedDistrict;
        for (final district in districts) {
          final normalizedDistrict = _normalizeTurkish(district);
          if (normalizedAddress.contains(normalizedDistrict)) {
            matchedDistrict = district;
            break;
          }
        }
        if (matchedDistrict != null) {
          updatedDistrictCode = matchedDistrict;
          updatedDistrictName = matchedDistrict;
        } else {
          updatedDistrictCode = null;
          updatedDistrictName = null;
        }
      }
    }

    widget.onLocatingStateChanged(false);
    widget.onLocationUpdated(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      statusMessage: LocationService.buildAccuracyMessage(position.accuracy),
      address: newAddress,
      provinceCode: updatedProvinceCode,
      provinceName: updatedProvinceName,
      districtCode: updatedDistrictCode,
      districtName: updatedDistrictName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = widget.selectedProvinceCode != null
        ? (turkeyDistricts[widget.selectedProvinceCode] ?? [])
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown: İl
        Row(
          children: [
            const Text(
              'İl',
              style: TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.selectedProvinceCode,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.map_rounded,
              color: mutedText,
              size: 18,
            ),
            filled: true,
            fillColor: inputBg,
            errorText: widget.provinceError,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
          ),
          hint: const Text(
            'İl Seçiniz',
            style: TextStyle(fontSize: 14, color: mutedText),
          ),
          items: turkeyProvinces.map((p) {
            return DropdownMenuItem<String>(
              value: p.code,
              child: Text(
                p.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            final pName = val != null
                ? turkeyProvinces.firstWhere((p) => p.code == val).name
                : '';
            widget.onProvinceChanged(val, pName);
          },
        ),
        const SizedBox(height: 14),

        // Dropdown: İlçe
        Row(
          children: [
            const Text(
              'İlçe',
              style: TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.selectedDistrictName,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.location_city_rounded,
              color: mutedText,
              size: 18,
            ),
            filled: true,
            fillColor: inputBg,
            errorText: widget.districtError,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
          ),
          hint: const Text(
            'İlçe Seçiniz',
            style: TextStyle(fontSize: 14, color: mutedText),
          ),
          disabledHint: const Text(
            'Önce İl Seçiniz',
            style: TextStyle(fontSize: 14, color: mutedText),
          ),
          items: districts.map((d) {
            return DropdownMenuItem<String>(
              value: d,
              child: Text(
                d,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            );
          }).toList(),
          onChanged: widget.selectedProvinceCode == null
              ? null
              : (val) {
                  widget.onDistrictChanged(val, val);
                },
        ),
        const SizedBox(height: 14),

        // Detailed Address Field
        Row(
          children: [
            const Text(
              'Açık Adres (Mahalle, Cadde, Sokak, No)',
              style: TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.addressController,
          style: const TextStyle(
            color: darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.location_on_rounded,
              color: mutedText,
              size: 18,
            ),
            hintText: 'Örn: Atatürk Mah. Fatih Cad. No:12 D:4',
            hintStyle: TextStyle(
              color: mutedText.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: inputBg,
            errorText: widget.addressError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: widget.isLocating ? null : _getCurrentLocation,
            icon: widget.isLocating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
            label: Text(
              widget.isLocating ? 'Konum alınıyor...' : '📡 GPS ile Konumumu Al',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
        if (widget.locationStatusMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.locationStatusMessage!,
            style: const TextStyle(
              color: mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (widget.latitude != null && widget.longitude != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 4),
              Text(
                'Koordinat kaydedildi (${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)})',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
