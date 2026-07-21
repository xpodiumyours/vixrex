import 'package:flutter/material.dart';
import 'package:vixrex/config/turkey_cities_config.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/utils/text_utils.dart';

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
  final void Function(String address) onAddressChanged;
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
    required this.onAddressChanged,
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

  bool _isInternalLocating = false;

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isInternalLocating = true;
      });
    }
    widget.onLocatingStateChanged(true);
    widget.onLocationUpdated(statusMessage: 'Konum aranıyor...');

    try {
      final result = await const LocationService().getCurrentLocation();
      if (!mounted) return;

      if (!result.isSuccess && !result.hasApproximatePosition) {
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
        final normalizedAddress = TextUtils.normalizeTurkish(geoAddress);
        Province? matchedProvince;
        for (final province in turkeyProvinces) {
          final normalizedProvince = TextUtils.normalizeTurkish(province.name);
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
            final normalizedDistrict = TextUtils.normalizeTurkish(district);
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
    } finally {
      if (mounted) {
        setState(() {
          _isInternalLocating = false;
        });
        widget.onLocatingStateChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocatingActive = widget.isLocating || _isInternalLocating;
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: widget.selectedProvinceCode,
          dropdownColor: inputBg,
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'İl seçiniz',
            hintStyle: const TextStyle(color: softText, fontSize: 13),
            errorText: widget.provinceError,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            filled: true,
            fillColor: inputBg,
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
              vertical: 12,
            ),
          ),
          items: turkeyProvinces.map((province) {
            return DropdownMenuItem<String>(
              value: province.code,
              child: Text(province.name),
            );
          }).toList(),
          onChanged: (code) {
            final found = turkeyProvinces.firstWhere(
              (p) => p.code == code,
              orElse: () => const Province('', ''),
            );
            widget.onProvinceChanged(
              code,
              found.name.isNotEmpty ? found.name : null,
            );
          },
        ),
        const SizedBox(height: 14),

        // Dropdown: İlçe
        Row(
          children: [
            const Text(
              'İlçe',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: widget.selectedDistrictCode,
          dropdownColor: inputBg,
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.selectedProvinceCode == null
                ? 'Önce il seçiniz'
                : 'İlçe seçiniz',
            hintStyle: const TextStyle(color: softText, fontSize: 13),
            errorText: widget.districtError,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            filled: true,
            fillColor: inputBg,
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
              vertical: 12,
            ),
          ),
          items: districts.map((district) {
            return DropdownMenuItem<String>(
              value: district,
              child: Text(district),
            );
          }).toList(),
          onChanged: widget.selectedProvinceCode == null
              ? null
              : (val) {
                  widget.onDistrictChanged(val, val);
                },
        ),
        const SizedBox(height: 14),

        // TextField: Açık Adres
        Row(
          children: [
            const Text(
              'Açık Adres (Mahalle, Cadde, Sokak, No)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.addressController,
          onChanged: widget.onAddressChanged,
          style: const TextStyle(
            color: darkText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Örn: Çatalmeşe Mah. 207. Sokak No: 12',
            hintStyle: const TextStyle(color: softText, fontSize: 13),
            errorText: widget.addressError,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            filled: true,
            fillColor: inputBg,
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
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: OutlinedButton(
            onPressed: isLocatingActive ? null : _getCurrentLocation,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isLocatingActive ? const Color(0xFF0EA5E9) : primaryColor,
                width: isLocatingActive ? 1.8 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: isLocatingActive
                ? const _ScanningLocationWidget()
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'GPS ile Konumumu Al',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
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

class _ScanningLocationWidget extends StatefulWidget {
  const _ScanningLocationWidget();

  @override
  State<_ScanningLocationWidget> createState() => _ScanningLocationWidgetState();
}

class _ScanningLocationWidgetState extends State<_ScanningLocationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _controller,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withAlpha(140),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 16,
                  color: Color(0xFF0EA5E9),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'GPS Taranıyor...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        );
      },
    );
  }
}


