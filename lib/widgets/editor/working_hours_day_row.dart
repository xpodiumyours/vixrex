import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class WorkingHoursDayRow extends StatefulWidget {
  final String day;
  final Map<String, dynamic> bookingWorkingHours;
  final VoidCallback onStateChanged;

  const WorkingHoursDayRow({
    super.key,
    required this.day,
    required this.bookingWorkingHours,
    required this.onStateChanged,
  });

  @override
  State<WorkingHoursDayRow> createState() => _WorkingHoursDayRowState();
}

class _WorkingHoursDayRowState extends State<WorkingHoursDayRow> {
  static const Color primaryColor = AppColors.primary;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;

  @override
  Widget build(BuildContext context) {
    final dayNames = {
      '1': 'Pazartesi',
      '2': 'Salı',
      '3': 'Çarşamba',
      '4': 'Perşembe',
      '5': 'Cuma',
      '6': 'Cumartesi',
      '7': 'Pazar',
    };
    final dayHours = widget.bookingWorkingHours[widget.day] ??
        {'start': '09:00', 'end': '19:00', 'active': true};
    final isActive = dayHours['active'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              dayNames[widget.day]!,
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
                widget.bookingWorkingHours[widget.day] = dayHours;
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
                      widget.bookingWorkingHours[widget.day] = dayHours;
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
                      widget.bookingWorkingHours[widget.day] = dayHours;
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
}
