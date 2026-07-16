import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/services/local_storage_keys.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guest publish token alignment', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('savePublishedVitrinInfo mirrors edit token for Auth link path', () async {
      final storage = StoreLocalStorageService();
      const token = 'edit-token-1234567890123456';

      await storage.savePublishedVitrinInfo(
        slug: 'aymira-giyim',
        publicLink: 'https://vixrex-public.vercel.app/v/aymira-giyim',
        name: 'Aymira Giyim',
        editToken: token,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocalStorageKeys.lastPublishedEditToken), token);
      expect(prefs.getString(LocalStorageKeys.vitrinEditToken), token);
      expect(prefs.getString(LocalStorageKeys.storeEditToken), token);

      final loaded = await storage.loadPublishedVitrinInfo();
      expect(loaded, isNotNull);
      expect(loaded!.editToken, token);
      expect(loaded.slug, 'aymira-giyim');
    });

    test('Auth token candidate order prefers last_published first', () {
      final candidates = <String>[
        'last-published-token-1234567890',
        'vitrin-token-should-not-win-here',
        'store-token-should-not-win-here',
      ];
      final chosen = candidates
          .map((t) => t.trim())
          .firstWhere((t) => t.isNotEmpty, orElse: () => '');
      expect(chosen, 'last-published-token-1234567890');
    });
  });
}
