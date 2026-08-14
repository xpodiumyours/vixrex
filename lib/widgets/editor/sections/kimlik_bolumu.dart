import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';
import 'package:vixrex/widgets/editor/sections/spaced_column.dart';

/// Kimlik bölümü — ad, işletme türü, kısa açıklama, kapak rozeti.
///
/// Faz 0 kalanı (Tek Asistan planı): vitrin_form_section.dart'ın (51KB)
/// altı bölüm gövdesinden biri. Yalnız [StoreEditorController]'ı ve ilgili
/// metin denetleyicilerini prop olarak alır — kendi içinde context.read
/// yapmaz, test edilebilir kalır.
class KimlikBolumu extends StatelessWidget {
  const KimlikBolumu({
    super.key,
    required this.controller,
    required this.state,
    required this.nameController,
    required this.businessTypeController,
    required this.descriptionController,
    required this.heroBadgeController,
  });

  final StoreEditorController controller;
  final MyVitrinState state;
  final TextEditingController nameController;
  final TextEditingController businessTypeController;
  final TextEditingController descriptionController;
  final TextEditingController heroBadgeController;

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
      children: [
        KeyedSubtree(
          key: state.nameKey,
          child: EditorTextField(
            label: 'İşletme / Vixrex Adı',
            controller: nameController,
            focusNode: state.nameFocusNode,
            hint: 'Örn: Aymira Butik',
            icon: Icons.storefront_rounded,
            requiredField: true,
            errorText: controller.nameError,
            onChanged: (v) {
              controller.updateName(v);
              controller.clearValidationErrors();
            },
          ),
        ),
        EditorTextField(
          label: 'İşletme Türü',
          controller: businessTypeController,
          hint: 'Örn: Kadın giyim / butik',
          icon: Icons.storefront_outlined,
          maxLength: 40,
          onChanged: (v) => controller.updateBusinessType(v),
        ),
        KeyedSubtree(
          key: state.descriptionKey,
          child: EditorTextField(
            label: 'Kısa Açıklama',
            controller: descriptionController,
            focusNode: state.descriptionFocusNode,
            hint: 'Bugün vitrinde ne var? Kısa bir tanıtım yaz.',
            icon: Icons.notes_rounded,
            maxLines: 3,
            onChanged: (v) {
              controller.setDescription(v);
              controller.clearValidationErrors();
            },
          ),
        ),
        EditorTextField(
          label: 'Kapak Rozeti',
          controller: heroBadgeController,
          hint: 'Örn: Atölye / Mağaza',
          icon: Icons.sell_outlined,
          onChanged: (v) => controller.updateHeroBadge(v),
        ),
      ],
    );
  }
}
