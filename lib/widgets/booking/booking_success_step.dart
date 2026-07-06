import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vixrex/theme/app_colors.dart';

class BookingSuccessStep extends StatelessWidget {
  final String trackingLink;
  final ValueChanged<String> onCopyPressed;
  final VoidCallback onClose;

  const BookingSuccessStep({
    super.key,
    required this.trackingLink,
    required this.onCopyPressed,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 64,
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        const Text(
          'Randevu talebiniz başarıyla alındı!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'İşletme randevunuzu onayladığında veya güncellediğinde WhatsApp üzerinden bilgilendirileceksiniz. Aşağıdaki takip bağlantısı üzerinden randevu durumunuzu dilediğiniz an kontrol edebilirsiniz.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.softText,
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                trackingLink,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.softText,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: trackingLink));
                  onCopyPressed('Takip linki kopyalandı.');
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text(
                  'Linki Kopyala',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Kapat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
