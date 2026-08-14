import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';
import 'package:vixrex/widgets/editor/sections/spaced_column.dart';

/// İletişim bölümü — WhatsApp, telefon, e-posta, Instagram.
///
/// Faz 0 kalanı (Tek Asistan planı): vitrin_form_section.dart'ın altı bölüm
/// gövdesinden biri.
class IletisimBolumu extends StatelessWidget {
  const IletisimBolumu({
    super.key,
    required this.controller,
    required this.state,
    required this.whatsappController,
    required this.phoneController,
    required this.emailController,
    required this.instagramController,
  });

  final StoreEditorController controller;
  final MyVitrinState state;
  final TextEditingController whatsappController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController instagramController;

  @override
  Widget build(BuildContext context) {
    return SpacedColumn(
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
        EditorTextField(
          label: 'Telefon',
          controller: phoneController,
          hint: '05xx xxx xx xx (isteğe bağlı)',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          onChanged: (v) => controller.updatePhone(v),
        ),
        EditorTextField(
          label: 'E-posta',
          controller: emailController,
          hint: 'ornek@isletme.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => controller.updateEmail(v),
        ),
        EditorTextField(
          label: 'Instagram',
          controller: instagramController,
          hint: '@kullanici_adi veya profil linki',
          icon: Icons.camera_alt_rounded,
          keyboardType: TextInputType.url,
          onChanged: (v) => controller.updateInstagram(v),
        ),
      ],
    );
  }
}
