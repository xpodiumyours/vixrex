import 'package:flutter/material.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/widgets/editor/cover_picker_section.dart';
import 'package:vixrex/widgets/editor/gallery_editor_section.dart';

class FormMediaPicker extends StatelessWidget {
  final StoreEditorController controller;
  final MyVitrinState state;
  final List<GalleryItem> galleryItems;
  final VoidCallback onPickCover;
  final VoidCallback onPickCoverFromCamera;
  final VoidCallback onAutoFillCover;
  final VoidCallback onPickGallery;

  const FormMediaPicker({
    super.key,
    required this.controller,
    required this.state,
    required this.galleryItems,
    required this.onPickCover,
    required this.onPickCoverFromCamera,
    required this.onAutoFillCover,
    required this.onPickGallery,
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
        const SizedBox(height: 10),
        KeyedSubtree(
          key: state.galleryKey,
          child: GalleryEditorSection(
            galleryItems: galleryItems,
            maxGalleryPhotos: controller.maxGalleryPhotos,
            onPickPhotos: onPickGallery,
            onRemovePhoto: controller.removeGalleryItem,
          ),
        ),
      ],
    );
  }
}
