import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class PublicWebsiteLinkSection extends StatelessWidget {
  final String? publicLink;
  final TextEditingController websiteController;
  final VoidCallback onOpenLink;
  final VoidCallback onCopyLink;
  final VoidCallback onShareLink;

  const PublicWebsiteLinkSection({
    super.key,
    required this.publicLink,
    required this.websiteController,
    required this.onOpenLink,
    required this.onCopyLink,
    required this.onShareLink,
  });

  static const Color _primaryColor = AppColors.primary;
  static const Color _darkText = AppColors.darkText;
  static const Color _softText = AppColors.softText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.border;

  bool get _hasPublicLink => publicLink != null && publicLink!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Website',
          style: TextStyle(
            color: _softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: websiteController,
          keyboardType: TextInputType.url,
          style: const TextStyle(
            color: _darkText,
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
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: _primaryColor,
                  size: 18,
                ),
              ),
            ),
            suffixIcon:
                _hasPublicLink
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Linki kopyala',
                          onPressed: onCopyLink,
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: _mutedText,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Linki paylaş',
                          onPressed: onShareLink,
                          icon: const Icon(
                            Icons.ios_share_rounded,
                            color: _primaryColor,
                            size: 18,
                          ),
                        ),
                      ],
                    )
                    : null,
            hintText: 'Yayına aldığınızda özel web linkiniz burada oluşur.',
            hintStyle: TextStyle(
              color: _mutedText.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: _inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primaryColor, width: 1.4),
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
