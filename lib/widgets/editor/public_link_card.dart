import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class PublicLinkCard extends StatelessWidget {
  final TextEditingController controller;
  final String? publicLink;
  final VoidCallback onOpenLink;
  final VoidCallback onCopyLink;
  final VoidCallback onShareLink;

  const PublicLinkCard({
    super.key,
    required this.controller,
    required this.publicLink,
    required this.onOpenLink,
    required this.onCopyLink,
    required this.onShareLink,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPublicLink = publicLink?.trim();
    final hasPublicLink =
        trimmedPublicLink != null && trimmedPublicLink.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Website',
          style: TextStyle(
            color: AppColors.softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            prefixIcon: IconButton(
              tooltip: 'Web linkini aç',
              onPressed: onOpenLink,
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
            suffixIcon:
                hasPublicLink
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Linki kopyala',
                          onPressed: onCopyLink,
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: AppColors.mutedText,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Linki paylaş',
                          onPressed: onShareLink,
                          icon: const Icon(
                            Icons.ios_share_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ],
                    )
                    : null,
            hintText: 'Yayına aldığınızda özel web linkiniz burada oluşur.',
            hintStyle: TextStyle(
              color: AppColors.mutedText.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
        ),
      ],
    );
  }
}
