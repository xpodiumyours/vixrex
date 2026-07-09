import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vixrex/services/category_image_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/landing/landing_template_category.dart';
import 'package:vixrex/widgets/landing/landing_template_card.dart';

/// Landing ekranında 12 kategoriyi gösteren şablon kataloğu.
/// Kullanıcı kategoriye tıklayıp "Bu şablonla başla" dediğinde
/// auth -> vitrin formu akışına yönlendirir.
class LandingTemplateCatalog extends StatefulWidget {
  final ValueChanged<String?> onNavigateToAuth;

  const LandingTemplateCatalog({
    super.key,
    required this.onNavigateToAuth,
  });

  @override
  State<LandingTemplateCatalog> createState() => _LandingTemplateCatalogState();
}

class _LandingTemplateCatalogState extends State<LandingTemplateCatalog> {
  final Map<String, CategoryImageSet> _imageSets = {};
  final Set<String> _loadingKeys = {};

  @override
  void initState() {
    super.initState();
    _loadAllCategoryImages();
  }

  String _dbKey(String uiKey) {
    const keyMap = {
      'butik_giyim': 'butik',
      'kuafor_guzellik': 'kuafor',
      'kafe_restoran': 'kafe_lokanta',
      'berber': 'kuafor',
      'oto_kuafor': 'oto_arac',
      'market_bakkal': 'gida',
      'pastane_tatlici': 'firin',
      'mobilya_dekorasyon': 'dekorasyon',
      'spor_salonu': 'spor_fitness',
      'dis_klinigi': 'dis_klinigi',
      'eczane': 'eczane',
      'teknik_servis': 'teknik_servis',
    };
    return keyMap[uiKey] ?? uiKey;
  }

  Future<void> _loadAllCategoryImages() async {
    for (final cat in templateCategories) {
      setState(() => _loadingKeys.add(cat.key));
      try {
        final imageSet = await CategoryImageService.getImagesForCategory(_dbKey(cat.key));
        if (!mounted) return;
        setState(() {
          _imageSets[cat.key] = imageSet;
          _loadingKeys.remove(cat.key);
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Template load error for ${cat.key}: $e');
        if (!mounted) return;
        setState(() => _loadingKeys.remove(cat.key));
      }
    }
  }

  void _openTemplatePreview(TemplateCategory category) {
    final imageSet = _imageSets[category.key];
    final hasImages = imageSet != null && imageSet.totalCount > 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(category.icon, color: category.color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasImages
                                  ? '${imageSet.totalCount} hazır görsel mevcut'
                                  : 'Hazır görseller yükleniyor...',
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (hasImages) ...[
                    if (imageSet.coverImages.isNotEmpty) ...[
                      const Text(
                        'Kapak Görselleri',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageSet.coverImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _ImageThumb(
                            url: imageSet.coverImages[i].imageUrl,
                            label: imageSet.coverImages[i].title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (imageSet.galleryImages.isNotEmpty) ...[
                      const Text(
                        'Galeri Görselleri',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageSet.galleryImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _ImageThumb(
                            url: imageSet.galleryImages[i].imageUrl,
                            label: imageSet.galleryImages[i].title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (imageSet.productImages.isNotEmpty) ...[
                      const Text(
                        'Ürün Görselleri',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageSet.productImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _ImageThumb(
                            url: imageSet.productImages[i].imageUrl,
                            label: imageSet.productImages[i].title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ] else if (_loadingKeys.contains(category.key)) ...[
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: AppColors.mutedText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Bu kategori için henüz hazır görsel bulunmuyor.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        widget.onNavigateToAuth(category.key);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text(
                        'Bu Şablonla Başla',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.bgLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'HAZIR ŞABLONLAR',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'İşletme Kategorine Özel Hazır Görseller',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '12 farklı kategoride profesyonel, telifsiz görsellerle vitrinini saniyeler içinde oluştur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 4
                        : constraints.maxWidth > 600
                            ? 3
                            : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: templateCategories.length,
                      itemBuilder: (context, index) {
                        final cat = templateCategories[index];
                        final imageSet = _imageSets[cat.key];
                        final previewUrl = imageSet?.coverImages.isNotEmpty == true
                            ? imageSet!.coverImages.first.imageUrl
                            : null;

                        return TemplateCard(
                          category: cat,
                          previewUrl: previewUrl,
                          isLoading: _loadingKeys.contains(cat.key),
                          onTap: () => _openTemplatePreview(cat),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final String url;
  final String? label;

  const _ImageThumb({required this.url, this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.network(
            url,
            width: 160,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 160,
              height: 120,
              color: AppColors.surfaceSoft,
              child: const Icon(Icons.broken_image, color: AppColors.mutedText),
            ),
          ),
          if (label != null && label!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
