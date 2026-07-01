import 'package:flutter/material.dart';

class CoverGallerySection extends StatelessWidget {
  final GlobalKey coverPhotoKey;
  final Widget coverPicker;
  final GlobalKey galleryKey;
  final Widget compactGalleryRow;

  const CoverGallerySection({
    super.key,
    required this.coverPhotoKey,
    required this.coverPicker,
    required this.galleryKey,
    required this.compactGalleryRow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(key: coverPhotoKey, child: coverPicker),
        const SizedBox(height: 10),
        KeyedSubtree(key: galleryKey, child: compactGalleryRow),
        const SizedBox(height: 18),
      ],
    );
  }
}
