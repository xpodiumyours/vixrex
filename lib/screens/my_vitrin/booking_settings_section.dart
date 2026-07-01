import 'package:flutter/material.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/my_vitrin/booking_services_section.dart';
import 'package:vitrinx/theme/app_colors.dart';

class BookingSettingsSection extends StatelessWidget {
  final bool bookingIsEnabled;
  final int bookingCapacity;
  final Map<String, dynamic> bookingLunchBreak;
  final Map<String, dynamic> bookingWorkingHours;
  final List<StoreOffering> offerings;
  final String selectedKategori;
  final void Function(bool) onBookingEnabledChanged;
  final void Function(int) onCapacityChanged;
  final VoidCallback onChanged;
  final void Function(String) onShowMessage;

  const BookingSettingsSection({
    super.key,
    required this.bookingIsEnabled,
    required this.bookingCapacity,
    required this.bookingLunchBreak,
    required this.bookingWorkingHours,
    required this.offerings,
    required this.selectedKategori,
    required this.onBookingEnabledChanged,
    required this.onCapacityChanged,
    required this.onChanged,
    required this.onShowMessage,
  });

  static const Color _primaryColor = AppColors.primary;
  static const Color _darkText = AppColors.darkText;
  static const Color _softText = AppColors.softText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _cardBorder = AppColors.border;

  static const Map<String, String> _dayNames = {
    '1': 'Pazartesi',
    '2': 'Salı',
    '3': 'Çarşamba',
    '4': 'Perşembe',
    '5': 'Cuma',
    '6': 'Cumartesi',
    '7': 'Pazar',
  };

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
            Icon(Icons.calendar_month_rounded, color: _primaryColor, size: 18),
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
            BookingServicesSection(
              offerings: offerings,
              selectedKategori: selectedKategori,
              onShowMessage: onShowMessage,
              onChanged: onChanged,
            ),
            const Divider(color: _cardBorder),
            const SizedBox(height: 8),
            Row(
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
            ),
            const Divider(color: _cardBorder),
            const SizedBox(height: 8),
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
                    items: ['11:00', '11:30', '12:00', '12:30', '13:00', '13:30']
                        .map((String val) => DropdownMenuItem<String>(
                              value: val,
                              child: Text(val, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        bookingLunchBreak['start'] = val;
                        onChanged();
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
                    items: ['12:00', '12:30', '13:00', '13:30', '14:00', '14:30']
                        .map((String val) => DropdownMenuItem<String>(
                              value: val,
                              child: Text(val, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        bookingLunchBreak['end'] = val;
                        onChanged();
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
                    bookingLunchBreak['active'] = val ?? false;
                    onChanged();
                  },
                ),
              ],
            ),
            const Divider(color: _cardBorder),
            const SizedBox(height: 8),
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
        ],
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final dayHours =
        (bookingWorkingHours[day] as Map<String, dynamic>?) ??
        {'start': '09:00', 'end': '19:00', 'active': true};
    final isActive = dayHours['active'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              _dayNames[day]!,
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
              dayHours['active'] = val ?? false;
              bookingWorkingHours[day] = dayHours;
              onChanged();
            },
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: dayHours['start'] as String? ?? '09:00',
                items: ['07:00', '08:00', '08:30', '09:00', '09:30', '10:00']
                    .map((String val) => DropdownMenuItem<String>(
                          value: val,
                          child: Text(val, style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    dayHours['start'] = val;
                    bookingWorkingHours[day] = dayHours;
                    onChanged();
                  }
                },
                underline: const SizedBox(),
              ),
            ),
            const Text('-', style: TextStyle(color: _mutedText)),
            Expanded(
              child: DropdownButton<String>(
                value: dayHours['end'] as String? ?? '19:00',
                items: ['16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00']
                    .map((String val) => DropdownMenuItem<String>(
                          value: val,
                          child: Text(val, style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    dayHours['end'] = val;
                    bookingWorkingHours[day] = dayHours;
                    onChanged();
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
