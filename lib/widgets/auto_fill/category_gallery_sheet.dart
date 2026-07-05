import 'dart:async';
import 'package:flutter/material.dart';
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
  final Set<String> _expandedCategories = {};
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

      for (final cat in categories) {
        final set = await CategoryImageService.getImagesForCategory(cat.key);
        if (set.totalCount > 0) {
          images[cat.key] = set;
          keys.add(cat.key);
        }
      }

      // Preferred kategoriyi öne çıkar
      if (widget.preferredCategoryKey != null &&
          images.containsKey(widget.preferredCategoryKey)) {
        keys.remove(widget.preferredCategoryKey);
        keys.insert(0, widget.preferredCategoryKey!);
        _expandedCategories.add(widget.preferredCategoryKey!);
      }

      if (mounted) {
        setState(() {
          _categoryImages = images;
          _categoryKeys = keys;
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

  void _toggleCategory(String key) {
    setState(() {
      if (_expandedCategories.contains(key)) {
        _expandedCategories.remove(key);
      } else {
        _expandedCategories.add(key);
      }
    });
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearch(),
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
        color: Colors.grey.shade300,
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hazır görsellerden seç',
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
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Kategori ara...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
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
      return const Center(child: Text('Hazır görsel bulunamadı.'));
    }

    final keys = _filteredKeys;
    if (keys.isEmpty) {
      return const Center(child: Text('Arama sonucu bulunamadı.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final set = _categoryImages[key]!;
        final isExpanded = _expandedCategories.contains(key);
        final isPreferred = key == widget.preferredCategoryKey;

        return _buildCategorySection(key, set, isExpanded, isPreferred);
      },
    );
  }

  Widget _buildCategorySection(
    String key,
    CategoryImageSet set,
    bool isExpanded,
    bool isPreferred,
  ) {
    final allImages = [...set.coverImages, ...set.galleryImages];
    if (allImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _toggleCategory(key),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPreferred
                        ? '📌 ${set.categoryLabel}'
                        : '🏷️ ${set.categoryLabel}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isPreferred
                          ? AppColors.primary
                          : AppColors.darkText,
                    ),
                  ),
                ),
                Text(
                  '${allImages.length} görsel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: allImages.length,
              itemBuilder: (context, imgIndex) {
                final img = allImages[imgIndex];
                final isSelected = _selectedImageUrl == img.imageUrl;
                return CategoryGalleryImageTile(
                  image: img,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedImageUrl = img.imageUrl),
                );
              },
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildBottomBar() {
    final hasSelection = _selectedImageUrl != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
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
                        foregroundColor: Colors.white,
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
                        foregroundColor: Colors.white,
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
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
