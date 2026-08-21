// ÜRETİLMİŞ DOSYA — ELLE DÜZENLEME.
// Kaynak: shared/business_categories.json
// Üreten: tool/business_categories_uret.dart

class BusinessCategoryCore {
  final String id;
  final int order;
  final String label;
  final List<String> aliases;

  const BusinessCategoryCore({
    required this.id,
    required this.order,
    required this.label,
    required this.aliases,
  });
}

const List<BusinessCategoryCore> businessCategories = [
  BusinessCategoryCore(
    id: 'giyim',
    order: 1,
    label: 'Giyim',
    aliases: ['giyim', 'Giyim & Butik'],
  ),
  BusinessCategoryCore(
    id: 'butik',
    order: 2,
    label: 'Butik',
    aliases: ['butik'],
  ),
  BusinessCategoryCore(
    id: 'gida',
    order: 3,
    label: 'Gıda',
    aliases: ['gida', 'Gıda & Fırın'],
  ),
  BusinessCategoryCore(
    id: 'firin',
    order: 4,
    label: 'Fırın',
    aliases: ['firin'],
  ),
  BusinessCategoryCore(
    id: 'kozmetik',
    order: 5,
    label: 'Kozmetik',
    aliases: ['kozmetik'],
  ),
  BusinessCategoryCore(
    id: 'dekorasyon',
    order: 6,
    label: 'Dekorasyon',
    aliases: ['dekorasyon'],
  ),
  BusinessCategoryCore(
    id: 'elektronik',
    order: 7,
    label: 'Elektronik',
    aliases: ['elektronik'],
  ),
  BusinessCategoryCore(
    id: 'kirtasiye',
    order: 8,
    label: 'Kırtasiye',
    aliases: ['kirtasiye'],
  ),
  BusinessCategoryCore(
    id: 'kafe_lokanta',
    order: 9,
    label: 'Kafe / Lokanta',
    aliases: ['kafe', 'restoran', 'lokanta'],
  ),
  BusinessCategoryCore(
    id: 'kuafor',
    order: 10,
    label: 'Kuaför',
    aliases: ['kuafor', 'güzellik', 'guzellik'],
  ),
  BusinessCategoryCore(
    id: 'teknik_servis',
    order: 11,
    label: 'Teknik Servis',
    aliases: ['teknik', 'servis'],
  ),
  BusinessCategoryCore(
    id: 'hizmet_danismanlik',
    order: 12,
    label: 'Danışmanlık',
    aliases: ['Hizmet & Danışmanlık', 'danismanlik', 'hizmet'],
  ),
  BusinessCategoryCore(
    id: 'egitim_ders',
    order: 13,
    label: 'Eğitim',
    aliases: ['Eğitim & Ders', 'egitim', 'ders'],
  ),
  BusinessCategoryCore(
    id: 'ev_temizlik',
    order: 14,
    label: 'Ev Temizlik',
    aliases: ['Ev & Temizlik', 'temizlik'],
  ),
  BusinessCategoryCore(
    id: 'spor_fitness',
    order: 15,
    label: 'Spor / Fitness',
    aliases: ['Spor & Fitness', 'spor', 'fitness'],
  ),
  BusinessCategoryCore(
    id: 'pet_shop_veteriner',
    order: 16,
    label: 'Pet / Veteriner',
    aliases: ['Pet Shop & Veteriner', 'pet', 'veteriner', 'evcil hayvan'],
  ),
  BusinessCategoryCore(
    id: 'saglik_yasam',
    order: 17,
    label: 'Sağlık / Yaşam',
    aliases: ['Sağlık & Yaşam', 'saglik', 'yaşam'],
  ),
  BusinessCategoryCore(
    id: 'oto_arac',
    order: 18,
    label: 'Oto / Araç',
    aliases: ['Oto & Araç Hizmetleri', 'oto', 'araç', 'arac', 'araba'],
  ),
  BusinessCategoryCore(
    id: 'diger',
    order: 19,
    label: 'Diğer',
    aliases: ['diger'],
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
