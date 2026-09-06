import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/repositories/vixrex_conversation_repository.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_memory.dart';

class _FakeConversationRepository extends VixrexConversationRepository {
  _FakeConversationRepository({required this.syncEnabled, this.remote})
    : super();

  bool syncEnabled;
  Map<String, dynamic>? remote;

  /// Testler kurulum sonrası açıp yazma hatasını taklit edebilsin diye
  /// kurucu parametresi değil, doğrudan alan olarak duruyor.
  bool failWrites = false;
  int writeCount = 0;

  @override
  bool get canSync => syncEnabled;

  @override
  Future<Map<String, dynamic>?> loadPendingSlot() async => remote;

  @override
  Future<void> savePendingSlot(Map<String, dynamic>? slot) async {
    writeCount += 1;
    if (failWrites) throw StateError('OFFLINE');
    remote = slot == null ? null : Map<String, dynamic>.from(slot);
  }
}

VixrexPendingSlot _telefonSlot() => VixrexPendingSlot(
  anahtar: 'telefon',
  etiket: 'Telefon',
  tip: 'telefon',
  sorulduAt: DateTime.parse('2026-09-05T12:00:00.000Z'),
);

void main() {
  group('Vixrex pending envelope v1', () {
    test('v1 JSON legacy uyum alanlarını da taşır', () {
      final json = _telefonSlot().toJson();
      expect(json['schemaVersion'], 1);
      expect(json['domain'], 'storefront');
      expect(json['kind'], 'missing_value');
      expect(json['fieldKey'], 'telefon');
      expect(json['anahtar'], 'telefon');
      expect(json['tip'], 'telefon');
      expect(json['deneme'], 1);
    });

    test('eski pending kaydını v1 olarak normalize eder', () {
      final slot = VixrexPendingSlot.fromJson({
        'anahtar': 'adres',
        'etiket': 'Açık Adres',
        'tip': 'uzunMetin',
        'sorulduAt': '2026-09-05T12:00:00.000Z',
        'deneme': 2,
      });

      expect(slot.schemaVersion, 1);
      expect(slot.domain, 'storefront');
      expect(slot.kind, 'missing_value');
      expect(slot.anahtar, 'adres');
      expect(slot.tip, 'uzunMetin');
      expect(slot.deneme, 2);
    });

    test(
      'Supabase yokken SharedPrefs yalnız cache olarak devam eder',
      () async {
        SharedPreferences.setMockInitialValues({});
        const memory = VixrexConversationMemory();

        await memory.savePendingSlot(_telefonSlot(), scope: 'test-store');
        final loaded = await memory.loadPendingSlot(scope: 'test-store');
        expect(loaded?.anahtar, 'telefon');

        await memory.clearPendingSlot(scope: 'test-store');
        expect(await memory.loadPendingSlot(scope: 'test-store'), isNull);
      },
    );

    test('remote state kanoniktir ve local cache tazelenir', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeConversationRepository(
        syncEnabled: true,
        remote: _telefonSlot().toJson(),
      );
      final memory = VixrexConversationMemory(repository: repo);

      final remoteLoaded = await memory.loadPendingSlot(scope: 'store-a');
      expect(remoteLoaded?.anahtar, 'telefon');

      repo.syncEnabled = false;
      repo.remote = null;
      final cachedLoaded = await memory.loadPendingSlot(scope: 'store-a');
      expect(cachedLoaded?.anahtar, 'telefon');
    });

    test('offline set reconnect olduğunda remote önce güncellenir', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = _FakeConversationRepository(syncEnabled: false);
      final memory = VixrexConversationMemory(repository: repo);

      await memory.savePendingSlot(_telefonSlot(), scope: 'store-b');
      expect(repo.remote, isNull);

      repo.syncEnabled = true;
      final loaded = await memory.loadPendingSlot(scope: 'store-b');
      expect(loaded?.anahtar, 'telefon');
      expect(repo.remote?['fieldKey'], 'telefon');
      expect(repo.writeCount, 1);
    });

    test(
      'offline clear stale remote pending stateini geri diriltmez',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repo = _FakeConversationRepository(
          syncEnabled: false,
          remote: _telefonSlot().toJson(),
        );
        final memory = VixrexConversationMemory(repository: repo);

        await memory.savePendingSlot(_telefonSlot(), scope: 'store-c');
        await memory.clearPendingSlot(scope: 'store-c');

        repo.syncEnabled = true;
        final loaded = await memory.loadPendingSlot(scope: 'store-c');
        expect(loaded, isNull);
        expect(repo.remote, isNull);
        expect(repo.writeCount, 1);
      },
    );
  });
}
