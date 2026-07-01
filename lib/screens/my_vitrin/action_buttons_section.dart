import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class ActionButtonsSection extends StatelessWidget {
  final bool bookingIsEnabled;
  final VoidCallback onOpenBookingManagement;
  final VoidCallback onOpenPublicVitrin;
  final VoidCallback onCopyLink;
  final VoidCallback onShowQrSheet;

  const ActionButtonsSection({
    super.key,
    required this.bookingIsEnabled,
    required this.onOpenBookingManagement,
    required this.onOpenPublicVitrin,
    required this.onCopyLink,
    required this.onShowQrSheet,
  });

  static const Color _darkText = AppColors.darkText;
  static const Color _cardBorder = AppColors.border;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth =
            constraints.maxWidth < 520
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (bookingIsEnabled)
              _actionButton(
                width: buttonWidth,
                label: 'Randevuları Yönet',
                icon: Icons.calendar_month_rounded,
                onPressed: onOpenBookingManagement,
              ),
            _actionButton(
              width: buttonWidth,
              label: 'Yayındaki Vitrini Aç',
              icon: Icons.open_in_new_rounded,
              onPressed: onOpenPublicVitrin,
            ),
            _actionButton(
              width: buttonWidth,
              label: 'Linki Kopyala',
              icon: Icons.copy_rounded,
              onPressed: onCopyLink,
            ),
            _actionButton(
              width: buttonWidth,
              label: 'QR Göster',
              icon: Icons.qr_code_2_rounded,
              onPressed: onShowQrSheet,
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton({
    required double width,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkText,
          backgroundColor: AppColors.surfaceSoft,
          side: const BorderSide(color: _cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
