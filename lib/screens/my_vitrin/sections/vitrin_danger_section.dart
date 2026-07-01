import 'package:flutter/material.dart';

class VitrinDangerSection extends StatelessWidget {
  final bool isWithdrawingConsent;
  final bool isDeleting;
  final VoidCallback onWithdrawConsent;
  final VoidCallback onShowDeleteConfirmation;
  final TextStyle withdrawTextStyle;
  final Color dangerColor;

  const VitrinDangerSection({
    super.key,
    required this.isWithdrawingConsent,
    required this.isDeleting,
    required this.onWithdrawConsent,
    required this.onShowDeleteConfirmation,
    required this.withdrawTextStyle,
    required this.dangerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: isWithdrawingConsent ? null : onWithdrawConsent,
            icon: const Icon(Icons.visibility_off_outlined, size: 16),
            label: Text(
              isWithdrawingConsent
                  ? 'Yayından kaldırılıyor...'
                  : 'Yayınlama Rızasını Geri Çek',
              style: withdrawTextStyle,
            ),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: isDeleting ? null : onShowDeleteConfirmation,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: dangerColor,
            ),
            label: Text(
              'Vitrini Sil',
              style: TextStyle(
                color: dangerColor,
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
}
