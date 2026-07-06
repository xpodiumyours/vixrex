import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class BookingDateStep extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const BookingDateStep({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  String _formatDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final monthNames = {
      1: 'Oca',
      2: 'Şub',
      3: 'Mar',
      4: 'Nis',
      5: 'May',
      6: 'Haz',
      7: 'Tem',
      8: 'Ağu',
      9: 'Eyl',
      10: 'Eki',
      11: 'Kas',
      12: 'Ara'
    };
    return '$day ${monthNames[date.month]}';
  }

  String _formatDayName(DateTime date) {
    final dayNames = {
      1: 'Pzt',
      2: 'Sal',
      3: 'Çar',
      4: 'Per',
      5: 'Cum',
      6: 'Cmt',
      7: 'Paz',
    };
    return dayNames[date.weekday]!;
  }

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'İşletmenin önümüzdeki 30 gün boyunca aktif çalışma saati bulunmamaktadır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final isSelected = selectedDate?.year == date.year &&
            selectedDate?.month == date.month &&
            selectedDate?.day == date.day;

        return InkWell(
          onTap: () => onDateSelected(date),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surfaceSoft : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDayName(date),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? AppColors.primaryDark : AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateLabel(date),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
