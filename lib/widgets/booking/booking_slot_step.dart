import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class BookingSlotStep extends StatelessWidget {
  final bool isLoadingSlots;
  final List<dynamic> availableSlots;
  final String? selectedSlotTime;
  final ValueChanged<String> onSlotSelected;

  const BookingSlotStep({
    super.key,
    required this.isLoadingSlots,
    required this.availableSlots,
    required this.selectedSlotTime,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (availableSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Seçilen tarihte müsait randevu saati bulunmamaktadır.',
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
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: availableSlots.length,
      itemBuilder: (context, index) {
        final slot = availableSlots[index];
        final timeStr = slot['time'] as String;
        final slotsLeft = slot['slots_left'] as int;
        final hasPending = slot['has_pending'] as bool;
        final isFull = slotsLeft == 0;
        final isSelected = selectedSlotTime == timeStr;

        Color cardBg = Colors.white;
        Color borderCol = AppColors.border;
        Color textCol = AppColors.darkText;
        Color subTextCol = AppColors.mutedText;
        String statusLabel = '$slotsLeft yer';

        if (isFull) {
          cardBg = AppColors.bgEditor;
          textCol = AppColors.disabled;
          subTextCol = AppColors.disabled;
          final confirmedList = slot['confirmed_names'] as List?;
          statusLabel = (confirmedList != null && confirmedList.isNotEmpty)
              ? confirmedList.join(', ')
              : 'Dolu';
        } else if (hasPending) {
          cardBg = Colors.amber.withValues(alpha: 0.1);
          borderCol = Colors.amber.withValues(alpha: 0.3);
          textCol = Colors.orange;
          subTextCol = Colors.orange;
          statusLabel = 'Geçici ayrıldı';
        } else if (isSelected) {
          cardBg = AppColors.surfaceSoft;
          borderCol = AppColors.primary;
          textCol = AppColors.primaryDark;
          subTextCol = AppColors.primaryDark;
        }

        return InkWell(
          onTap: isFull || hasPending ? null : () => onSlotSelected(timeStr),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderCol,
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: subTextCol,
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
