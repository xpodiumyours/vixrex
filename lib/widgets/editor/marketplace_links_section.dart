import 'package:flutter/material.dart';
import 'package:vixrex/models/store_product.dart';
import 'package:vixrex/theme/app_colors.dart';

class MarketplaceLinksSection extends StatelessWidget {
  final List<MarketplaceLink> links;
  final Set<String> customPlatformLinkIds;
  final List<String> platformOptions;
  final VoidCallback onAddLink;
  final void Function(int index) onRemoveLink;
  final void Function(int index, String? value) onPlatformChanged;
  final void Function(int index, String value) onUrlChanged;
  final void Function(int index, String value) onCustomPlatformChanged;
  final void Function(int index, String value) onSubtitleChanged;

  const MarketplaceLinksSection({
    super.key,
    required this.links,
    required this.customPlatformLinkIds,
    required this.platformOptions,
    required this.onAddLink,
    required this.onRemoveLink,
    required this.onPlatformChanged,
    required this.onUrlChanged,
    required this.onCustomPlatformChanged,
    required this.onSubtitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Bağlantılar',
              style: TextStyle(
                color: AppColors.softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAddLink,
              icon: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                'Ekle',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (links.isEmpty)
          Text(
            'Trendyol, Instagram gibi linkleri veya özel bağlantıları buraya ekleyebilirsiniz.',
            style: TextStyle(
              color: AppColors.mutedText.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        for (int i = 0; i < links.length; i++) ...[
          const SizedBox(height: 8),
          _MarketplaceLinkRow(
            link: links[i],
            index: i,
            customPlatformLinkIds: customPlatformLinkIds,
            platformOptions: platformOptions,
            onRemoveLink: onRemoveLink,
            onPlatformChanged: onPlatformChanged,
            onUrlChanged: onUrlChanged,
            onCustomPlatformChanged: onCustomPlatformChanged,
            onSubtitleChanged: onSubtitleChanged,
          ),
        ],
      ],
    );
  }
}

class _MarketplaceLinkRow extends StatelessWidget {
  final MarketplaceLink link;
  final int index;
  final Set<String> customPlatformLinkIds;
  final List<String> platformOptions;
  final void Function(int index) onRemoveLink;
  final void Function(int index, String? value) onPlatformChanged;
  final void Function(int index, String value) onUrlChanged;
  final void Function(int index, String value) onCustomPlatformChanged;
  final void Function(int index, String value) onSubtitleChanged;

  const _MarketplaceLinkRow({
    required this.link,
    required this.index,
    required this.customPlatformLinkIds,
    required this.platformOptions,
    required this.onRemoveLink,
    required this.onPlatformChanged,
    required this.onUrlChanged,
    required this.onCustomPlatformChanged,
    required this.onSubtitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom =
        customPlatformLinkIds.contains(link.id) ||
        link.platform == 'Özel...' ||
        (!platformOptions.contains(link.platform) && link.platform.isNotEmpty);
    final dropdownValue =
        isCustom
            ? 'Özel...'
            : (platformOptions.contains(link.platform) ? link.platform : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: dropdownValue,
                hint: const Text('Platform', style: TextStyle(fontSize: 13)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderDark),
                  ),
                ),
                items:
                    platformOptions
                        .map(
                          (platform) => DropdownMenuItem(
                            value: platform,
                            child: Text(
                              platform,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) => onPlatformChanged(index, value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                key: ValueKey('${link.id}-url'),
                initialValue: link.url,
                onChanged: (value) => onUrlChanged(index, value),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: _hintForPlatform(link.platform),
                  hintStyle: TextStyle(
                    color: AppColors.mutedText.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorderDark),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => onRemoveLink(index),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        if (isCustom) ...[
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('${link.id}-platform'),
            initialValue: link.platform == 'Özel...' ? '' : link.platform,
            onChanged: (value) => onCustomPlatformChanged(index, value),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkText,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Bağlantı başlığı (ör. Randevu al)',
              hintStyle: TextStyle(
                color: AppColors.mutedText.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Icon(
                Icons.edit_rounded,
                size: 16,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: AppColors.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('${link.id}-subtitle'),
          initialValue: link.subtitle,
          onChanged: (value) => onSubtitleChanged(index, value),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.darkText,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Kısa açıklama (isteğe bağlı)',
            hintStyle: TextStyle(
              color: AppColors.mutedText.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorderDark),
            ),
          ),
        ),
      ],
    );
  }

  String _hintForPlatform(String platform) {
    final value = platform.toLowerCase();
    if (value.contains('trendyol')) return 'trendyol.com/magaza/...';
    if (value.contains('hepsiburada')) return 'hepsiburada.com/magaza/...';
    if (value.contains('instagram')) return 'instagram.com/...';
    if (value.contains('google')) return 'g.page/...';
    if (value.contains('whatsapp')) return 'wa.me/...';
    return 'https://...';
  }
}
