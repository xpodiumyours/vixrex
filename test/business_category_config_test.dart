import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/config/business_category_config.dart';

void main() {
  group('BusinessCategoryConfig & SuggestedOffering Tests', () {
    test('SuggestedOffering can hold durationMinutes and isBookable properties', () {
      const offering = SuggestedOffering(
        title: 'Örnek Hizmet',
        description: 'Örnek açıklama',
        price: '100 TL',
        durationMinutes: 45,
        isBookable: true,
      );

      expect(offering.title, 'Örnek Hizmet');
      expect(offering.description, 'Örnek açıklama');
      expect(offering.price, '100 TL');
      expect(offering.durationMinutes, 45);
      expect(offering.isBookable, true);
    });

    test('Kuaför category has correct rich suggested offerings with default booking options', () {
      final kuafor = BusinessCategoryConfig.categories.firstWhere((c) => c.id == 'kuafor');

      expect(kuafor.suggestedOfferings, isNotEmpty);
      expect(kuafor.suggestedOfferings.length, greaterThanOrEqualTo(5));

      final hairCut = kuafor.suggestedOfferings.firstWhere((o) => o.title == 'Saç Kesimi & Yıkama');
      expect(hairCut.durationMinutes, 45);
      expect(hairCut.isBookable, true);

      final skinCare = kuafor.suggestedOfferings.firstWhere((o) => o.title == 'Medikal Cilt Bakımı');
      expect(skinCare.durationMinutes, 60);
      expect(skinCare.isBookable, true);
    });

    test('Teknik Servis category has correct bookable suggested offerings', () {
      final service = BusinessCategoryConfig.categories.firstWhere((c) => c.id == 'teknik_servis');

      expect(service.suggestedOfferings, isNotEmpty);
      final screenRep = service.suggestedOfferings.firstWhere((o) => o.title == 'Telefon Ekran Değişimi');
      expect(screenRep.durationMinutes, 45);
      expect(screenRep.isBookable, true);
    });

    test('Giyim & Butik has suggestions that are not bookable by default', () {
      final clothing = BusinessCategoryConfig.categories.firstWhere((c) => c.id == 'giyim_butik');

      expect(clothing.suggestedOfferings, isNotEmpty);
      final dress = clothing.suggestedOfferings.firstWhere((o) => o.title == 'Yeni Sezon Elbiseler');
      expect(dress.isBookable, false);
    });

    test('fromCategoryLabel maps categories correctly', () {
      final categoryKuafor = BusinessCategoryConfig.fromCategoryLabel('Güzellik Salonu');
      expect(categoryKuafor.id, 'kuafor');

      final categoryRestoran = BusinessCategoryConfig.fromCategoryLabel('Restoran');
      expect(categoryRestoran.id, 'kafe_lokanta');
    });
  });
}
