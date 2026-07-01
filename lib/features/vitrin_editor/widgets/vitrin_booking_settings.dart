import 'package:flutter/material.dart';
import 'package:vitrinx/config/business_category_config.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Randevu hizmetleri ve çalışma saati ayarları widget'ı.
/// Yalnızca "Kuaför" kategorisi seçildiğinde gösterilir.
class VitrinBookingSettings extends StatelessWidget {
  final bool bookingIsEnabled;
  final int bookingCapacity;
  final Map<String, dynamic> bookingWorkingHours;
  final Map<String, dynamic> bookingLunchBreak;
  final List<StoreOffering> offerings;
  final String selectedKategori;
  final void Function(bool) onBookingEnabledChanged;
  final void Function(int) onCapacityChanged;
  final void Function(String day, Map<String, dynamic> hours)
  onWorkingHoursChanged;
  final void Function(Map<String, dynamic>) onLunchBreakChanged;
  final void Function(List<StoreOffering>) onOfferingsChanged;
  final void Function(String) onShowMessage;

  static const Color _primaryColor = AppColors.primary;
  static const Color _softText = AppColors.softText;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _cardBorder = AppColors.cardBorderDark;
  static const Color _dangerColor = Color(0xFFDC2626);

  const VitrinBookingSettings({
    super.key,
    required this.bookingIsEnabled,
    required this.bookingCapacity,
    required this.bookingWorkingHours,
    required this.bookingLunchBreak,
    required this.offerings,
    required this.selectedKategori,
    required this.onBookingEnabledChanged,
    required this.onCapacityChanged,
    required this.onWorkingHoursChanged,
    required this.onLunchBreakChanged,
    required this.onOfferingsChanged,
    required this.onShowMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: ExpansionTile(
        title: const Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: _primaryColor,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Randevu Ayarları',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _darkText,
              ),
            ),
          ],
        ),
        subtitle: Text(
          bookingIsEnabled
              ? 'Aktif · Kapasite: $bookingCapacity kişi'
              : 'Pasif',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: bookingIsEnabled ? _primaryColor : _mutedText,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
        shape: const Border(),
        children: [
          Row(
            children: [
              const Text(
                'Randevu Alınabilsin',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _softText,
                ),
              ),
              const Spacer(),
              Switch(
                value: bookingIsEnabled,
                activeThumbColor: _primaryColor,
                onChanged: onBookingEnabledChanged,
              ),
            ],
          ),
          if (bookingIsEnabled) ...[
            const Divider(color: _cardBorder),
            const SizedBox(height: 8),
            _buildServicesSection(),
            const Divider(color: _cardBorder),
            const SizedBox(height: 8),
            _buildCapacityRow(),
            const Divider(color: _cardBorder),
            const SizedBox(height: 8),
            _buildLunchBreakSection(),
            const Divider(color: _cardBorder),
            const SizedBox(height: 8),
            _buildWorkingHoursSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
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
                  final updated = List<StoreOffering>.from(offerings)
                    ..add(
                      StoreOffering(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: '',
                        description: '',
                        price: '',
                        isBookable: true,
                      ),
                    );
                  onOfferingsChanged(updated);
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
                  final updated = List<StoreOffering>.from(offerings)
                    ..add(
                      StoreOffering(
                        id:
                            '${DateTime.now().millisecondsSinceEpoch}_${sug.title.hashCode}',
                        title: sug.title,
                        description: sug.description,
                        price: sug.price,
                        durationMinutes: sug.durationMinutes,
                        isBookable: true,
                      ),
                    );
                  onOfferingsChanged(updated);
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
        color: AppColors.inputBg,
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
                      (context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
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
                      (context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
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
                  final updated = List<StoreOffering>.from(offerings)
                    ..removeAt(index);
                  onOfferingsChanged(updated);
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
                (context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
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
                  if (val != null) {
                    offering.durationMinutes = val;
                    offering.isBookable = true;
                    onOfferingsChanged(List<StoreOffering>.from(offerings));
                  }
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

  Widget _buildCapacityRow() {
    return Row(
      children: [
        const Text(
          'Aynı Anda Kapasite',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _softText,
          ),
        ),
        const Spacer(),
        DropdownButton<int>(
          value: bookingCapacity,
          items: [1, 2, 3, 4, 5].map((int val) {
            return DropdownMenuItem<int>(
              value: val,
              child: Text(
                '$val kişi',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onCapacityChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildLunchBreakSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Öğle Arası Saatleri',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _softText,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: bookingLunchBreak['start'] ?? '12:00',
                decoration: const InputDecoration(
                  labelText: 'Başlangıç',
                  isDense: true,
                ),
                items:
                    ['11:00', '11:30', '12:00', '12:30', '13:00', '13:30']
                        .map(
                          (String val) => DropdownMenuItem<String>(
                            value: val,
                            child: Text(
                              val,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) {
                    onLunchBreakChanged({...bookingLunchBreak, 'start': val});
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: bookingLunchBreak['end'] ?? '13:00',
                decoration: const InputDecoration(
                  labelText: 'Bitiş',
                  isDense: true,
                ),
                items:
                    ['12:00', '12:30', '13:00', '13:30', '14:00', '14:30']
                        .map(
                          (String val) => DropdownMenuItem<String>(
                            value: val,
                            child: Text(
                              val,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) {
                    onLunchBreakChanged({...bookingLunchBreak, 'end': val});
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Aktif',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Checkbox(
              value: bookingLunchBreak['active'] ?? true,
              activeColor: _primaryColor,
              onChanged: (val) {
                onLunchBreakChanged({...bookingLunchBreak, 'active': val ?? false});
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkingHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Çalışma Gün ve Saatleri',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _softText,
          ),
        ),
        const SizedBox(height: 8),
        for (final day in ['1', '2', '3', '4', '5', '6', '7'])
          _buildDayRow(day),
      ],
    );
  }

  Widget _buildDayRow(String day) {
    const dayNames = {
      '1': 'Pazartesi',
      '2': 'Salı',
      '3': 'Çarşamba',
      '4': 'Perşembe',
      '5': 'Cuma',
      '6': 'Cumartesi',
      '7': 'Pazar',
    };
    final dayHours =
        (bookingWorkingHours[day] as Map<String, dynamic>?) ??
        {'start': '09:00', 'end': '19:00', 'active': true};
    final isActive = (dayHours['active'] as bool?) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              dayNames[day]!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? _darkText : _mutedText,
              ),
            ),
          ),
          Checkbox(
            value: isActive,
            activeColor: _primaryColor,
            onChanged: (val) {
              final updated = Map<String, dynamic>.from(dayHours)
                ..[' active'] = val ?? false;
              // Fix key name without extra space
              final fixed = {...dayHours, 'active': val ?? false};
              onWorkingHoursChanged(day, fixed);
            },
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: dayHours['start'] ?? '09:00',
                items:
                    ['07:00', '08:00', '08:30', '09:00', '09:30', '10:00']
                        .map(
                          (String val) => DropdownMenuItem<String>(
                            value: val,
                            child: Text(
                              val,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) {
                    onWorkingHoursChanged(day, {...dayHours, 'start': val});
                  }
                },
                underline: const SizedBox(),
              ),
            ),
            const Text('-', style: TextStyle(color: _mutedText)),
            Expanded(
              child: DropdownButton<String>(
                value: dayHours['end'] ?? '19:00',
                items:
                    [
                          '16:00',
                          '17:00',
                          '18:00',
                          '19:00',
                          '20:00',
                          '21:00',
                          '22:00',
                          '23:00',
                        ]
                        .map(
                          (String val) => DropdownMenuItem<String>(
                            value: val,
                            child: Text(
                              val,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) {
                    onWorkingHoursChanged(day, {...dayHours, 'end': val});
                  }
                },
                underline: const SizedBox(),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Text(
                'Kapalı',
                style: TextStyle(
                  fontSize: 12,
                  color: _mutedText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
