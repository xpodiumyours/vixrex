import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/business_categories.g.dart';
import 'package:vixrex/config/business_category_config.dart';

void main() {
  test('ortak kategori core 19 benzersiz ID ve sabit sıra taşır', () {
    expect(businessCategories, hasLength(19));
    expect(
      businessCategories.map((category) => category.id).toSet(),
      hasLength(19),
    );
    expect(
      businessCategories.map((category) => category.order),
      orderedEquals(List<int>.generate(19, (index) => index + 1)),
    );
  });

  test('yedi eski Flutter etiketi canonical ID değerlerine çözülür', () {
    const legacyLabels = {
      'Hizmet & Danışmanlık': 'hizmet_danismanlik',
      'Eğitim & Ders': 'egitim_ders',
      'Ev & Temizlik': 'ev_temizlik',
      'Spor & Fitness': 'spor_fitness',
      'Pet Shop & Veteriner': 'pet_shop_veteriner',
      'Sağlık & Yaşam': 'saglik_yasam',
      'Oto & Araç Hizmetleri': 'oto_arac',
    };

    for (final entry in legacyLabels.entries) {
      expect(resolveBusinessCategoryId(entry.key), entry.value);
    }
  });

  test('eski arama aliasları ve en özgül kısmi eşleşme korunur', () {
    expect(resolveBusinessCategoryId('telefon servis'), 'teknik_servis');
    expect(resolveBusinessCategoryId('pet hizmetleri'), 'pet_shop_veteriner');
  });

  test('Flutter adapter ortak core kimliklerini eksiksiz kapsar', () {
    expect(
      BusinessCategoryConfig.categories.map((category) => category.id),
      orderedEquals(businessCategories.map((category) => category.id)),
    );
    expect(
      BusinessCategoryConfig.categories.map((category) => category.label),
      orderedEquals(businessCategories.map((category) => category.label)),
    );
  });
}
