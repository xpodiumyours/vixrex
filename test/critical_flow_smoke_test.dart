import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/controllers/explore_controller.dart';
import 'package:vixrex/models/in_app_notification.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/explore_repository.dart';
import 'package:vixrex/services/bulk_product_upload_service.dart';
import 'package:vixrex/services/notification_inbox_service.dart';
import 'package:vixrex/services/notification_preferences_service.dart';
import 'dart:convert';

class _FakeExploreRepo extends Fake implements ExploreRepository {
  _FakeExploreRepo(this.stores);
  final List<StoreData> stores;

  @override
  Future<List<StoreData>> fetchPublishedStores() async => stores;

  @override
  Future<List<String>> loadFavoriteStoreNames() async => [];

  @override
  Future<void> saveFavoriteStoreNames(List<String> names) async {}

  @override
  Future<String?> loadLastPublishedSlug() async => null;
}

/// Puzzle Complete — kritik akış parçalarının smoke doğrulaması.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Critical flow smoke', () {
    test('Keşfet ürün adına göre filtreler (etiket=davranış)', () async {
      final repo = _FakeExploreRepo([
        StoreData(
          name: 'Moda Evi',
          description: 'Giyim',
          kategori: 'Giyim',
          slug: 'moda-evi',
          products: [
            Product(id: '1', name: 'Kırmızı Elbise', price: '500'),
          ],
        ),
        StoreData(
          name: 'Lezzet',
          description: 'Yemek',
          kategori: 'Gıda',
          slug: 'lezzet',
          products: [
            Product(id: '2', name: 'Lahmacun', price: '100'),
          ],
        ),
      ]);
      final controller = ExploreController(repository: repo);
      await controller.initialize();
      controller.setSearchQuery('elbise');
      expect(controller.filteredStores.length, 1);
      expect(controller.filteredStores.first.slug, 'moda-evi');
    });

    test('Bulk CSV şablonu gerçek sütun üretir', () {
      final bytes = const BulkProductUploadService().generateTemplateCsv();
      final csv = utf8.decode(bytes);
      expect(csv, contains('Ürün Adı,Fiyat,Açıklama,Kategori,Stok Durumu'));
      expect(csv, contains('Örnek Ürün'));
    });

    test('Bildirim tercihi kaydedilir ve okunur', () async {
      const prefs = NotificationPreferencesService();
      await prefs.setBookingPushEnabled(false);
      expect(await prefs.isBookingPushEnabled(), isFalse);
      await prefs.setBookingPushEnabled(true);
      expect(await prefs.isBookingPushEnabled(), isTrue);
    });

    test('Bildirim inbox yazılır ve listelenir', () async {
      const inbox = NotificationInboxService();
      await inbox.add(
        InAppNotification(
          id: 'n1',
          title: 'Yeni randevu talebi',
          body: 'Ayşe randevu talebi gönderdi.',
          storeSlug: 'demo-store',
          createdAt: DateTime.now(),
        ),
      );
      final items = await inbox.list();
      expect(items, isNotEmpty);
      expect(items.first.storeSlug, 'demo-store');
      expect(items.first.title, contains('randevu'));
    });
  });
}
