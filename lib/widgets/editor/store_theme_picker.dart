import 'package:flutter/material.dart';
import 'package:vitrinx/theme/app_colors.dart';

class StoreThemePicker extends StatelessWidget {
  final String selectedTheme;
  final ValueChanged<String> onThemeChanged;

  const StoreThemePicker({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  static const Color primaryColor = AppColors.primary;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;
  static const Color softText = AppColors.softText;
  static const Color cardBorder = AppColors.cardBorderDark;
  static const Color inputBg = AppColors.inputBg;

  static const List<String> themes = [
    'Premium',
    'Sade',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vitrin Teması',
          style: TextStyle(
            color: softText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: themes.contains(selectedTheme) ? selectedTheme : themes.first,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.palette_rounded, color: mutedText, size: 18),
            filled: true,
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorder),
            ),
          ),
          items: themes.map((theme) {
            return DropdownMenuItem<String>(
              value: theme,
              child: Text(
                theme,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onThemeChanged(val);
            }
          },
        ),
      ],
    );
  }
}
