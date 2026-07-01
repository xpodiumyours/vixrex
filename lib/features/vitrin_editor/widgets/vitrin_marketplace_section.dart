import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Pazar yeri bağlantıları (Trendyol, Instagram vb.) yönetim bölümü.
class VitrinMarketplaceSection extends StatelessWidget {
  final List<MarketplaceLink> marketplaceLinks;
  final Set<String> customPlatformLinkIds;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  /// Platform, URL veya alt başlık değiştiğinde çağrılır (parent setState için).
  final VoidCallback onChanged;

  static const Color _primaryColor = AppColors.primary;
  static const Color _softText = AppColors.softText;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.cardBorderDark;

  static const List<String> _platformOptions = [
    'Trendyol',
    'Hepsiburada',
    'N11',
    'Amazon',
    'Çiçeksepeti',
    'Shopier',
    'Google İşletme',
    'Instagram',
    'WhatsApp',
    'Diğer',
    'Özel...',
  ];

  const VitrinMarketplaceSection({
    super.key,
    required this.marketplaceLinks,
    required this.customPlatformLinkIds,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
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
                color: _softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16, color: _primaryColor),
              label: const Text(
                'Ekle',
                style: TextStyle(
                  color: _primaryColor,
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
        if (marketplaceLinks.isEmpty)
          Text(
            'Trendyol, Instagram gibi linkleri veya özel bağlantıları buraya ekleyebilirsiniz.',
            style: TextStyle(
              color: _mutedText.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        for (int i = 0; i < marketplaceLinks.length; i++) ...[
          const SizedBox(height: 8),
          _buildLinkRow(i),
        ],
      ],
    );
  }

  Widget _buildLinkRow(int index) {
    final link = marketplaceLinks[index];
    final isCustom =
        customPlatformLinkIds.contains(link.id) ||
        link.platform == 'Özel...' ||
        (!_platformOptions.contains(link.platform) && link.platform.isNotEmpty);
    final dropdownValue =
        isCustom
            ? 'Özel...'
            : (_platformOptions.contains(link.platform) ? link.platform : null);

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
                  fillColor: _inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                ),
                items: _platformOptions
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == 'Özel...') {
                    link.platform = 'Özel...';
                    customPlatformLinkIds.add(link.id);
                  } else {
                    link.platform = val ?? '';
                    customPlatformLinkIds.remove(link.id);
                  }
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                key: ValueKey('${link.id}-url'),
                initialValue: link.url,
                onChanged: (val) {
                  marketplaceLinks[index].url = val;
                  onChanged();
                },
                style: const TextStyle(
                  fontSize: 13,
                  color: _darkText,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: _urlHint(link.platform),
                  hintStyle: TextStyle(
                    color: _mutedText.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: _inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => onRemove(index),
              icon: const Icon(Icons.close_rounded, size: 18, color: _mutedText),
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
            onChanged: (val) {
              marketplaceLinks[index].platform = val.trim();
              onChanged();
            },
            style: const TextStyle(
              fontSize: 13,
              color: _darkText,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Bağlantı başlığı (ör. Randevu al)',
              hintStyle: TextStyle(
                color: _mutedText.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Icon(
                Icons.edit_rounded,
                size: 16,
                color: _primaryColor.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: _inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _primaryColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextFormField(
          key: ValueKey('${link.id}-subtitle'),
          initialValue: link.subtitle,
          onChanged: (val) {
            marketplaceLinks[index].subtitle = val.trim();
            onChanged();
          },
          style: const TextStyle(
            fontSize: 12,
            color: _darkText,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Kısa açıklama (isteğe bağlı)',
            hintStyle: TextStyle(
              color: _mutedText.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder),
            ),
          ),
        ),
      ],
    );
  }

  String _urlHint(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('trendyol')) return 'trendyol.com/magaza/...';
    if (p.contains('hepsiburada')) return 'hepsiburada.com/magaza/...';
    if (p.contains('instagram')) return 'instagram.com/...';
    if (p.contains('google')) return 'g.page/...';
    if (p.contains('whatsapp')) return 'wa.me/...';
    return 'https://...';
  }
}
