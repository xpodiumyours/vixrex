import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

/// Mağazaya özel Vixrex vitrin linki (işletmenin kendi web sitesi değildir).
/// İsim yazılınca öngörülen link; yayın sonrası canlı link gösterilir.
class PublicLinkCard extends StatelessWidget {
  final String? displayLink;
  final bool isLive;
  final VoidCallback onCopyLink;
  final VoidCallback onPreview;
  final VoidCallback? onShareLink;
  final VoidCallback? onOpenLiveLink;
  final VoidCallback? onScrollToPublish;

  const PublicLinkCard({
    super.key,
    required this.displayLink,
    required this.isLive,
    required this.onCopyLink,
    required this.onPreview,
    this.onShareLink,
    this.onOpenLiveLink,
    this.onScrollToPublish,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedLink = displayLink?.trim();
    final hasLink = trimmedLink != null && trimmedLink.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Paylaşım linki',
                style: TextStyle(
                  color: AppColors.softText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (hasLink && isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF12B76A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Canlı',
                  style: TextStyle(
                    color: Color(0xFF12B76A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            prefixIcon: IconButton(
              tooltip: isLive ? 'Canlı vitrin linkini aç' : 'Önizlemeyi aç',
              onPressed: hasLink
                  ? (isLive ? (onOpenLiveLink ?? onPreview) : onPreview)
                  : null,
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLive ? Icons.link_rounded : Icons.visibility_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cardBorderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          child: hasLink
              ? SelectableText(
                  trimmedLink,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Text(
                  'İşletme adı yazınca oluşur.',
                  style: TextStyle(
                    color: AppColors.mutedText.withValues(alpha: 0.62),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        if (hasLink && !isLive) ...[
          const SizedBox(height: 6),
          Text(
            'Yayından sonra tarayıcıda açılır.',
            style: TextStyle(
              color: AppColors.mutedText.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (hasLink) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: Icons.copy_rounded,
                label: 'Kopyala',
                onTap: onCopyLink,
              ),
              _ActionChip(
                icon: Icons.visibility_rounded,
                label: 'Önizle',
                onTap: onPreview,
              ),
              if (isLive && onShareLink != null)
                _ActionChip(
                  icon: Icons.ios_share_rounded,
                  label: 'Paylaş',
                  onTap: onShareLink!,
                ),
              if (!isLive && onScrollToPublish != null)
                _ActionChip(
                  icon: Icons.rocket_launch_rounded,
                  label: 'Yayına al',
                  emphasized: true,
                  onTap: onScrollToPublish!,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasized
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.inputBg;
    final fg = emphasized ? AppColors.primary : AppColors.darkText;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
