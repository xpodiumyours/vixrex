import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

class FormContactInfo extends StatelessWidget {
  final StoreEditorController controller;
  final MyVitrinState state;
  final TextEditingController whatsappController;
  final TextEditingController instaController;

  const FormContactInfo({
    super.key,
    required this.controller,
    required this.state,
    required this.whatsappController,
    required this.instaController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: state.whatsappKey,
          child: EditorTextField(
            label: 'WhatsApp Numarası',
            controller: whatsappController,
            focusNode: state.whatsappFocusNode,
            hint: '05xx xxx xx xx',
            icon: Icons.chat_bubble_rounded,
            keyboardType: TextInputType.phone,
            requiredField: true,
            errorText: controller.whatsappError,
            onChanged: (v) {
              controller.updateWhatsapp(v);
              controller.clearValidationErrors();
            },
          ),
        ),
        const SizedBox(height: 14),
        EditorTextField(
          label: 'Instagram',
          controller: instaController,
          hint: '@kullanici_adi veya profil linki',
          icon: Icons.camera_alt_rounded,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}
