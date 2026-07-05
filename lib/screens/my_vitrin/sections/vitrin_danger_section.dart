import 'package:flutter/material.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';

class VitrinDangerSection extends StatelessWidget {
  final MyVitrinState state;

  const VitrinDangerSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final ctrl = state.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: ctrl.isWithdrawingConsent
                ? null
                : () => state.handleWithdraw(context),
            icon: const Icon(Icons.visibility_off_outlined, size: 16),
            label: Text(
              ctrl.isWithdrawingConsent
                  ? 'Yayından kaldırılıyor...'
                  : 'Yayınlama Rızasını Geri Çek',
              style: AppTextStyles.labelBold,
            ),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: ctrl.isDeleting
                ? null
                : () => _showDeleteConfirmation(context),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Color(0xFFDC2626),
            ),
            label: const Text(
              'Vitrini Sil',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Vitrini Sil',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        content: const Text(
          'Bu işlem geri alınamaz. Vitrininiz kalıcı olarak silinecektir.',
          style: TextStyle(
            color: AppColors.softText,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Vazgeç',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.mutedText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.handleDelete(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
