import 'package:flutter/material.dart';

class TemplateCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const TemplateCategory(this.key, this.label, this.icon, this.color);
}

const List<TemplateCategory> templateCategories = [
  TemplateCategory(
    'giyim',
    'Giyim',
    Icons.checkroom_rounded,
    Color(0xFFFF5A1F),
  ),
  TemplateCategory(
    'butik',
    'Butik',
    Icons.shopping_bag_rounded,
    Color(0xFFCA8A04),
  ),
  TemplateCategory(
    'gida',
    'Gıda',
    Icons.shopping_basket_rounded,
    Color(0xFF059669),
  ),
  TemplateCategory(
    'kafe_lokanta',
    'Kafe / Lokanta',
    Icons.restaurant_menu_rounded,
    Color(0xFFEA580C),
  ),
  TemplateCategory(
    'kuafor',
    'Kuaför',
    Icons.content_cut_rounded,
    Color(0xFFDB2777),
  ),
  TemplateCategory(
    'teknik_servis',
    'Teknik Servis',
    Icons.build_circle_rounded,
    Color(0xFF4F46E5),
  ),
];
