import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/services/category_image_service.dart';
import 'package:vixrex/utils/gallery_image_file_validator.dart';
import 'package:vixrex/widgets/auto_fill/category_gallery_sheet.dart';
import 'package:vixrex/widgets/editor/form_media_picker.dart';
import 'package:vixrex/widgets/editor/gallery_editor_section.dart';

/// Görseller bölümü — kapak fotoğrafı ve galeri.
///
/// Faz 0 kalanı (Tek Asistan planı): vitrin_form_section.dart'ın altı bölüm
/// gövdesinden biri. Görsel seçme/doğrulama mantığı (FilePicker, kamera,
/// kategori galerisi) yalnız bu bölümde kullanıldığı için buraya taşındı.
class GorsellerBolumu extends StatelessWidget {
  const GorsellerBolumu({
    super.key,
    required this.controller,
    required this.state,
    required this.galleryKickerController,
    required this.galleryTitleController,
    required this.galleryActionLabelController,
    required this.galleryActionHrefController,
  });

  final StoreEditorController controller;
  final MyVitrinState state;
  final TextEditingController galleryKickerController;
  final TextEditingController galleryTitleController;
  final TextEditingController galleryActionLabelController;
  final TextEditingController galleryActionHrefController;

  /// EditorGalleryItem → GalleryItem dönüşümü (GalleryEditorSection uyumluluğu)
  List<GalleryItem> get _galleryItemsForEditor =>
      controller.galleryItems
          .map(
            (e) => GalleryItem(
              id: e.id,
              bytes: e.bytes,
              imageUrl: e.imageUrl ?? '',
              extension: e.extension ?? 'jpg',
              contentType: e.contentType ?? 'image/jpeg',
              title: e.title ?? '',
              isRemoved: e.isRemoved,
            ),
          )
          .toList();

  /// GalleryItem → EditorGalleryItem dönüşümü (controller uyumluluğu)
  List<EditorGalleryItem> _toEditorItems(List<GalleryItem> items) =>
      items
          .where((e) => e.bytes != null)
          .map(
            (e) => EditorGalleryItem(
              id: e.id,
              bytes: e.bytes,
              extension: e.extension,
              contentType: e.contentType,
              title: e.title.trim().isEmpty ? null : e.title.trim(),
            ),
          )
          .toList();

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: state.categoryKey,
      child: FormMediaPicker(
        controller: controller,
        state: state,
        galleryItems: _galleryItemsForEditor,
        galleryKickerController: galleryKickerController,
        galleryTitleController: galleryTitleController,
        galleryActionLabelController: galleryActionLabelController,
        galleryActionHrefController: galleryActionHrefController,
        onPickCover: () => _pickCover(context),
        onPickCoverFromCamera: () => _pickCoverFromCamera(context),
        onAutoFillCover:
            () => _showCategoryGallery(
              context,
              source: SheetImageSource.coverPicker,
            ),
        onPickGallery: () => _pickGallery(context),
        onGalleryTitleChanged: (index, title) {
          controller.updateGalleryItemTitle(index, title);
          controller.saveLocally();
        },
        onGalleryActionLabelChanged: controller.updateGalleryActionLabel,
        onGalleryActionHrefChanged: controller.updateGalleryActionHref,
      ),
    );
  }

  /// Kategori galerisi bottom sheet'ini açar
  Future<void> _showCategoryGallery(
    BuildContext ctx, {
    required SheetImageSource source,
  }) async {
    final kategori = controller.selectedKategori.trim();
    final preferredKey =
        kategori.isNotEmpty ? mapKategoriToKey(kategori) : null;

    await CategoryGallerySheet.show(
      context: ctx,
      preferredCategoryKey: preferredKey,
      source: source,
      onImageAction: (url, action, categoryKey) {
        switch (action) {
          case ImageAction.setAsCover:
            controller.setCoverUrl(url);
            if (categoryKey != null && categoryKey.trim().isNotEmpty) {
              final label = BusinessCategoryConfig.labelForKey(categoryKey);
              if (label != null) {
                controller.selectCategory(label);
              }
            }
            controller.saveLocally();
            break;
          case ImageAction.addToGallery:
            controller.addGalleryUrl(url);
            break;
        }
      },
    );
  }

  Future<void> _pickCover(BuildContext ctx) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!ctx.mounted) return;
    final file = result.files.single;
    final v = GalleryImageFileValidator.validate(
      bytes: file.bytes,
      reportedSize: file.size,
    );
    if (!v.isValid || file.bytes == null) {
      state.showSnackBar(
        ctx,
        'Fotoğraf eklenemedi. JPG, PNG veya WEBP, en fazla 15 MB.',
      );
      return;
    }
    controller.setCoverBytes(
      file.bytes!,
      file.name,
      v.fileInfo?.extension ?? 'jpg',
      v.fileInfo?.contentType ?? 'image/jpeg',
    );
  }

  Future<void> _pickCoverFromCamera(BuildContext ctx) async {
    try {
      final picker = img_picker.ImagePicker();
      final pickedFile = await picker.pickImage(
        source: img_picker.ImageSource.camera,
      );
      if (pickedFile == null) return;
      final bytes = await pickedFile.readAsBytes();
      final size = bytes.length;
      final v = GalleryImageFileValidator.validate(
        bytes: bytes,
        reportedSize: size,
      );
      if (!ctx.mounted) return;
      if (!v.isValid) {
        state.showSnackBar(
          ctx,
          'Fotoğraf eklenemedi. JPG, PNG veya WEBP, en fazla 15 MB.',
        );
        return;
      }
      controller.setCoverBytes(
        bytes,
        pickedFile.name,
        v.fileInfo?.extension ?? 'jpg',
        v.fileInfo?.contentType ?? 'image/jpeg',
      );
    } catch (_) {
      if (ctx.mounted) {
        state.showSnackBar(
          ctx,
          'Kameraya erişilemedi. Kamera izinlerini kontrol edin veya dosya yüklemeyi kullanın.',
        );
      }
    }
  }

  Future<void> _pickGallery(BuildContext ctx) async {
    final remaining =
        controller.maxGalleryPhotos - controller.galleryItems.length;
    if (remaining <= 0) {
      state.showSnackBar(
        ctx,
        'En fazla ${controller.maxGalleryPhotos} galeri fotoğrafı eklenebilir.',
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!ctx.mounted) return;
    var rejected = 0;
    final newItems = <GalleryItem>[];
    for (final file in result.files.take(remaining)) {
      final v = GalleryImageFileValidator.validate(
        bytes: file.bytes,
        reportedSize: file.size,
      );
      if (!v.isValid || file.bytes == null) {
        rejected++;
        continue;
      }
      newItems.add(
        GalleryItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_${newItems.length}',
          bytes: file.bytes,
          imageUrl: '',
          extension: v.fileInfo?.extension ?? 'jpg',
          contentType: v.fileInfo?.contentType ?? 'image/jpeg',
        ),
      );
    }
    final editorItems = [
      ...controller.galleryItems,
      ..._toEditorItems(newItems),
    ];
    controller.setGalleryItems(editorItems);
    if (rejected > 0) state.showSnackBar(ctx, '$rejected fotoğraf eklenemedi.');
  }
}
