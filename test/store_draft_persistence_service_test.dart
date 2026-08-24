import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_draft_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  const storage = StoreLocalStorageService();
  const service = StoreDraftPersistenceService(storage: storage);

  test("ensureDraftEditToken aynı token'ı tekrar döndürür", () async {
    final ilk = await service.ensureDraftEditToken();
    final ikinci = await service.ensureDraftEditToken();
    expect(ilk, ikinci);
    expect(ilk, isNotEmpty);
  });

  test(
    'persist yayınlanmamış (publishedInfo null) veriyi hata vermeden kaydeder',
    () async {
      final data = StoreData(
        name: 'Test Vitrin',
        kategori: 'Diğer',
        status: 'Açık',
      );
      await service.persist(data, null);
      final yuklenen = await storage.loadVitrinData();
      expect(yuklenen?.name, 'Test Vitrin');
    },
  );

  test('persist publishedInfo doluysa onu da kaydeder', () async {
    final data = StoreData(
      name: 'Yayınlı Vitrin',
      kategori: 'Diğer',
      status: 'Açık',
    );
    final info = PublishedVitrinInfo(
      publicLink: 'https://vixrex-public.vercel.app/v/yayinli',
      slug: 'yayinli',
      name: 'Yayınlı Vitrin',
      editToken: 'edit-token-abcdefghij0123456789',
    );

    await service.persist(data, info);

    final yuklenenBilgi = await storage.loadPublishedVitrinInfo();
    expect(yuklenenBilgi?.slug, 'yayinli');
    expect(yuklenenBilgi?.editToken, 'edit-token-abcdefghij0123456789');
  });
}
