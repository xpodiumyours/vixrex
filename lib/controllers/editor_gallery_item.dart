import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/models/vitrin_gallery_preview_item.dart';

class EditorGalleryItem {
  final String id;
  Uint8List? bytes;
  String imageUrl;
  String? fileName;
  String extension;
  String contentType;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  EditorGalleryItem({
    required this.id,
    this.bytes,
    this.imageUrl = '',
    this.fileName,
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
    String title = '',
    String description = '',
  })  : titleController = TextEditingController(text: title),
        descriptionController = TextEditingController(text: description);

  factory EditorGalleryItem.fromStoreItem(StoreGalleryItem item) {
    return EditorGalleryItem(
      id: item.id.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : item.id,
      imageUrl: item.imageUrl,
      title: item.title,
      description: item.description,
    );
  }

  String get title => titleController.text.trim();

  String get description => descriptionController.text.trim();

  bool get hasLocalBytes => bytes != null;
  bool get hasUrl => imageUrl.trim().isNotEmpty;

  bool get hasPreviewImage => hasLocalBytes || imageUrl.trim().isNotEmpty;

  void markUploaded(String uploadedUrl) {
    imageUrl = uploadedUrl;
    bytes = null;
  }

  void replaceImageFrom(EditorGalleryItem replacement) {
    bytes = replacement.bytes;
    imageUrl = '';
    fileName = replacement.fileName;
    extension = replacement.extension;
    contentType = replacement.contentType;
  }

  StoreGalleryItem toStoreItem() {
    return StoreGalleryItem(
      id: id,
      imageUrl: imageUrl.trim(),
      title: title,
      description: description,
    );
  }

  VitrinGalleryPreviewItem toPreviewItem() {
    return VitrinGalleryPreviewItem(
      imageUrl: imageUrl,
      imageBytes: bytes,
      title: title,
      description: description,
    );
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}
