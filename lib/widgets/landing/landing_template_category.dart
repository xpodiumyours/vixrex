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
    'butik_giyim',
    'Butik & Giyim',
    Icons.checkroom_rounded,
    Color(0xFFFF5A1F),
  ),
  TemplateCategory(
    'kuafor_guzellik',
    'Kuaför & Güzellik',
    Icons.content_cut_rounded,
    Color(0xFFDB2777),
  ),
  TemplateCategory(
    'kafe_restoran',
    'Kafe & Restoran',
    Icons.restaurant_menu_rounded,
    Color(0xFFEA580C),
  ),
  TemplateCategory('berber', 'Berber', Icons.face_rounded, Color(0xFF7C3AED)),
  TemplateCategory(
    'oto_kuafor',
    'Oto Kuaför',
    Icons.local_car_wash_rounded,
    Color(0xFF2563EB),
  ),
  TemplateCategory(
    'market_bakkal',
    'Market & Bakkal',
    Icons.shopping_basket_rounded,
    Color(0xFF059669),
  ),
  TemplateCategory(
    'pastane_tatlici',
    'Pastane & Tatlıcı',
    Icons.bakery_dining_rounded,
    Color(0xFFD946EF),
  ),
  TemplateCategory(
    'mobilya_dekorasyon',
    'Mobilya & Dekorasyon',
    Icons.chair_rounded,
    Color(0xFFCA8A04),
  ),
  TemplateCategory(
    'spor_salonu',
    'Spor Salonu',
    Icons.fitness_center_rounded,
    Color(0xFFDC2626),
  ),
  TemplateCategory(
    'dis_klinigi',
    'Diş Kliniği',
    Icons.medical_services_rounded,
    Color(0xFF0891B2),
  ),
  TemplateCategory(
    'eczane',
    'Eczane',
    Icons.local_pharmacy_rounded,
    Color(0xFF16A34A),
  ),
  TemplateCategory(
    'teknik_servis',
    'Teknik Servis',
    Icons.build_circle_rounded,
    Color(0xFF4F46E5),
  ),
];
