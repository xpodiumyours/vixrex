import 'package:flutter/material.dart';

class BusinessInfoFormSection extends StatelessWidget {
  final GlobalKey nameKey;
  final Widget nameField;
  final GlobalKey whatsappKey;
  final Widget whatsappField;
  final GlobalKey locationKey;
  final Widget locationField;
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
    required this.locationField,
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
        KeyedSubtree(key: locationKey, child: locationField),
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
