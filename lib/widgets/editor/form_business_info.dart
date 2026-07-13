import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

class FormBusinessInfo extends StatelessWidget {
  final StoreEditorController controller;
  final MyVitrinState state;
  final TextEditingController nameController;
  final TextEditingController descController;

  const FormBusinessInfo({
    super.key,
    required this.controller,
    required this.state,
    required this.nameController,
    required this.descController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        const SizedBox(height: 14),
        KeyedSubtree(
          key: state.descriptionKey,
          child: EditorTextField(
            label: 'Kısa Açıklama',
            controller: descController,
            focusNode: state.descriptionFocusNode,
            hint: 'Bugün vitrinde ne var? Kısa bir tanıtım yaz.',
            icon: Icons.notes_rounded,
            maxLines: 3,
            onChanged: (_) => controller.clearValidationErrors(),
          ),
        ),
      ],
    );
  }
}
