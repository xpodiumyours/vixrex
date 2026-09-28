// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.
// Kaynak: shared/business_categories.json
// Üreten: tool/business_categories_uret.dart

class BusinessCategoryCore {
  final String id;
  final int order;
  final String label;
  final List<String> aliases;
  final String productTemplateKey;

  const BusinessCategoryCore({
    required this.id,
    required this.order,
    required this.label,
    required this.aliases,
    required this.productTemplateKey,
  });
}

const List<BusinessCategoryCore> businessCategories = [
  BusinessCategoryCore(
    id: 'giyim',
    order: 1,
    label: 'Giyim',
    aliases: ['giyim', 'Giyim & Butik'],
    productTemplateKey: 'fashion',
  ),
  BusinessCategoryCore(
    id: 'butik',
    order: 2,
    label: 'Butik',
    aliases: ['butik'],
    productTemplateKey: 'fashion',
  ),
  BusinessCategoryCore(
    id: 'gida',
    order: 3,
    label: 'Gıda',
    aliases: ['gida', 'Gıda & Fırın'],
    productTemplateKey: 'food',
  ),
  BusinessCategoryCore(
    id: 'firin',
    order: 4,
    label: 'Fırın',
    aliases: ['firin'],
    productTemplateKey: 'cafe_restaurant',
  ),
  BusinessCategoryCore(
    id: 'kozmetik',
    order: 5,
    label: 'Kozmetik',
    aliases: ['kozmetik'],
    productTemplateKey: 'beauty',
  ),
  BusinessCategoryCore(
    id: 'dekorasyon',
    order: 6,
    label: 'Dekorasyon',
    aliases: ['dekorasyon'],
    productTemplateKey: 'home',
  ),
  BusinessCategoryCore(
    id: 'elektronik',
    order: 7,
    label: 'Elektronik',
    aliases: ['elektronik'],
    productTemplateKey: 'electronics',
  ),
  BusinessCategoryCore(
    id: 'kirtasiye',
    order: 8,
    label: 'Kırtasiye',
    aliases: ['kirtasiye'],
    productTemplateKey: 'generic',
  ),
  BusinessCategoryCore(
    id: 'kafe_lokanta',
    order: 9,
    label: 'Kafe / Lokanta',
    aliases: ['kafe', 'restoran', 'lokanta'],
    productTemplateKey: 'cafe_restaurant',
  ),
  BusinessCategoryCore(
    id: 'kuafor',
    order: 10,
    label: 'Kuaför',
    aliases: ['kuafor', 'güzellik', 'guzellik'],
    productTemplateKey: 'service',
  ),
  BusinessCategoryCore(
    id: 'teknik_servis',
    order: 11,
    label: 'Teknik Servis',
    aliases: ['teknik', 'servis'],
    productTemplateKey: 'technical_service',
  ),
  BusinessCategoryCore(
    id: 'hizmet_danismanlik',
    order: 12,
    label: 'Danışmanlık',
    aliases: ['Hizmet & Danışmanlık', 'danismanlik', 'hizmet'],
    productTemplateKey: 'service',
  ),
  BusinessCategoryCore(
    id: 'egitim_ders',
    order: 13,
    label: 'Eğitim',
    aliases: ['Eğitim & Ders', 'egitim', 'ders'],
    productTemplateKey: 'service',
  ),
  BusinessCategoryCore(
    id: 'ev_temizlik',
    order: 14,
    label: 'Ev Temizlik',
    aliases: ['Ev & Temizlik', 'temizlik'],
    productTemplateKey: 'service',
  ),
  BusinessCategoryCore(
    id: 'spor_fitness',
    order: 15,
    label: 'Spor / Fitness',
    aliases: ['Spor & Fitness', 'spor', 'fitness'],
    productTemplateKey: 'service',
  ),
  BusinessCategoryCore(
    id: 'pet_shop_veteriner',
    order: 16,
    label: 'Pet / Veteriner',
    aliases: ['Pet Shop & Veteriner', 'pet', 'veteriner', 'evcil hayvan'],
    productTemplateKey: 'generic',
  ),
  BusinessCategoryCore(
    id: 'saglik_yasam',
    order: 17,
    label: 'Sağlık / Yaşam',
    aliases: ['Sağlık & Yaşam', 'saglik', 'yaşam'],
    productTemplateKey: 'service',
  ),
  BusinessCategoryCore(
    id: 'oto_arac',
    order: 18,
    label: 'Oto / Araç',
    aliases: ['Oto & Araç Hizmetleri', 'oto', 'araç', 'arac', 'araba'],
    productTemplateKey: 'automotive',
  ),
  BusinessCategoryCore(
    id: 'diger',
    order: 19,
    label: 'Diğer',
    aliases: ['diger'],
    productTemplateKey: 'generic',
  ),
];

final Map<String, BusinessCategoryCore> businessCategoryById = {
  for (final category in businessCategories) category.id: category,
};

String normalizeBusinessCategoryTerm(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ş', 's')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

final Map<String, String> _businessCategoryTerms = {
  for (final category in businessCategories)
    for (final term in [category.id, category.label, ...category.aliases])
      normalizeBusinessCategoryTerm(term): category.id,
};

String? resolveBusinessCategoryId(String value) {
  final normalized = normalizeBusinessCategoryTerm(value);
  if (normalized.isEmpty) return null;
  final exact = _businessCategoryTerms[normalized];
  if (exact != null) return exact;
  final partialTerms =
      _businessCategoryTerms.entries
          .where((entry) => normalized.contains(entry.key))
          .toList()
        ..sort((left, right) {
          final position = normalized
              .indexOf(left.key)
              .compareTo(normalized.indexOf(right.key));
          return position != 0
              ? position
              : right.key.length.compareTo(left.key.length);
        });
  for (final entry in partialTerms) {
    return entry.value;
  }
  return null;
}
