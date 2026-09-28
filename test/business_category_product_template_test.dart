import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/business_categories.g.dart';
import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/services/product_attribute_schema_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'her isletme kategorisinin urun sablonu shared semada tanimli',
    () async {
      final schema = await const ProductAttributeSchemaService().load();
      final tanimliAnahtarlar =
          schema.templates.map((item) => item.key).toSet();

      expect(businessCategories, isNotEmpty);
      for (final category in businessCategories) {
        expect(
          category.productTemplateKey.trim(),
          isNotEmpty,
          reason: '${category.id} icin productTemplateKey bos birakilmis',
        );
        expect(
          tanimliAnahtarlar,
          contains(category.productTemplateKey),
          reason:
              '${category.id} -> ${category.productTemplateKey} '
              'shared/product_attribute_schema.json icinde yok',
        );
      }
    },
  );

  test('magaza kategorisinden urun sablonu turetilir', () {
    expect(
      BusinessCategoryConfig.productTemplateKeyForCategory('Giyim'),
      'fashion',
    );
    expect(
      BusinessCategoryConfig.productTemplateKeyForCategory('Elektronik'),
      'electronics',
    );
    expect(
      BusinessCategoryConfig.productTemplateKeyForCategory('Kuaför'),
      'service',
    );
    expect(
      BusinessCategoryConfig.productTemplateKeyForCategory('Kafe / Lokanta'),
      'cafe_restaurant',
    );
  });

  test('pet shop urun satar, hizmet sablonuna dusurulmez', () {
    // Hizmet sablonuna gecis marka/barkod/stok alanlarini siliyor.
    // Pet shop fiziksel urun sattigi icin bu alanlari kaybetmemeli.
    expect(
      BusinessCategoryConfig.productTemplateKeyForCategory(
        'Pet Shop & Veteriner',
      ),
      isNot('service'),
    );
  });

  test('bos veya taninmayan kategoride onceki davranis korunur', () {
    expect(BusinessCategoryConfig.productTemplateKeyForCategory(''), 'generic');
    expect(
      BusinessCategoryConfig.productTemplateKeyForCategory('   '),
      'generic',
    );
    expect(
      BusinessCategoryConfig.productTemplateKeyForCategory('boyle-bir-sey-yok'),
      'generic',
    );
    expect(
      BusinessCategoryConfig.productTemplateKeyForCategory(null),
      'generic',
    );
  });
}
