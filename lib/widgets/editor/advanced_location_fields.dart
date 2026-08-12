import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

/// Manuel vitrin paneline ait isteğe bağlı konum sunum alanları.
///
/// İl, ilçe, açık adres ve GPS akışı `LocationEditorSection` içinde kalır.
/// Bu alanlar kurulum için zorunlu değildir; yalnız ayrıntılı manuel formda
/// gösterilir ve doğrudan vitrin verisine yazılır.
class AdvancedLocationFields extends StatelessWidget {
  final StoreEditorController controller;
  final TextEditingController heroLocationTextController;
  final TextEditingController mapLabelController;

  const AdvancedLocationFields({
    super.key,
    required this.controller,
    required this.heroLocationTextController,
    required this.mapLabelController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorTextField(
          label: 'Hero Konum Metni',
          controller: heroLocationTextController,
          hint: 'Örn: Kadıköy, İstanbul',
          icon: Icons.place_outlined,
          maxLength: 60,
          onChanged:
              (value) =>
                  controller.updateHeroLocationText(controller.data, value),
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: 'Harita Kartı Etiketi',
          controller: mapLabelController,
          hint: 'Örn: Atatürk Cad. No:24',
          icon: Icons.map_outlined,
          maxLength: 120,
          onChanged:
              (value) => controller.updateMapLabel(controller.data, value),
        ),
      ],
    );
  }
}
