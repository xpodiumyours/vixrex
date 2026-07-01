import 'package:flutter/material.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/theme/app_text_styles.dart';

class PublishedSummaryCard extends StatelessWidget {
  final PublishedVitrinInfo info;
  final String coverUrl;
  final VoidCallback? onOpenExplore;

  const PublishedSummaryCard({
    super.key,
    required this.info,
    required this.coverUrl,
    required this.onOpenExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child:
                coverUrl.isNotEmpty
                    ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder(),
                    )
                    : _coverPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Keşfet\'te yayında',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onOpenExplore,
                      icon: const Icon(Icons.travel_explore_rounded, size: 18),
                      color: AppColors.primary,
                      tooltip: 'Keşfet\'te Gör',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        minimumSize: const Size(36, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  info.name.trim().isNotEmpty ? info.name : 'Vitrinim',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  info.publicLink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceSoft, AppColors.bgEditor],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          color: AppColors.primary,
          size: 38,
        ),
      ),
    );
  }
}

class PublishActionsSection extends StatelessWidget {
  final bool bookingIsEnabled;
  final VoidCallback onOpenBookingManagement;
  final VoidCallback onOpenPublicVitrin;
  final VoidCallback onCopyLink;
  final VoidCallback onShowQrSheet;

  const PublishActionsSection({
    super.key,
    required this.bookingIsEnabled,
    required this.onOpenBookingManagement,
    required this.onOpenPublicVitrin,
    required this.onCopyLink,
    required this.onShowQrSheet,
  });

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
              _ActionButton(
                width: buttonWidth,
                label: 'Randevuları Yönet',
                icon: Icons.calendar_month_rounded,
                onPressed: onOpenBookingManagement,
              ),
            _ActionButton(
              width: buttonWidth,
              label: 'Yayındaki Vitrini Aç',
              icon: Icons.open_in_new_rounded,
              onPressed: onOpenPublicVitrin,
            ),
            _ActionButton(
              width: buttonWidth,
              label: 'Linki Kopyala',
              icon: Icons.copy_rounded,
              onPressed: onCopyLink,
            ),
            _ActionButton(
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
}

class PublicationDangerActions extends StatelessWidget {
  final bool isWithdrawingConsent;
  final bool isDeleting;
  final VoidCallback onWithdrawPublicationConsent;
  final VoidCallback onShowDeleteConfirmation;

  const PublicationDangerActions({
    super.key,
    required this.isWithdrawingConsent,
    required this.isDeleting,
    required this.onWithdrawPublicationConsent,
    required this.onShowDeleteConfirmation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: TextButton.icon(
            onPressed:
                isWithdrawingConsent ? null : onWithdrawPublicationConsent,
            icon: const Icon(Icons.visibility_off_outlined, size: 16),
            label: Text(
              isWithdrawingConsent
                  ? 'Yayından kaldırılıyor...'
                  : 'Yayınlama Rızasını Geri Çek',
              style: AppTextStyles.labelBold,
            ),
          ),
        ),
        Center(
          child: TextButton.icon(
            onPressed: isDeleting ? null : onShowDeleteConfirmation,
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
}

class _ActionButton extends StatelessWidget {
  final double width;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.width,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
          foregroundColor: AppColors.darkText,
          backgroundColor: AppColors.surfaceSoft,
          side: const BorderSide(color: AppColors.cardBorderDark),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.cardBorderDark),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}
