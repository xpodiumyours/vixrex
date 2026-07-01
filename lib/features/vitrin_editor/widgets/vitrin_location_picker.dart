import 'package:flutter/material.dart';
import 'package:vitrinx/config/turkey_cities_config.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Konum seçimi widget'ı: il/ilçe dropdown'ları, açık adres ve GPS butonu.
class VitrinLocationPicker extends StatelessWidget {
  final String? selectedProvinceCode;
  final String? selectedProvinceName;
  final String? selectedDistrictName;
  final String? provinceError;
  final String? districtError;
  final String? addressError;
  final TextEditingController addressController;
  final bool isLocating;
  final String? locationStatusMessage;
  final double? latitude;
  final double? longitude;
  final void Function(String? code, String? name) onProvinceChanged;
  final void Function(String? code, String? name) onDistrictChanged;
  final VoidCallback onGetLocation;

  static const Color _primaryColor = AppColors.primary;
  static const Color _softText = AppColors.softText;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.cardBorderDark;

  const VitrinLocationPicker({
    super.key,
    required this.selectedProvinceCode,
    required this.selectedProvinceName,
    required this.selectedDistrictName,
    required this.provinceError,
    required this.districtError,
    required this.addressError,
    required this.addressController,
    required this.isLocating,
    required this.locationStatusMessage,
    required this.latitude,
    required this.longitude,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onGetLocation,
  });

  @override
  Widget build(BuildContext context) {
    final districts =
        selectedProvinceCode != null
            ? (turkeyDistricts[selectedProvinceCode] ?? <String>[])
            : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('İl', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedProvinceCode,
          decoration: _inputDecoration(
            errorText: provinceError,
            prefixIcon: const Icon(Icons.map_rounded, color: _mutedText, size: 18),
          ),
          hint: const Text(
            'İl Seçiniz',
            style: TextStyle(fontSize: 14, color: _mutedText),
          ),
          items: turkeyProvinces.map((p) {
            return DropdownMenuItem<String>(
              value: p.code,
              child: Text(
                p.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            final name =
                val != null
                    ? turkeyProvinces.firstWhere((p) => p.code == val).name
                    : '';
            onProvinceChanged(val, val != null ? name : null);
          },
        ),
        const SizedBox(height: 14),
        _label('İlçe', required: true),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedDistrictName,
          decoration: _inputDecoration(
            errorText: districtError,
            prefixIcon: const Icon(
              Icons.location_city_rounded,
              color: _mutedText,
              size: 18,
            ),
          ),
          hint: const Text(
            'İlçe Seçiniz',
            style: TextStyle(fontSize: 14, color: _mutedText),
          ),
          disabledHint: const Text(
            'Önce İl Seçiniz',
            style: TextStyle(fontSize: 14, color: _mutedText),
          ),
          items: districts.map((d) {
            return DropdownMenuItem<String>(
              value: d,
              child: Text(
                d,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                ),
              ),
            );
          }).toList(),
          onChanged:
              selectedProvinceCode == null
                  ? null
                  : (val) => onDistrictChanged(val, val),
        ),
        const SizedBox(height: 14),
        _label('Açık Adres (Mahalle, Cadde, Sokak, No)', required: true),
        const SizedBox(height: 8),
        TextField(
          controller: addressController,
          style: const TextStyle(
            color: _darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.location_on_rounded,
              color: _mutedText,
              size: 18,
            ),
            hintText: 'Örn: Atatürk Mah. Fatih Cad. No:12 D:4',
            hintStyle: TextStyle(
              color: _mutedText.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: _inputBg,
            errorText: addressError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primaryColor, width: 1.4),
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
            onPressed: isLocating ? null : onGetLocation,
            icon:
                isLocating
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryColor,
                      ),
                    )
                    : const Icon(
                      Icons.my_location_rounded,
                      size: 16,
                      color: _primaryColor,
                    ),
            label: Text(
              isLocating ? 'Konum alınıyor...' : '📡 GPS ile Konumumu Al',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
        ),
        if (locationStatusMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            locationStatusMessage!,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (latitude != null && longitude != null) ...[
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
                'Koordinat kaydedildi (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})',
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

  Widget _label(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: _softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w900),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? errorText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: _inputBg,
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _cardBorder),
      ),
    );
  }
}
