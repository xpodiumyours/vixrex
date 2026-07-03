import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/app_constants.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/utils/image_helper.dart';

class EditorGalleryItem {
  final String id;
  final Uint8List? bytes;
  final String? imageUrl;
  final String? extension;
  final String? contentType;
  final int? originalWidth;
  final int? originalHeight;
  final bool isRemoved;

  const EditorGalleryItem._({
    required this.id,
    this.bytes,
    this.imageUrl,
    this.extension,
    this.contentType,
    this.originalWidth,
    this.originalHeight,
    this.isRemoved = false,
  });

  /// Yeni fotoğraf ekleme (cihazdan seçim)
  factory EditorGalleryItem.fromBytes({
    required String id,
    required Uint8List bytes,
    required String extension,
    required String contentType,
    int? originalWidth,
    int? originalHeight,
  }) {
    return EditorGalleryItem._(
      id: id,
      bytes: bytes,
      extension: extension,
      contentType: contentType,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
    );
  }

  /// Var olan URL'den (DB'den gelen)
  factory EditorGalleryItem.fromUrl(String url, {String? id}) {
    return EditorGalleryItem._(
      id: id ?? url,
      imageUrl: url,
    );
  }

  /// StoreGalleryItem'dan
  factory EditorGalleryItem.fromStoreItem(StoreGalleryItem item) {
    return EditorGalleryItem._(
      id: item.id,
      imageUrl: item.imageUrl,
    );
  }

  /// Kaldırma işareti
  EditorGalleryItem markRemoved() {
    return EditorGalleryItem._(
      id: id,
      bytes: bytes,
      imageUrl: imageUrl,
      extension: extension,
      contentType: contentType,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      isRemoved: true,
    );
  }

  /// Kapak fotoğrafı kontrolü
  bool get isFromUrl => imageUrl != null && imageUrl!.isNotEmpty;
  bool get isFromBytes => bytes != null;
  bool get isEmpty => !isFromUrl && !isFromBytes;
}

class StoreEditorController extends ChangeNotifier {
  final StoreData _data;
  StorePublishedInfo? _publishedInfo;
  bool _isLoading = false;

  // Kapak Fotoğrafı
  Uint8List? _coverBytes;
  String? _coverFileName;
  String? _coverUrl;

  // Galeri
  List<EditorGalleryItem> _editorGalleryItems = [];
  int _maxGalleryPhotos = AppConstants.maxGalleryPhotos;

  StoreEditorController(this._data) {
    _initialize();
  }

  StoreData get data => _data;
  StorePublishedInfo? get publishedInfo => _publishedInfo;
  bool get isLoading => _isLoading;
  int get maxGalleryPhotos => _maxGalleryPhotos;

  // Kapak Fotoğrafı
  Uint8List? get coverBytes => _coverBytes;
  String? get coverFileName => _coverFileName;
  String? get coverUrl => _coverUrl;
  String? get coverUrlOrNull => _coverUrl;
  bool get hasCover => _coverBytes != null || (_coverUrl != null && _coverUrl!.isNotEmpty);

  // Galeri
  List<EditorGalleryItem> get editorGalleryItems => _editorGalleryItems;
  List<EditorGalleryItem> get activeGalleryItems =>
      _editorGalleryItems.where((item) => !item.isRemoved).toList();
  List<String> get removedGalleryUrls => _editorGalleryItems
      .where((item) => item.isRemoved && item.imageUrl != null)
      .map((item) => item.imageUrl!)
      .toList();
  List<String> get galleryPhotoUrls => _editorGalleryItems
      .where((item) => item.imageUrl != null && !item.isRemoved)
      .map((item) => item.imageUrl!)
      .toList();

  // İşletme Adı
  String get currentName => _data.name;

  // Kategori
  String get selectedKategori => _data.kategori;

  // Açıklama
  String get currentDescription => _data.description;

  // Ürün/Hizmet
  List<StoreProduct> get products => _data.products;
  bool get hasProducts => _data.products.isNotEmpty;

  void _initialize() {
    _coverUrl = _data.shelfImageUrl.isNotEmpty ? _data.shelfImageUrl : null;
    _editorGalleryItems = _data.galleryItems.map((item) => EditorGalleryItem.fromStoreItem(item)).toList();
  }

  void setPublishedInfo(StorePublishedInfo? info) {
    _publishedInfo = info;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Kapak Fotoğrafı İşlemleri
  void setCoverBytes(Uint8List bytes, String fileName) {
    _coverBytes = bytes;
    _coverFileName = fileName;
    _coverUrl = null;
    notifyListeners();
  }

  /// Kapak gorselini URL ile set et (hazir sablon gorselleri icin)
  void setCoverUrl(String url) {
    _coverUrl = url;
    _coverBytes = null;
    _coverFileName = null;
    notifyListeners();
  }

  void clearCoverBytes() {
    _coverBytes = null;
    _coverFileName = null;
    notifyListeners();
  }

  // Galeri İşlemleri
  void setGalleryItems(List<EditorGalleryItem> items) {
    _editorGalleryItems = items;
    notifyListeners();
  }

  void addGalleryItem(EditorGalleryItem item) {
    if (_editorGalleryItems.length < _maxGalleryPhotos) {
      _editorGalleryItems.add(item);
      notifyListeners();
    }
  }

  void removeGalleryItem(int index) {
    if (index >= 0 && index < _editorGalleryItems.length) {
      final item = _editorGalleryItems[index];
      if (item.isFromUrl) {
        _editorGalleryItems[index] = item.markRemoved();
      } else {
        _editorGalleryItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  // İşletme Adı İşlemleri
  void setName(String name) {
    _data.name = name;
    notifyListeners();
  }

  // Kategori İşlemleri
  void selectCategory(String kategori) {
    _data.kategori = kategori;
    notifyListeners();
  }

  // Açıklama İşlemleri
  void setDescription(String description) {
    _data.description = description;
    notifyListeners();
  }

  // Ürün/Hizmet İşlemleri
  void addProduct(StoreProduct product) {
    _data.products.add(product);
    notifyListeners();
  }

  void removeProduct(int index) {
    if (index >= 0 && index < _data.products.length) {
      _data.products.removeAt(index);
      notifyListeners();
    }
  }

  void updateProduct(int index, StoreProduct product) {
    if (index >= 0 && index < _data.products.length) {
      _data.products[index] = product;
      notifyListeners();
    }
  }

  /// Controller'daki tüm değişiklikleri StoreData'ya uygula
  StoreData applyChangesToData() {
    // Kapak fotoğrafı
    if (_coverBytes != null) {
      // Bytes varsa, veriyi işleme al
      // Not: Asıl yükleme işlemi servis katmanında yapılır
    }
    
    // Galeri güncellemeleri
    _data.galleryItems = _editorGalleryItems
        .where((item) => !item.isRemoved)
        .map((item) {
          if (item.isFromUrl) {
            return StoreGalleryItem(imageUrl: item.imageUrl!);
          }
          return StoreGalleryItem(id: item.id);
        })
        .toList();
    
    return _data;
  }

  /// Değişiklik var mı kontrol et
  bool get hasChanges {
    return _coverBytes != null ||
        _editorGalleryItems.any((item) => item.isRemoved || item.isFromBytes);
  }

  void reset() {
    _coverBytes = null;
    _coverFileName = null;
    _coverUrl = _data.shelfImageUrl.isNotEmpty ? _data.shelfImageUrl : null;
    _editorGalleryItems = _data.galleryItems.map((item) => EditorGalleryItem.fromStoreItem(item)).toList();
    notifyListeners();
  }
}
