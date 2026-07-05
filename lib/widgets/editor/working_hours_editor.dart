import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/theme/app_colors.dart';

class WorkingHoursEditor extends StatefulWidget {
  final bool bookingIsEnabled;
  final int bookingCapacity;
  final Map<String, dynamic> bookingWorkingHours;
  final Map<String, dynamic> bookingLunchBreak;
  final List<StoreOffering> offerings;
  final String selectedKategori;

  final ValueChanged<bool> onBookingEnabledChanged;
  final ValueChanged<int> onBookingCapacityChanged;
  final VoidCallback onStateChanged;
  final void Function(String) showSnackBar;

  const WorkingHoursEditor({
    super.key,
    required this.bookingIsEnabled,
    required this.bookingCapacity,
    required this.bookingWorkingHours,
    required this.bookingLunchBreak,
    required this.offerings,
    required this.selectedKategori,
    required this.onBookingEnabledChanged,
    required this.onBookingCapacityChanged,
    required this.onStateChanged,
    required this.showSnackBar,
  });

  @override
  State<WorkingHoursEditor> createState() => _WorkingHoursEditorState();
}

class _WorkingHoursEditorState extends State<WorkingHoursEditor> {
  static const Color primaryColor = AppColors.primary;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;
  static const Color softText = AppColors.softText;
  static const Color cardBorder = AppColors.cardBorderDark;
  static const Color inputBg = AppColors.inputBg;
  static const Color dangerColor = Color(0xFFDC2626);

  Widget _buildBookingServicesSection() {
    final config = BusinessCategoryConfig.fromCategoryLabel(widget.selectedKategori);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Randevu Hizmetleri',
              style: TextStyle(
                color: softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (widget.offerings.length < 6)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    widget.offerings.add(
                      StoreOffering(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: '',
                        description: '',
                        price: '',
                        isBookable: true,
                      ),
                    );
                  });
                  widget.onStateChanged();
                },
                icon: const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: primaryColor,
                ),
                label: const Text(
                  'Ekle',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (config.suggestedOfferings.isNotEmpty && widget.offerings.length < 6) ...[
          const Text(
            'Hazır hizmetler (eklemek için dokunun):',
            style: TextStyle(
              color: mutedText,
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
                side: const BorderSide(color: cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                avatar: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: primaryColor,
                  size: 16,
                ),
                label: Text(
                  'Ekle: ${sug.title}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: darkText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  if (widget.offerings.length >= 6) {
                    widget.showSnackBar('En fazla 6 adet hizmet ekleyebilirsiniz.');
                    return;
                  }
                  final trimmedTitle = sug.title.trim().toLowerCase();
                  final isDuplicate = widget.offerings.any(
                    (o) => o.title.trim().toLowerCase() == trimmedTitle,
                  );
                  if (isDuplicate) {
                    widget.showSnackBar('Bu hizmet zaten eklenmiş.');
                    return;
                  }
                  setState(() {
                    widget.offerings.add(
                      StoreOffering(
                        id: '${DateTime.now().millisecondsSinceEpoch}_${sug.title.hashCode}',
                        title: sug.title,
                        description: sug.description,
                        price: sug.price,
                        durationMinutes: sug.durationMinutes,
                        isBookable: true,
                      ),
                    );
                  });
                  widget.onStateChanged();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        if (widget.offerings.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Müşterinin randevu alırken seçeceği hizmetleri ekleyin. Bu liste public profilde görünmez.',
              style: TextStyle(
                color: mutedText.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        for (int i = 0; i < widget.offerings.length; i++) ...[
          _buildBookingServiceRow(i),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildBookingServiceRow(int index) {
    final offering = widget.offerings[index];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
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
                  onChanged: (val) {
                    offering.title = val;
                    widget.onStateChanged();
                  },
                  maxLength: 60,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  style: const TextStyle(
                    fontSize: 13,
                    color: darkText,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Randevu hizmeti (örn: Saç Kesimi)',
                    hintStyle: TextStyle(
                      color: mutedText.withValues(alpha: 0.6),
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
                  onChanged: (val) {
                    offering.price = val;
                    widget.onStateChanged();
                  },
                  maxLength: 30,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  style: const TextStyle(
                    fontSize: 13,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Fiyat (örn: 150 TL)',
                    hintStyle: TextStyle(
                      color: mutedText.withValues(alpha: 0.6),
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
                  setState(() {
                    widget.offerings.removeAt(index);
                  });
                  widget.onStateChanged();
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: dangerColor,
                ),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: cardBorder),
          TextFormField(
            key: ValueKey('${offering.id}-desc'),
            initialValue: offering.description,
            onChanged: (val) {
              offering.description = val;
              widget.onStateChanged();
            },
            maxLength: 120,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              color: softText,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Kısa açıklama (örn: Yıkama ve fön dahil hizmet)',
              hintStyle: TextStyle(
                color: mutedText.withValues(alpha: 0.5),
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
          const Divider(height: 1, color: cardBorder),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.timer_rounded, size: 14, color: mutedText),
              const SizedBox(width: 4),
              const Text(
                'Süre',
                style: TextStyle(
                  fontSize: 12,
                  color: softText,
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
                        color: darkText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    if (val != null) {
                      offering.durationMinutes = val;
                    }
                    offering.isBookable = true;
                  });
                  widget.onStateChanged();
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

  Widget _buildDayRow(String day) {
    final dayNames = {
      '1': 'Pazartesi',
      '2': 'Salı',
      '3': 'Çarşamba',
      '4': 'Perşembe',
      '5': 'Cuma',
      '6': 'Cumartesi',
      '7': 'Pazar',
    };
    final dayHours = widget.bookingWorkingHours[day] ??
        {'start': '09:00', 'end': '19:00', 'active': true};
    final isActive = dayHours['active'] ?? false;

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
                color: isActive ? darkText : mutedText,
              ),
            ),
          ),
          Checkbox(
            value: isActive,
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() {
                dayHours['active'] = val ?? false;
                widget.bookingWorkingHours[day] = dayHours;
              });
              widget.onStateChanged();
            },
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: dayHours['start'] ?? '09:00',
                items: ['07:00', '08:00', '08:30', '09:00', '09:30', '10:00'].map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    if (val != null) {
                      dayHours['start'] = val;
                      widget.bookingWorkingHours[day] = dayHours;
                    }
                  });
                  widget.onStateChanged();
                },
                underline: const SizedBox(),
              ),
            ),
            const Text('-', style: TextStyle(color: mutedText)),
            Expanded(
              child: DropdownButton<String>(
                value: dayHours['end'] ?? '19:00',
                items: [
                  '16:00',
                  '17:00',
                  '18:00',
                  '19:00',
                  '20:00',
                  '21:00',
                  '22:00',
                  '23:00',
                ].map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val, style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    if (val != null) {
                      dayHours['end'] = val;
                      widget.bookingWorkingHours[day] = dayHours;
                    }
                  });
                  widget.onStateChanged();
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
                  color: mutedText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: ExpansionTile(
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: primaryColor, size: 18),
            SizedBox(width: 8),
            Text(
              'Randevu Ayarları',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: darkText,
              ),
            ),
          ],
        ),
        subtitle: Text(
          widget.bookingIsEnabled
              ? 'Aktif · Kapasite: ${widget.bookingCapacity} kişi'
              : 'Pasif',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: widget.bookingIsEnabled ? primaryColor : mutedText,
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
                  color: softText,
                ),
              ),
              const Spacer(),
              Switch(
                value: widget.bookingIsEnabled,
                activeThumbColor: primaryColor,
                onChanged: widget.onBookingEnabledChanged,
              ),
            ],
          ),
          if (widget.bookingIsEnabled) ...[
            const Divider(color: cardBorder),
            const SizedBox(height: 8),
            _buildBookingServicesSection(),
            const Divider(color: cardBorder),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Aynı Anda Kapasite',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: softText,
                  ),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: widget.bookingCapacity,
                  items: [1, 2, 3, 4, 5].map((int val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text(
                        '$val kişi',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      widget.onBookingCapacityChanged(val);
                    }
                  },
                ),
              ],
            ),
            const Divider(color: cardBorder),
            const SizedBox(height: 8),
            const Text(
              'Öğle Arası Saatleri',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: softText,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.bookingLunchBreak['start'] ?? '12:00',
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç',
                      isDense: true,
                    ),
                    items: [
                      '11:00',
                      '11:30',
                      '12:00',
                      '12:30',
                      '13:00',
                      '13:30',
                    ].map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(
                          val,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        if (val != null) {
                          widget.bookingLunchBreak['start'] = val;
                        }
                      });
                      widget.onStateChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.bookingLunchBreak['end'] ?? '13:00',
                    decoration: const InputDecoration(
                      labelText: 'Bitiş',
                      isDense: true,
                    ),
                    items: [
                      '12:00',
                      '12:30',
                      '13:00',
                      '13:30',
                      '14:00',
                      '14:30',
                    ].map((String val) {
                      return DropdownMenuItem<String>(
                        value: val,
                        child: Text(
                          val,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        if (val != null) {
                          widget.bookingLunchBreak['end'] = val;
                        }
                      });
                      widget.onStateChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Aktif',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Checkbox(
                  value: widget.bookingLunchBreak['active'] ?? true,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    setState(() {
                      widget.bookingLunchBreak['active'] = val ?? false;
                    });
                    widget.onStateChanged();
                  },
                ),
              ],
            ),
            const Divider(color: cardBorder),
            const SizedBox(height: 8),
            const Text(
              'Çalışma Gün ve Saatleri',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: softText,
              ),
            ),
            const SizedBox(height: 8),
            for (String day in ['1', '2', '3', '4', '5', '6', '7']) ...[
              _buildDayRow(day),
            ],
          ],
        ],
      ),
    );
  }
}
