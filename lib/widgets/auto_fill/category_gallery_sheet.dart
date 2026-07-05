import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vitrinx/config/business_category_config.dart';
import 'package:vitrinx/services/category_image_service.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/auto_fill/category_gallery_image_tile.dart';

/// Sheet'in hangi alandan açıldığını belirtir
enum SheetImageSource { coverPicker, galleryEditor }

/// Seçilen görsele uygulanacak aksiyon
enum ImageAction { setAsCover, addToGallery }

/// Tüm kategorilerin hazır görsellerini gösteren bottom sheet.
/// Kullanıcı kendi kategorisini öne çıkarılmış şekilde görür,
/// her kategoriyi accordion ile açıp kapatabilir, görsel seçip
/// kapak olarak veya galeriye ekleyebilir.
class CategoryGallerySheet extends StatefulWidget {
  final String? preferredCategoryKey;
  final SheetImageSource source;
  final void Function(String url, ImageAction action) onImageAction;

  const CategoryGallerySheet({
    super.key,
    this.preferredCategoryKey,
    required this.source,
    required this.onImageAction,
  });

  static Future<void> show({
    required BuildContext context,
    String? preferredCategoryKey,
    required SheetImageSource source,
    required void Function(String url, ImageAction action) onImageAction,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryGallerySheet(
        preferredCategoryKey: preferredCategoryKey,
        source: source,
        onImageAction: onImageAction,
      ),
    );
  }

  @override
  State<CategoryGallerySheet> createState() => _CategoryGallerySheetState();
}

class _CategoryGallerySheetState extends State<CategoryGallerySheet> {
  bool _isLoading = true;
  Map<String, CategoryImageSet> _categoryImages = {};
  List<String> _categoryKeys = [];
  String? _selectedImageUrl;
  String? _activeCategoryKey;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    try {
      final categories = await CategoryImageService.getAvailableCategories();
      final Map<String, CategoryImageSet> images = {};
      final List<String> keys = [];

      final categorySets = await Future.wait(
        categories.map((cat) async {
          final set = await CategoryImageService.getImagesForCategory(cat.key);
          return MapEntry(cat.key, set);
        }),
      );

      for (final entry in categorySets) {
        final hasImages = widget.source == SheetImageSource.coverPicker
            ? entry.value.coverImages.isNotEmpty
            : entry.value.galleryImages.isNotEmpty;

        if (hasImages) {
          images[entry.key] = entry.value;
          keys.add(entry.key);
        }
      }

      // Kategorileri alfabetik olarak sıralayalım
      keys.sort((a, b) {
        final labelA = images[a]?.categoryLabel ?? '';
        final labelB = images[b]?.categoryLabel ?? '';
        return labelA.compareTo(labelB);
      });

      // 'diger' kategorisini tamamen kaldıralım
      keys.remove('diger');

      // Preferred kategoriyi en öne çıkar
      String? defaultActiveKey;
      if (widget.preferredCategoryKey != null &&
          widget.preferredCategoryKey != 'diger' &&
          images.containsKey(widget.preferredCategoryKey)) {
        keys.remove(widget.preferredCategoryKey);
        keys.insert(0, widget.preferredCategoryKey!);
        defaultActiveKey = widget.preferredCategoryKey;
      } else if (keys.isNotEmpty) {
        defaultActiveKey = keys.first;
      }

      if (mounted) {
        setState(() {
          _categoryImages = images;
          _categoryKeys = keys;
          _activeCategoryKey = defaultActiveKey;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAction(ImageAction action) {
    if (_selectedImageUrl == null) return;
    widget.onImageAction(_selectedImageUrl!, action);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.bgEditor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _buildContent()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Şablon Kütüphanesi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'İşletmeniz için özenle tasarlanmış görseller',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorAndSearch(List<String> keys, String activeKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Sol: Kategori Seçici
          Expanded(
            flex: 4,
            child: _buildCategorySelector(keys, activeKey),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(List<String> keys, String activeKey) {
    final currentSet = _categoryImages[activeKey];
    if (currentSet == null) return const SizedBox.shrink();

    final categoryConfig = BusinessCategoryConfig.categories.firstWhere(
      (c) => c.id == activeKey,
      orElse: () => BusinessCategoryConfig.categories.last,
    );
    final emoji = activeKey == widget.preferredCategoryKey ? '📌' : categoryConfig.emoji;

    return PopupMenuButton<String>(
      onSelected: (key) {
        setState(() {
          _activeCategoryKey = key;
          _selectedImageUrl = null; // Kategori değiştiğinde seçimi temizle
        });
      },
      offset: const Offset(0, 50),
      color: AppColors.bgEditor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (context) {
        return keys.map((key) {
          final set = _categoryImages[key]!;
          final isPreferred = key == widget.preferredCategoryKey;
          final config = BusinessCategoryConfig.categories.firstWhere(
            (c) => c.id == key,
            orElse: () => BusinessCategoryConfig.categories.last,
          );
          final itemEmoji = isPreferred ? '📌' : config.emoji;

          return PopupMenuItem<String>(
            value: key,
            child: Row(
              children: [
                Text(itemEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    set.categoryLabel,
                    style: TextStyle(
                      color: key == activeKey ? AppColors.primary : AppColors.darkText,
                      fontWeight: key == activeKey ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isPreferred)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ÖNERİLEN',
                      style: TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                currentSet.categoryLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_categoryKeys.isEmpty) {
      return const Center(child: Text('Hazır görsel bulunamadı.', style: TextStyle(color: AppColors.mutedText)));
    }

    final keys = _categoryKeys;
    final activeKey = _activeCategoryKey ?? keys.first;

    return Column(
      children: [
        _buildSelectorAndSearch(keys, activeKey),
        const SizedBox(height: 4),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(activeKey),
              child: _buildGridContent(activeKey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridContent(String activeKey) {
    final set = _categoryImages[activeKey];
    if (set == null) return const SizedBox.shrink();

    final rawImages = widget.source == SheetImageSource.coverPicker
        ? set.coverImages
        : set.galleryImages;

    final seenUrls = <String>{};
    final allImages = rawImages.where((img) => seenUrls.add(img.imageUrl)).toList();

    if (allImages.isEmpty) {
      return const Center(
        child: Text(
          'Bu kategoride hazır görsel bulunmuyor.',
          style: TextStyle(color: AppColors.mutedText),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        final img = allImages[index];
        final isSelected = _selectedImageUrl == img.imageUrl;
        return CategoryGalleryImageTile(
          image: img,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedImageUrl = img.imageUrl),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final hasSelection = _selectedImageUrl != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.bgEditor,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (widget.source == SheetImageSource.coverPicker) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasSelection
                          ? () => _handleAction(ImageAction.setAsCover)
                          : null,
                      icon: const Icon(Icons.image_rounded, size: 18),
                      label: const Text('Kapak Olarak Kullan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.disabled,
                        disabledForegroundColor: AppColors.mutedText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasSelection
                          ? () => _handleAction(ImageAction.addToGallery)
                          : null,
                      icon: const Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 18,
                      ),
                      label: const Text('Galeriye Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: AppColors.disabled,
                        disabledForegroundColor: AppColors.mutedText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkText,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('İptal'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
