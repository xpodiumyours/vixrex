import 'package:flutter/material.dart';
import 'package:vixrex/services/category_image_service.dart';
import 'package:vixrex/theme/app_colors.dart';

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

class _TemplateCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _TemplateCategory(this.key, this.label, this.icon, this.color);
}

const List<_TemplateCategory> _categories = [
  _TemplateCategory(
    'butik_giyim',
    'Butik & Giyim',
    Icons.checkroom_rounded,
    Color(0xFFFF5A1F),
  ),
  _TemplateCategory(
    'kuafor_guzellik',
    'Kuaför & Güzellik',
    Icons.content_cut_rounded,
    Color(0xFFDB2777),
  ),
  _TemplateCategory(
    'kafe_restoran',
    'Kafe & Restoran',
    Icons.restaurant_menu_rounded,
    Color(0xFFEA580C),
  ),
  _TemplateCategory('berber', 'Berber', Icons.face_rounded, Color(0xFF7C3AED)),
  _TemplateCategory(
    'oto_kuafor',
    'Oto Kuaför',
    Icons.local_car_wash_rounded,
    Color(0xFF2563EB),
  ),
  _TemplateCategory(
    'market_bakkal',
    'Market & Bakkal',
    Icons.shopping_basket_rounded,
    Color(0xFF059669),
  ),
  _TemplateCategory(
    'pastane_tatlici',
    'Pastane & Tatlıcı',
    Icons.bakery_dining_rounded,
    Color(0xFFD946EF),
  ),
  _TemplateCategory(
    'mobilya_dekorasyon',
    'Mobilya & Dekorasyon',
    Icons.chair_rounded,
    Color(0xFFCA8A04),
  ),
  _TemplateCategory(
    'spor_salonu',
    'Spor Salonu',
    Icons.fitness_center_rounded,
    Color(0xFFDC2626),
  ),
  _TemplateCategory(
    'dis_klinigi',
    'Diş Kliniği',
    Icons.medical_services_rounded,
    Color(0xFF0891B2),
  ),
  _TemplateCategory(
    'eczane',
    'Eczane',
    Icons.local_pharmacy_rounded,
    Color(0xFF16A34A),
  ),
  _TemplateCategory(
    'teknik_servis',
    'Teknik Servis',
    Icons.build_circle_rounded,
    Color(0xFF4F46E5),
  ),
];

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
    for (final cat in _categories) {
      setState(() => _loadingKeys.add(cat.key));
      try {
        final imageSet = await CategoryImageService.getImagesForCategory(_dbKey(cat.key));
        if (!mounted) return;
        setState(() {
          _imageSets[cat.key] = imageSet;
          _loadingKeys.remove(cat.key);
        });
      } catch (e) {
        debugPrint('Template load error for ${cat.key}: $e');
        if (!mounted) return;
        setState(() => _loadingKeys.remove(cat.key));
      }
    }
  }

  void _openTemplatePreview(_TemplateCategory category) {
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
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final imageSet = _imageSets[cat.key];
                        final previewUrl = imageSet?.coverImages.isNotEmpty == true
                            ? imageSet!.coverImages.first.imageUrl
                            : null;

                        return _TemplateCard(
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

class _TemplateCard extends StatelessWidget {
  final _TemplateCategory category;
  final String? previewUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.category,
    this.previewUrl,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    color: category.color.withValues(alpha: 0.08),
                    child: previewUrl != null
                        ? Image.network(
                            previewUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackContent(),
                          )
                        : _fallbackContent(),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.label,
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Hazır görseller →',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackContent() {
    return Center(
      child: Icon(
        category.icon,
        size: 48,
        color: category.color.withValues(alpha: 0.4),
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
