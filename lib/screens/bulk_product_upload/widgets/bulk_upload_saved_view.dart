import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

typedef OnReset = VoidCallback;
typedef OnDismiss = VoidCallback;

class BulkUploadSavedView extends StatelessWidget {
  final int savedCount;
  final OnReset onReset;
  final OnDismiss onDismiss;

  const BulkUploadSavedView({
    super.key,
    required this.savedCount,
    required this.onReset,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$savedCount ürün eklendi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ürünleriniz vitrininize eklendi.\nDeğişiklikleri yayınlamayı unutmayın.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  static Widget successActions({
    required OnReset onReset,
    required OnDismiss onDismiss,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkText,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Yeni Dosya Yükle'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: onDismiss,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
