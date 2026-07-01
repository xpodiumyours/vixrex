import 'package:flutter/material.dart';
import 'package:vitrinx/screens/my_vitrin/location_section.dart';

class BusinessInfoFormSection extends StatelessWidget {
  final GlobalKey nameKey;
  final Widget nameField;
  final GlobalKey whatsappKey;
  final Widget whatsappField;
  final GlobalKey locationKey;
  final String? selectedProvinceCode;
  final String? selectedDistrictName;
  final String? provinceError;
  final String? districtError;
  final String? addressError;
  final String? locationStatusMessage;
  final double? latitude;
  final double? longitude;
  final bool isLocating;
  final TextEditingController addressController;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onDistrictChanged;
  final VoidCallback onGetCurrentLocation;
  final GlobalKey descriptionKey;
  final Widget descriptionField;
  final Widget categoryDropdown;
  final String selectedKategori;
  final GlobalKey productsKey;
  final Widget? bookingSettingsSection;
  final Widget statusDropdown;
  final Widget instagramField;

  const BusinessInfoFormSection({
    super.key,
    required this.nameKey,
    required this.nameField,
    required this.whatsappKey,
    required this.whatsappField,
    required this.locationKey,
    required this.selectedProvinceCode,
    required this.selectedDistrictName,
    required this.provinceError,
    required this.districtError,
    required this.addressError,
    required this.locationStatusMessage,
    required this.latitude,
    required this.longitude,
    required this.isLocating,
    required this.addressController,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
    required this.onGetCurrentLocation,
    required this.descriptionKey,
    required this.descriptionField,
    required this.categoryDropdown,
    required this.selectedKategori,
    required this.productsKey,
    required this.bookingSettingsSection,
    required this.statusDropdown,
    required this.instagramField,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(key: nameKey, child: nameField),
        const SizedBox(height: 14),
        KeyedSubtree(key: whatsappKey, child: whatsappField),
        const SizedBox(height: 14),
        LocationSection(
          locationKey: locationKey,
          selectedProvinceCode: selectedProvinceCode,
          selectedDistrictName: selectedDistrictName,
          provinceError: provinceError,
          districtError: districtError,
          addressError: addressError,
          locationStatusMessage: locationStatusMessage,
          latitude: latitude,
          longitude: longitude,
          isLocating: isLocating,
          addressController: addressController,
          onProvinceChanged: onProvinceChanged,
          onDistrictChanged: onDistrictChanged,
          onGetCurrentLocation: onGetCurrentLocation,
        ),
        const SizedBox(height: 14),
        KeyedSubtree(key: descriptionKey, child: descriptionField),
        const SizedBox(height: 14),
        categoryDropdown,
        const SizedBox(height: 14),
        if (selectedKategori == 'Kuaför' && bookingSettingsSection != null) ...[
          KeyedSubtree(key: productsKey, child: bookingSettingsSection!),
          const SizedBox(height: 14),
        ],
        statusDropdown,
        const SizedBox(height: 14),
        instagramField,
      ],
    );
  }
}
