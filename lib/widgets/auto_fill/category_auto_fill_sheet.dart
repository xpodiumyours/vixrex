import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vitrinx/services/category_image_service.dart';
import 'package:vitrinx/services/auto_fill_service.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Local uygulama callback'i - controller'a gorselleri local olarak uygular
/// [coverImage] secilen kapak goruntusu (opsiyonel)
/// [galleryImages] secilen galeri goruntuleri
/// [productImages] secilen urun sablon goruntuleri
typedef LocalApplyCallback = void Function({
  CategoryTemplateImage? coverImage,
  List<CategoryTemplateImage> galleryImages,
  List<CategoryTemplateImage> productImages,
});

/// Kategori sablonu ile vitrini otomatik doldurma bottom sheet'i
class CategoryAutoFillSheet extends StatefulWidget {
  final String categoryKey;
  final String categoryLabel;
  final String storeId;
  final FutureOr<void> Function()? onApplied;
  final LocalApplyCallback? onLocalApply;

  const CategoryAutoFillSheet({
    super.key,
    required this.categoryKey,
    required this.categoryLabel,
    required this.storeId,
    this.onApplied,
    this.onLocalApply,
  });

  static Future<void> show({
    required BuildContext context,
    required String categoryKey,
    required String categoryLabel,
    required String storeId,
    FutureOr<void> Function()? onApplied,
    LocalApplyCallback? onLocalApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryAutoFillSheet(
        categoryKey: categoryKey,
        categoryLabel: categoryLabel,
        storeId: storeId,
        onApplied: onApplied,
        onLocalApply: onLocalApply,
      ),
    );
  }

  @override
  State<CategoryAutoFillSheet> createState() => _CategoryAutoFillSheetState();
}

class _CategoryAutoFillSheetState extends State<CategoryAutoFillSheet> {
  bool _fillCover = false;
  final bool _fillLogo = true;
  bool _fillGallery = false;
  bool _fillProducts = false;
  bool _isLoading = false;
  bool _isApplying = false;
  CategoryImageSet? _imageSet;
  String? _error;
  String? _selectedCoverUrl;

  bool get _isLocalMode => widget.storeId.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() => _isLoading = true);
    try {
      final set = await CategoryImageService.getImagesForCategory(
        widget.categoryKey,
      );
      setState(() {
        _imageSet = set;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Gorseller yuklenemedi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _apply() async {
    // Local mod: controller'a gorselleri local olarak uygula
    if (_isLocalMode && widget.onLocalApply != null) {
      setState(() => _isApplying = true);

      final selectedCover = _fillCover && _imageSet != null && _imageSet!.coverImages.isNotEmpty
          ? _imageSet!.coverImages.first
          : null;
      final selectedGallery = _fillGallery && _imageSet != null
          ? _imageSet!.galleryImages
          : <CategoryTemplateImage>[];
      final selectedProducts = _fillProducts && _imageSet != null
          ? _imageSet!.productImages
          : <CategoryTemplateImage>[];

      widget.onLocalApply!(
        coverImage: selectedCover,
        galleryImages: selectedGallery,
        productImages: selectedProducts,
      );

      setState(() => _isApplying = false);

      if (mounted) {
        Navigator.pop(context);
        await widget.onApplied?.call();

        final totalCount = (selectedCover != null ? 1 : 0) +
            selectedGallery.length +
            selectedProducts.length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$totalCount hazir gorsel vitrinine eklendi! '
                    'Yayina aldiginda gorunur olacak.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Remote mod: Supabase RPC/manuel service kullan
    if (_isLocalMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lutfen once vitrininizi kaydedin.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isApplying = true);

    final result = await AutoFillService.applyCategoryTemplate(
      storeId: widget.storeId,
      categoryKey: widget.categoryKey,
      options: AutoFillOptions(
        fillCover: _fillCover,
        fillLogo: _fillLogo,
        fillGallery: _fillGallery,
        fillProducts: _fillProducts,
      ),
      selectedCoverUrl: _selectedCoverUrl,
    );

    setState(() => _isApplying = false);

    if (result.success && mounted) {
      Navigator.pop(context);
      await widget.onApplied?.call();

      // Basari snackbar'i
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${result.appliedCount} alan otomatik dolduruldu! '
                  'Vitrin puanin ~+${result.estimatedScoreBoost} artti.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Bir hata olustu.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hazir gorsellerle vitrinini tamamla',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          if (_isLocalMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Gorseller su an local olarak vitrininize eklenecek. '
                      'Yayina aldiginizda herkes gorebilecek.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _imageSet == null
                        ? const SizedBox.shrink()
                        : _buildContent(),
          ),
          // Bottom actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Secenekler
                  if (_imageSet != null) ...[
                    _buildOptionTile(
                      'Kapak gorseli',
                      _imageSet!.coverImages.isNotEmpty
                          ? '${_imageSet!.coverImages.length} secenek'
                          : 'Yok',
                      Icons.image_rounded,
                      _fillCover,
                      (v) => setState(() => _fillCover = v),
                      _imageSet!.coverImages.isNotEmpty,
                    ),
                    _buildOptionTile(
                      'Galeri gorselleri',
                      _imageSet!.galleryImages.isNotEmpty
                          ? '${_imageSet!.galleryImages.length} gorsel'
                          : 'Yok',
                      Icons.photo_library_rounded,
                      _fillGallery,
                      (v) => setState(() => _fillGallery = v),
                      _imageSet!.galleryImages.isNotEmpty,
                    ),
                    _buildOptionTile(
                      'Urun sablonlari',
                      _imageSet!.productImages.isNotEmpty
                          ? '${_imageSet!.productImages.length} urun'
                          : 'Yok',
                      Icons.shopping_bag_rounded,
                      _fillProducts,
                      (v) => setState(() => _fillProducts = v),
                      _imageSet!.productImages.isNotEmpty,
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Uygula butonu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isApplying ||
                              (_imageSet?.totalCount ?? 0) == 0 ||
                              !(_fillCover || _fillGallery || _fillProducts)
                          ? null
                          : _apply,
                      icon: _isApplying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high_rounded),
                      label: Text(
                        _isApplying
                            ? 'Uygulaniyor...'
                            : _isLocalMode
                                ? 'Gorselleri Vitrinine Ekle'
                                : 'Hazir Gorselleri Uygula',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPreview,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Onizleme
          if (_imageSet!.coverImages.isNotEmpty) ...[
            _buildSectionTitle('Kapak Onizleme (secmek icin dokun)'),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imageSet!.coverImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final img = _imageSet!.coverImages[index];
                  final isSelected = _selectedCoverUrl == img.imageUrl;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCoverUrl = img.imageUrl),
                    child: Container(
                      width: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          img.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Galeri onizleme
          if (_imageSet!.galleryImages.isNotEmpty) ...[
            _buildSectionTitle(
              'Galeri Onizleme (${_imageSet!.galleryImages.length})',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imageSet!.galleryImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final img = _imageSet!.galleryImages[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      img.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          // Urun onizleme
          if (_imageSet!.productImages.isNotEmpty) ...[
            _buildSectionTitle(
              'Urun Sablonlari (${_imageSet!.productImages.length})',
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.darkText,
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool enabled,
  ) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: CheckboxListTile(
        value: value && enabled,
        onChanged: enabled ? (v) => onChanged(v ?? false) : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        secondary: Icon(icon, color: AppColors.primary),
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        dense: true,
      ),
    );
  }
}
