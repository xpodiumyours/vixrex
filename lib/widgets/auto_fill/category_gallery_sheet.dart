import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vitrinx/config/business_category_config.dart';
import 'package:vitrinx/services/category_image_service.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/widgets/auto_fill/category_gallery_image_tile.dart';

/// Sheet'in hangi alandan açıldığını belirtir
enum ImageSource { coverPicker, galleryEditor }

/// Seçilen görsele uygulanacak aksiyon
enum ImageAction { setAsCover, addToGallery }

/// Tüm kategorilerin hazır görsellerini gösteren bottom sheet.
/// Kullanıcı kendi kategorisini öne çıkarılmış şekilde görür,
/// her kategoriyi accordion ile açıp kapatabilir, görsel seçip
/// kapak olarak veya galeriye ekleyebilir.
class CategoryGallerySheet extends StatefulWidget {
  final String? preferredCategoryKey;
  final ImageSource source;
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
    required ImageSource source,
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
  bool _isViewingGallery = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        final hasImages = widget.source == ImageSource.coverPicker
            ? entry.value.coverImages.isNotEmpty
            : entry.value.galleryImages.isNotEmpty;

        if (hasImages) {
          images[entry.key] = entry.value;
          keys.add(entry.key);
        }
      }

      // Preferred kategoriyi öne çıkar
      String? defaultActiveKey;
      if (widget.preferredCategoryKey != null &&
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
    } catch (e) {
      debugPrint('CategoryGallerySheet _loadImages error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _filteredKeys {
    if (_searchQuery.isEmpty) return _categoryKeys;
    return _categoryKeys.where((key) {
      final label = _categoryImages[key]?.categoryLabel ?? key;
      return label.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
          if (!_isViewingGallery) _buildSearch(),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori Galerisi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Hazır şablon görsellerinden seç',
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

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.darkText),
        decoration: InputDecoration(
          hintText: 'Kategori ara...',
          hintStyle: const TextStyle(color: AppColors.softText),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.softText),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: AppColors.inputBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
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

    final keys = _filteredKeys;
    if (keys.isEmpty) {
      return const Center(child: Text('Arama sonucu bulunamadı.', style: TextStyle(color: AppColors.mutedText)));
    }

    if (_isViewingGallery && _activeCategoryKey != null && _categoryKeys.contains(_activeCategoryKey)) {
      return _buildGalleryView(_activeCategoryKey!);
    }

    return _buildCategoryGrid(keys);
  }

  Widget _buildCategoryGrid(List<String> keys) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final set = _categoryImages[key]!;
        final isPreferred = key == widget.preferredCategoryKey;

        // Config'den emoji ve ikon bul
        final categoryConfig = BusinessCategoryConfig.categories.firstWhere(
          (c) => c.id == key,
          orElse: () => BusinessCategoryConfig.categories.last, // diger
        );
        final emoji = categoryConfig.id == 'diger' && !isPreferred ? '🏷️' : categoryConfig.emoji;

        return InkWell(
          onTap: () {
            setState(() {
              _activeCategoryKey = key;
              _isViewingGallery = true;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isPreferred 
                  ? AppColors.primary.withOpacity(0.08) 
                  : AppColors.inputBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPreferred ? AppColors.primary : AppColors.border,
                width: isPreferred ? 2 : 1,
              ),
              boxShadow: isPreferred ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPreferred)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ÖNERİLEN',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                Text(
                  isPreferred ? '📌' : emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    set.categoryLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPreferred ? AppColors.primary : AppColors.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGalleryView(String activeKey) {
    final set = _categoryImages[activeKey]!;
    final categoryConfig = BusinessCategoryConfig.categories.firstWhere(
      (c) => c.id == activeKey,
      orElse: () => BusinessCategoryConfig.categories.last,
    );
    final emoji = categoryConfig.emoji;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isViewingGallery = false;
                  });
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.inputBg,
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$emoji ${set.categoryLabel} Şablonları',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildGridContent(activeKey)),
      ],
    );
  }

  Widget _buildGridContent(String activeKey) {
    final set = _categoryImages[activeKey];
    if (set == null) return const SizedBox.shrink();

    final rawImages = widget.source == ImageSource.coverPicker
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                if (widget.source == ImageSource.coverPicker) ...[
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
