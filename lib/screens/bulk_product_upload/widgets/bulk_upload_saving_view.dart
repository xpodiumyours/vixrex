import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

const _textStyle = TextStyle(color: AppColors.mutedText);

class BulkUploadSavingView extends StatelessWidget {
  const BulkUploadSavingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Ürünler kaydediliyor...', style: _textStyle),
        ],
      ),
    );
  }
}
