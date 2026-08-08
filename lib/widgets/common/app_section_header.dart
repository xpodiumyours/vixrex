import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_text_styles.dart';

/// Ekran içi bölüm başlığı — başlık + isteğe bağlı açıklama, tek stil.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.description,
  });

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(description!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}
