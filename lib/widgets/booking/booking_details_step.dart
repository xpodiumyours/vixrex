import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';

class BookingDetailsStep extends StatefulWidget {
  final StoreOffering selectedService;
  final DateTime selectedDate;
  final String selectedSlotTime;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final bool kvkkConsent;
  final ValueChanged<bool> onKvkkConsentChanged;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const BookingDetailsStep({
    super.key,
    required this.selectedService,
    required this.selectedDate,
    required this.selectedSlotTime,
    required this.nameController,
    required this.phoneController,
    required this.notesController,
    required this.kvkkConsent,
    required this.onKvkkConsentChanged,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<BookingDetailsStep> createState() => _BookingDetailsStepState();
}

class _BookingDetailsStepState extends State<BookingDetailsStep> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.selectedService.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tarih: ${_formatDayName(widget.selectedDate)} ${_formatDateLabel(widget.selectedDate)} saat ${widget.selectedSlotTime}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.softText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.nameController,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Ad Soyad *',
            hintText: 'Örn: Ahmet Ozan',
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            labelText: 'Telefon Numarası *',
            hintText: '05xx xxx xx xx',
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.notesController,
          maxLines: 2,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: 'Not (İsteğe bağlı)',
            hintText: 'Belirtmek istediğiniz özel bir durum var mı?',
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: widget.kvkkConsent,
              activeColor: AppColors.primary,
              onChanged: (val) => widget.onKvkkConsentChanged(val ?? false),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  'Kişisel verilerimin işlenmesini ve isim maskeleme (A*** O***) yöntemiyle public takvimde gösterilmesini kabul ediyorum.',
                  style: TextStyle(
                    color: AppColors.softText,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: widget.isSubmitting ? null : widget.onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: widget.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Randevu Talebi Oluştur',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }
}
