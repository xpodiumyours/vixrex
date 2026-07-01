import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/utils/whatsapp_link_helper.dart';

/// Vitrin editörü için yeniden kullanılabilir metin alanı widget'ı.
class VitrinTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? errorText;
  final bool validateWhatsapp;
  final FocusNode? focusNode;
  final ValueChanged<String?>? onNameErrorChanged;
  final ValueChanged<String?>? onAddressErrorChanged;
  final ValueChanged<String?>? onWhatsappErrorChanged;

  static const Color _primaryColor = AppColors.primary;
  static const Color _softText = AppColors.softText;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.cardBorderDark;

  const VitrinTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.errorText,
    this.validateWhatsapp = false,
    this.focusNode,
    this.onNameErrorChanged,
    this.onAddressErrorChanged,
    this.onWhatsappErrorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _softText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: _darkText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          onChanged: (value) {
            if (errorText != null || validateWhatsapp) {
              onNameErrorChanged?.call(null);
              onAddressErrorChanged?.call(null);
              if (validateWhatsapp) {
                onWhatsappErrorChanged?.call(
                  value.trim().isEmpty ||
                          WhatsAppLinkHelper.isValidTurkeyMobile(value)
                      ? null
                      : WhatsAppLinkHelper.invalidNumberMessage,
                );
              } else {
                onWhatsappErrorChanged?.call(null);
              }
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _mutedText, size: 18),
            hintText: hint,
            hintStyle: TextStyle(
              color: _mutedText.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: _inputBg,
            errorText: errorText,
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

/// Vitrin editörü için yeniden kullanılabilir dropdown widget'ı.
class VitrinDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  static const Color _softText = AppColors.softText;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.cardBorderDark;

  const VitrinDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : items.first,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _mutedText, size: 18),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cardBorder),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Vitrin yayın linki gösterme ve kopyalama kartı.
class VitrinWebsiteLinkCard extends StatelessWidget {
  final TextEditingController websiteController;
  final bool hasPublicLink;
  final VoidCallback onOpenLink;
  final VoidCallback onCopyLink;
  final VoidCallback onShareLink;

  static const Color _primaryColor = AppColors.primary;
  static const Color _softText = AppColors.softText;
  static const Color _darkText = AppColors.darkText;
  static const Color _mutedText = AppColors.mutedText;
  static const Color _inputBg = AppColors.inputBg;
  static const Color _cardBorder = AppColors.cardBorderDark;

  const VitrinWebsiteLinkCard({
    super.key,
    required this.websiteController,
    required this.hasPublicLink,
    required this.onOpenLink,
    required this.onCopyLink,
    required this.onShareLink,
  });

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
                hasPublicLink
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
