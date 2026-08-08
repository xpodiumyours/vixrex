import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class SectionVisibilityCard extends StatelessWidget {
  final Map<String, bool> visibility;
  final void Function(String key, bool visible) onChanged;

  const SectionVisibilityCard({
    super.key,
    required this.visibility,
    required this.onChanged,
  });

  static const _sections = [
    (key: 'categories', label: 'Kategoriler', icon: Icons.category_outlined),
    (key: 'products', label: 'Ürünler', icon: Icons.inventory_2_outlined),
    (key: 'about', label: 'Hakkımızda', icon: Icons.info_outline_rounded),
    (key: 'gallery', label: 'Galeri', icon: Icons.photo_library_outlined),
    (key: 'blog', label: 'Blog', icon: Icons.article_outlined),
    (key: 'faq', label: 'Sık Sorulan Sorular', icon: Icons.help_outline_rounded),
    (key: 'contact', label: 'İletişim & Konum', icon: Icons.place_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Gelişmiş Ayarlar',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bölümlerden birini kapatırsan vitrininde görünmez. '
            'Kapalıyken açarsan tekrar görünmeye başlar. Boş bırakılırsa '
            'bölüm veri doluysa otomatik görünür.',
            style: TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (final section in _sections)
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                dense: true,
                secondary: Icon(
                  section.icon,
                  size: 20,
                  color: AppColors.mutedText,
                ),
                title: Text(
                  section.label,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                value: visibility[section.key] != false,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => onChanged(section.key, value),
              ),
            ),
        ],
      ),
    );
  }
}
