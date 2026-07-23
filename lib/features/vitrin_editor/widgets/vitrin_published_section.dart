import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vitrinx/theme/app_colors.dart';

/// Yayınlanan vitrinin özet kartı, aksiyon butonları ve Google görünürlük merkezi.
class VitrinPublishedSection extends StatelessWidget {
  final String vitrinName;
  final String publicLink;
  final String? coverUrl;
  final bool bookingIsEnabled;
  final VoidCallback? onOpenExplore;
  final VoidCallback onOpenBookingManagement;
  final VoidCallback onOpenPublicVitrin;
  final VoidCallback onCopyLink;
  final VoidCallback onShowQrSheet;

  static const Color _primaryColor = AppColors.primary;
  static const Color _darkText = AppColors.darkText;
  static const Color _softText = AppColors.softText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _cardBorder = AppColors.cardBorderDark;

  const VitrinPublishedSection({
    super.key,
    required this.vitrinName,
    required this.publicLink,
    required this.coverUrl,
    required this.bookingIsEnabled,
    required this.onOpenExplore,
    required this.onOpenBookingManagement,
    required this.onOpenPublicVitrin,
    required this.onCopyLink,
    required this.onShowQrSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final cover = coverUrl?.trim() ?? '';

    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child:
                cover.isNotEmpty
                    ? Image.network(
                      cover,
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
                      icon: const Icon(
                        Icons.travel_explore_rounded,
                        size: 18,
                      ),
                      color: _primaryColor,
                      tooltip: 'Keşfet\'te Gör',
                      style: IconButton.styleFrom(
                        backgroundColor: _primaryColor.withValues(alpha: 0.12),
                        minimumSize: const Size(36, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  vitrinName.trim().isNotEmpty ? vitrinName : 'Vitrinim',
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  publicLink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryColor,
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

  Widget _buildActionButtons(BuildContext context) {
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
          color: _primaryColor,
          size: 38,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

/// QR kod gösterme bottom sheet'i.
class VitrinQrSheet extends StatelessWidget {
  final String title;
  final String link;
  final Widget? warningWidget;

  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _cardBorder = AppColors.cardBorderDark;

  const VitrinQrSheet({
    super.key,
    required this.title,
    required this.link,
    this.warningWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _darkText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (warningWidget != null) ...[
            const SizedBox(height: 12),
            warningWidget!,
          ],
          const SizedBox(height: 16),
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _cardBorder),
            ),
            child: QrImageView(
              data: link,
              version: QrVersions.auto,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            link,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
