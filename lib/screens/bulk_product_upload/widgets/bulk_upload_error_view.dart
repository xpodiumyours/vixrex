import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

typedef OnRetry = VoidCallback;

class BulkUploadErrorView extends StatelessWidget {
  final String? errorMessage;
  final OnRetry onRetry;

  const BulkUploadErrorView({
    super.key,
    this.errorMessage,
    required this.onRetry,
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
              color: AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bir hata oluştu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Bilinmeyen hata',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
