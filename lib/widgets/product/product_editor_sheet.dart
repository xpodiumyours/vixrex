import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vixrex/models/product_rich_data.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/product_category_metadata_service.dart';
import 'package:vixrex/services/product_image_policy.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/utils/gallery_image_file_validator.dart';
import 'package:vixrex/widgets/product/product_rich_fields_editor.dart';

class ProductEditorSheet extends StatefulWidget {
  const ProductEditorSheet({
    super.key,
    required this.categories,
    required this.storeSlug,
    this.product,
  });

  final List<ProductCategory> categories;
  final String storeSlug;
  final Product? product;

  @override
  State<ProductEditorSheet> createState() => _ProductEditorSheetState();
}

class _ProductEditorSheetState extends State<ProductEditorSheet> {
  static const int _maxImages = ProductImagePolicy.maxImages;
  static final _stockOptions = [
    StockStatus.available.label,
    StockStatus.lowStock.label,
    StockStatus.soldOut.label,
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _oldPriceController;
  late final TextEditingController _badgeTagController;
  late final TextEditingController _fulfillmentController;
  late final TextEditingController _descriptionController;
  late final List<_ProductImageDraft> _images;
  late String _categoryId;
  late String _stockStatus;
  String? _brand;
  String? _barcode;
  int? _stockQuantity;
  late ProductRichMetadata _richMetadata;
  late List<ProductVariantData> _variants;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(text: product?.price ?? '');
    _oldPriceController = TextEditingController(
      text:
          product?.oldPriceAmount == null
              ? ''
              : _formatAmount(product!.oldPriceAmount!),
    );
    _badgeTagController = TextEditingController(text: product?.badgeTag ?? '');
    _fulfillmentController = TextEditingController(
      text: product?.fulfillmentLocation ?? '',
    );
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _images =
        (product?.displayImageUrls ?? const <String>[])
            .map((url) => _ProductImageDraft(url: url))
            .toList();
    _categoryId = _resolveInitialCategoryId(product);
    _stockStatus =
        _stockOptions.contains(product?.stockStatus)
            ? product!.stockStatus
            : _stockOptions.first;
    _brand = product?.brand;
    _barcode = product?.barcode;
    _stockQuantity = product?.stockQuantity;
    _richMetadata = product?.richMetadata ?? const ProductRichMetadata();
    _variants = List<ProductVariantData>.of(product?.variants ?? const []);

    final category = _selectedCategory;
    if (category != null) {
      _richMetadata = alignProductMetadataToCategory(_richMetadata, category);
    }
  }

  String _resolveInitialCategoryId(Product? product) {
    final explicit = product?.categoryId.trim() ?? '';
    if (widget.categories.any((category) => category.id == explicit)) {
      return explicit;
    }
    final label = product?.category.trim().toLowerCase() ?? '';
    for (final category in widget.categories) {
      if (category.name.trim().toLowerCase() == label) return category.id;
    }
    return widget.categories.isEmpty ? '' : widget.categories.first.id;
  }

  ProductCategory? get _selectedCategory {
    for (final category in widget.categories) {
      if (category.id == _categoryId) return category;
    }
    return null;
  }

  bool get _isServiceProduct =>
      (_selectedCategory?.productTemplateKey.trim() ?? '') == 'service';

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _badgeTagController.dispose();
    _fulfillmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  double? _parseAmount(String raw) {
    var cleaned = raw.trim().replaceAll(RegExp(r'[^\d,.]'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '.');
    }
    return double.tryParse(cleaned);
  }

  void _selectProductCategory(String? value) {
    final nextId = value ?? '';
    ProductCategory? category;
    for (final item in widget.categories) {
      if (item.id == nextId) {
        category = item;
        break;
      }
    }
    setState(() {
      _categoryId = nextId;
      if (category != null) {
        _richMetadata = alignProductMetadataToCategory(_richMetadata, category!);
        if (category!.productTemplateKey == 'service') {
          _stockQuantity = null;
        }
      }
    });
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) {
      _showMessage('Bir ürüne en fazla $_maxImages fotoğraf eklenebilir.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    var rejected = 0;
    final additions = <_ProductImageDraft>[];
    for (final file in result.files.take(remaining)) {
      final validation = GalleryImageFileValidator.validate(
        bytes: file.bytes,
        reportedSize: file.size,
      );
      if (!validation.isValid || file.bytes == null) {
        rejected++;
        continue;
      }
      additions.add(
        _ProductImageDraft(
          bytes: file.bytes,
          extension: validation.fileInfo!.extension,
          contentType: validation.fileInfo!.contentType,
        ),
      );
    }
    setState(() => _images.addAll(additions));
    if (rejected > 0) {
      _showMessage(
        '$rejected görsel eklenemedi. JPG, PNG veya WEBP, en fazla 15 MB.',
      );
    }
  }

  void _moveImage(int index, int direction) {
    final target = index + direction;
    if (target < 0 || target >= _images.length) return;
    setState(() {
      final item = _images.removeAt(index);
      _images.insert(target, item);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Ürün adı zorunludur.');
      return;
    }
    if (_images.length < ProductImagePolicy.minImages) {
      _showMessage(
        'Bir ürün için en az ${ProductImagePolicy.minImages} fotoğraf zorunludur.',
      );
      return;
    }
    final selectedCategory = _selectedCategory;
    if (selectedCategory == null) {
      _showMessage('Ürün kategorisi zorunludur.');
      return;
    }

    setState(() => _isSaving = true);
    final productId =
        widget.product?.id.trim().isNotEmpty == true
            ? widget.product!.id
            : DateTime.now().microsecondsSinceEpoch.toString();
    final uploadedUrls = <String>[];
    try {
      for (var index = 0; index < _images.length; index++) {
        final draft = _images[index];
        if (draft.url.trim().isNotEmpty) {
          uploadedUrls.add(draft.url.trim());
          continue;
        }
        final bytes = draft.bytes;
        if (bytes == null) continue;
        final url = await const StoreShelfUploadService().uploadProductImage(
          bytes,
          widget.storeSlug,
          productId,
          fileExtension: draft.extension,
          contentType: draft.contentType,
        );
        uploadedUrls.add(url);
        draft.url = url;
        draft.bytes = null;
      }

      final builder = const StorePublishPayloadBuilder();
      final slug =
          widget.product?.slug?.trim().isNotEmpty == true
              ? widget.product!.slug!
              : builder.generateSlug('$name-$productId');
      final richMetadata = alignProductMetadataToCategory(
        _richMetadata,
        selectedCategory,
      );
      final isService = selectedCategory.productTemplateKey == 'service';
      final result = Product(
        id: productId,
        name: name,
        price: _priceController.text.trim(),
        description: _descriptionController.text.trim(),
        imagePath: uploadedUrls.isEmpty ? null : uploadedUrls.first,
        imageUrls: uploadedUrls,
        categoryId: selectedCategory.id,
        category: selectedCategory.name,
        stockStatus: isService ? '' : _stockStatus,
        isVisible: widget.product?.isVisible ?? true,
        slug: slug,
        source: widget.product?.source,
        sourceMediaId: widget.product?.sourceMediaId,
        sourcePermalink: widget.product?.sourcePermalink,
        importedAt: widget.product?.importedAt,
        brand: _brand,
        barcode: isService ? null : _barcode,
        sku: richMetadata.sku,
        stockQuantity: isService ? null : _stockQuantity,
        richMetadata: richMetadata,
        variants: _variants,
        oldPriceAmount: _parseAmount(_oldPriceController.text),
        badgeTag:
            _badgeTagController.text.trim().isEmpty
                ? null
                : _badgeTagController.text.trim(),
        fulfillmentLocation:
            _fulfillmentController.text.trim().isEmpty
                ? null
                : _fulfillmentController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Ürün görselleri yüklenemedi. Form korundu, tekrar deneyebilirsiniz.',
      );
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _selectedCategory;
    return PopScope(
      canPop: !_isSaving,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.product == null ? 'Yeni Ürün' : 'Ürünü Düzenle',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _buildImages(),
                const SizedBox(height: 18),
                _field(_nameController, 'Ürün adı *', 80),
                const SizedBox(height: 12),
                _field(_priceController, 'Fiyat', 30),
                const SizedBox(height: 12),
                _field(_oldPriceController, 'Eski fiyat (üstü çizili)', 30),
                const SizedBox(height: 12),
                _field(_badgeTagController, 'Rozet (örn. Yeni, -31%)', 20),
                const SizedBox(height: 12),
                _field(
                  _fulfillmentController,
                  'Teslim bölgesi (isteğe bağlı)',
                  80,
                ),
                const SizedBox(height: 12),
                _field(
                  _descriptionController,
                  'Kısa açıklama',
                  500,
                  maxLines: 4,
                  helperBuilder: _descriptionHelper,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categoryId.isEmpty ? null : _categoryId,
                  dropdownColor: AppColors.surfaceSoft,
                  decoration: const InputDecoration(labelText: 'Kategori *'),
                  items:
                      widget.categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                  onChanged: _isSaving ? null : _selectProductCategory,
                ),
                if (!_isServiceProduct) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _stockStatus,
                    dropdownColor: AppColors.surfaceSoft,
                    decoration: const InputDecoration(labelText: 'Stok durumu'),
                    items:
                        _stockOptions
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                    onChanged:
                        _isSaving
                            ? null
                            : (value) => setState(
                              () =>
                                  _stockStatus =
                                      value ?? StockStatus.available.label,
                            ),
                  ),
                ],
                if (selectedCategory != null)
                  ProductRichFieldsEditor(
                    key: ValueKey('rich-${selectedCategory.productTemplateKey}'),
                    templateKey: selectedCategory.productTemplateKey,
                    value: ProductRichEditorValue(
                      brand: _brand,
                      barcode: _barcode,
                      stockQuantity: _stockQuantity,
                      metadata: _richMetadata,
                    ),
                    variantCount: _variants.length,
                    enabled: !_isSaving,
                    onChanged: (next) {
                      setState(() {
                        _brand = next.brand;
                        _barcode = next.barcode;
                        _stockQuantity = next.stockQuantity;
                        _richMetadata = next.metadata;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon:
                      _isSaving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Kaydediliyor...' : 'Ürünü Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    int maxLength, {
    int maxLines = 1,
    String? Function(String)? helperBuilder,
  }) {
    if (helperBuilder == null) {
      return TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        enabled: !_isSaving,
        decoration: InputDecoration(labelText: label, counterText: ''),
      );
    }

    // #247: eksik/çok kısa açıklama, ürün sayısı arttıkça SEO ve müşteri
    // güveni açısından bir kalite riski — bu yumuşak (bloklamayan) uyarı,
    // kaydetmeyi engellemeden esnafı bilgilendirir. ValueListenableBuilder
    // kullanılıyor çünkü TextEditingController zaten bir ValueNotifier —
    // ayrı bir state/setState açmaya gerek yok.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          enabled: !_isSaving,
          decoration: InputDecoration(
            labelText: label,
            counterText: '',
            helperText: helperBuilder(value.text),
            helperMaxLines: 2,
            helperStyle: const TextStyle(color: AppColors.warning),
          ),
        );
      },
    );
  }

  /// Boşsa uyarı yok (zorunlu alan değil) — yalnız doldurulmuş ama çok kısa
  /// bırakılmışsa uyarır. Eşik (40 karakter) kesin bir kural değil, kaba bir
  /// "bir cümleden az" sezgisi.
  String? _descriptionHelper(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length >= 40) return null;
    return 'Açıklama kısa görünüyor — birkaç cümle eklemek müşteri güvenini ve aramada bulunmayı artırır.';
  }

  Widget _buildImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ürün görselleri *',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${_images.length}/$_maxImages',
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + (_images.length < _maxImages ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == _images.length) {
                return _buildAddImageTile();
              }
              return _buildImageTile(index);
            },
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'En az 3, en fazla 10 fotoğraf. İlk fotoğraf ürün kapağıdır.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildAddImageTile() {
    return InkWell(
      onTap: _isSaving ? null : _pickImages,
      borderRadius: BorderRadius.circular(AppColors.radius14),
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppColors.radius14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined),
            SizedBox(height: 6),
            Text('Görsel ekle', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final image = _images[index];
    return SizedBox(
      width: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppColors.radius14),
              child:
                  image.bytes != null
                      ? Image.memory(image.bytes!, fit: BoxFit.cover)
                      : Image.network(
                        image.url,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: AppColors.surfaceSoft,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                      ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              onPressed:
                  _isSaving
                      ? null
                      : () => setState(() => _images.removeAt(index)),
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
          ),
          Positioned(
            left: 2,
            right: 2,
            bottom: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _moveButton(index, -1, Icons.chevron_left_rounded),
                _moveButton(index, 1, Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moveButton(int index, int direction, IconData icon) {
    final enabled =
        !_isSaving &&
        index + direction >= 0 &&
        index + direction < _images.length;
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      onPressed: enabled ? () => _moveImage(index, direction) : null,
      icon: Icon(icon, size: 16),
    );
  }
}

class _ProductImageDraft {
  _ProductImageDraft({
    this.url = '',
    this.bytes,
    this.extension = 'jpg',
    this.contentType = 'image/jpeg',
  });

  String url;
  Uint8List? bytes;
  final String extension;
  final String contentType;
}
