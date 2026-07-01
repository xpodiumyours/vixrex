import 'package:flutter/material.dart';
import 'package:vitrinx/config/business_category_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/app_colors.dart';

class BookingServicesSection extends StatelessWidget {
  final List<StoreOffering> offerings;
  final String selectedKategori;
  final void Function(String) onShowMessage;
  final VoidCallback onChanged;

  const BookingServicesSection({
    super.key,
    required this.offerings,
    required this.selectedKategori,
    required this.onShowMessage,
    required this.onChanged,
  });

  static const Color _primaryColor = AppColors.primary;
  static const Color _darkText = AppColors.darkText;
  static const Color _softText = AppColors.softText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.border;
  static const Color _dangerColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final config = BusinessCategoryConfig.fromCategoryLabel(selectedKategori);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Randevu Hizmetleri',
              style: TextStyle(
                color: _softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (offerings.length < 6)
              TextButton.icon(
                onPressed: () {
                  offerings.add(
                    StoreOffering(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: '',
                      description: '',
                      price: '',
                      isBookable: true,
                    ),
                  );
                  onChanged();
                },
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
        const SizedBox(height: 6),
        if (config.suggestedOfferings.isNotEmpty && offerings.length < 6) ...[
          const Text(
            'Hazır hizmetler (eklemek için dokunun):',
            style: TextStyle(
              color: _mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: config.suggestedOfferings.map((sug) {
              return ActionChip(
                backgroundColor: AppColors.surfaceSoft,
                side: const BorderSide(color: _cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                avatar: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: _primaryColor,
                  size: 16,
                ),
                label: Text(
                  'Ekle: ${sug.title}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _darkText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  if (offerings.length >= 6) {
                    onShowMessage('En fazla 6 adet hizmet ekleyebilirsiniz.');
                    return;
                  }
                  final trimmedTitle = sug.title.trim().toLowerCase();
                  final isDuplicate = offerings.any(
                    (o) => o.title.trim().toLowerCase() == trimmedTitle,
                  );
                  if (isDuplicate) {
                    onShowMessage('Bu hizmet zaten eklenmiş.');
                    return;
                  }
                  offerings.add(
                    StoreOffering(
                      id: '${DateTime.now().millisecondsSinceEpoch}_${sug.title.hashCode}',
                      title: sug.title,
                      description: sug.description,
                      price: sug.price,
                      durationMinutes: sug.durationMinutes,
                      isBookable: true,
                    ),
                  );
                  onChanged();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        if (offerings.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Müşterinin randevu alırken seçeceği hizmetleri ekleyin. Bu liste public profilde görünmez.',
              style: TextStyle(
                color: _mutedText.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        for (int i = 0; i < offerings.length; i++) ...[
          _buildServiceRow(i),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildServiceRow(int index) {
    final offering = offerings[index];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: ValueKey('${offering.id}-title'),
                  initialValue: offering.title,
                  onChanged: (val) => offering.title = val,
                  maxLength: 60,
                  buildCounter:
                      (context, {required currentLength, required isFocused, maxLength}) =>
                          null,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _darkText,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Randevu hizmeti (örn: Saç Kesimi)',
                    hintStyle: TextStyle(
                      color: _mutedText.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: ValueKey('${offering.id}-price'),
                  initialValue: offering.price,
                  onChanged: (val) => offering.price = val,
                  maxLength: 30,
                  buildCounter:
                      (context, {required currentLength, required isFocused, maxLength}) =>
                          null,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Fiyat (örn: 150 TL)',
                    hintStyle: TextStyle(
                      color: _mutedText.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  offerings.removeAt(index);
                  onChanged();
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: _dangerColor,
                ),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: _cardBorder),
          TextFormField(
            key: ValueKey('${offering.id}-desc'),
            initialValue: offering.description,
            onChanged: (val) => offering.description = val,
            maxLength: 120,
            buildCounter:
                (context, {required currentLength, required isFocused, maxLength}) =>
                    null,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              color: _softText,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Kısa açıklama (örn: Yıkama ve fön dahil hizmet)',
              hintStyle: TextStyle(
                color: _mutedText.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: InputBorder.none,
            ),
          ),
          const Divider(height: 1, color: _cardBorder),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.timer_rounded, size: 14, color: _mutedText),
              const SizedBox(width: 4),
              const Text(
                'Süre',
                style: TextStyle(
                  fontSize: 12,
                  color: _softText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: offering.durationMinutes,
                items: [15, 30, 45, 60, 90, 120, 180, 240].map((int val) {
                  return DropdownMenuItem<int>(
                    value: val,
                    child: Text(
                      '$val dk',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _darkText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) offering.durationMinutes = val;
                  offering.isBookable = true;
                  onChanged();
                },
                underline: const SizedBox(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}
