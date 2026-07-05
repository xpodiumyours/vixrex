import 'package:flutter/material.dart';
import 'package:vixrex/models/vitrin_gallery_preview_item.dart';

class VitrinGalleryImage extends StatelessWidget {
  final VitrinGalleryPreviewItem item;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const VitrinGalleryImage({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = item.imageBytes;
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        filterQuality: FilterQuality.medium,
      );
    }

    return Image.network(
      item.imageUrl.trim(),
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: errorBuilder,
    );
  }
}
