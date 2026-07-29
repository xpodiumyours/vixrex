import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';
import 'package:vixrex/widgets/editor/cover_picker_section.dart';
import 'package:vixrex/widgets/editor/gallery_editor_section.dart';

class FormMediaPicker extends StatelessWidget {
  final StoreEditorController controller;
  final MyVitrinState state;
  final List<GalleryItem> galleryItems;
  final TextEditingController galleryKickerController;
  final TextEditingController galleryTitleController;
  final VoidCallback onPickCover;
  final VoidCallback onPickCoverFromCamera;
  final VoidCallback onAutoFillCover;
  final VoidCallback onPickGallery;
  final void Function(int index, String title)? onGalleryTitleChanged;

  const FormMediaPicker({
    super.key,
    required this.controller,
    required this.state,
    required this.galleryItems,
    required this.galleryKickerController,
    required this.galleryTitleController,
    required this.onPickCover,
    required this.onPickCoverFromCamera,
    required this.onAutoFillCover,
    required this.onPickGallery,
    this.onGalleryTitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: state.coverPhotoKey,
          child: CoverPickerSection(
            coverBytes: controller.coverBytes,
            coverUrl: controller.coverUrl,
            coverFileName: controller.coverFileName,
            onTap: onPickCover,
            onCameraTap: onPickCoverFromCamera,
            onAutoFillTap: onAutoFillCover,
          ),
        ),
        const SizedBox(height: 14),
        EditorTextField(
          label: 'Galeri üst etiketi',
          controller: galleryKickerController,
          hint: 'Örn: Mağazadan kareler',
          icon: Icons.label_outline_rounded,
          onChanged: (value) {
            controller.updateGallerySectionMeta(
              kicker: value,
              title: galleryTitleController.text,
            );
          },
        ),
        const SizedBox(height: 12),
        EditorTextField(
          label: 'Galeri başlığı',
          controller: galleryTitleController,
          hint: 'Örn: Atmosferi yakından tanı',
          icon: Icons.title_rounded,
          onChanged: (value) {
            controller.updateGallerySectionMeta(
              kicker: galleryKickerController.text,
              title: value,
            );
          },
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: state.galleryKey,
          child: GalleryEditorSection(
            galleryItems: galleryItems,
            maxGalleryPhotos: controller.maxGalleryPhotos,
            onPickPhotos: onPickGallery,
            onRemovePhoto: controller.removeGalleryItem,
            onTitleChanged: onGalleryTitleChanged,
          ),
        ),
      ],
    );
  }
}
