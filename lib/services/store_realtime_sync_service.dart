import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_safe_select.dart';

/// `StoreEditorController`'ın canlı/taslak realtime dinleme mantığını
/// sahiplenir — iki ayrı Supabase kanalı:
///
///  - `vitrin_<slug>`: yayındaki `stores` satırı buluttan değişince haber
///    verir (ör. esnaf vitrinini tarayıcıdaki Vixrex Asistan ile de
///    düzenliyor). Yalnız YAYINLANMIŞ veri dinlenir.
///  - `draft:<slug>`: Vixrex Asistan taslakta alan güncellediğinde
///    BİLDİRİM verir — veri taşımaz, Flutter'ın yerel taslağını değiştirmez.
///
/// Bu servis kanal referanslarını KENDİSİ tutar (bağlantı yaşam döngüsü
/// bu yüzden stateful) ama controller-state'e (`_data`, `notifyListeners`)
/// hiç dokunmaz — yalnız callback'lerle haber verir; `_data`'yı ne zaman
/// güncelleyeceğine ve ne zaman `notifyListeners` çağıracağına controller
/// karar verir (`ProductCatalogSyncService`/`StoreLegalStampingService` ile
/// aynı desen).
///
/// 2026-08-13: `store_editor_controller.dart`'tan (Faz 3, controller
/// parçalama) birebir taşındı. Davranış kasıtlı olarak değiştirilmedi.
class StoreRealtimeSyncService {
  StoreRealtimeSyncService();

  RealtimeChannel? _canliKanal;
  RealtimeChannel? _taslakKanal;

  /// Yayındaki vitrini buluttan çeker; bulut daha yeniyse [StoreData] döner
  /// ve yerel kopyaya yazar. Yerel damga bulut kadar yeni/yeniyse `null`
  /// döner — hiçbir şey değişmedi demektir.
  ///
  /// Sessizce başarısız olur: internet yoksa ya da sorgu düşerse `null`
  /// döner, hata fırlatmaz. Çevrimdışı çalışabilmek manuel panelin varlık
  /// sebebi (VIXREX_RULES §1) — bu senkron onu bozamaz.
  Future<StoreData?> pullFromCloudIfNewer({
    required SupabaseClient client,
    required String slug,
    required StoreLocalStorageService storage,
  }) async {
    final temizSlug = slug.trim();
    if (temizSlug.isEmpty) return null;

    try {
      final row =
          await client
              .from('stores')
              .select('${StoreSafeSelect.columns},updated_at')
              .eq('slug', temizSlug)
              .maybeSingle();
      if (row == null) return null;

      final bulutZamani =
          DateTime.tryParse((row['updated_at'] as String?) ?? '')?.toUtc();
      if (bulutZamani == null) return null;

      final yerelZamani = await storage.loadVitrinDataSavedAt();

      // Yerel damga yoksa bulut kazanır: yerel veri eski bir sürümden
      // kalmış olabilir ve ne zaman yazıldığı bilinmiyor.
      if (yerelZamani != null && yerelZamani.isAfter(bulutZamani)) return null;

      final guncel = StoreData.fromJson(Map<String, dynamic>.from(row));
      await storage.saveVitrinData(guncel);
      return guncel;
    } catch (e) {
      if (kDebugMode) debugPrint('Bulut senkronu atlandı: $e');
      return null;
    }
  }

  /// Canlı + taslak dinlemeyi başlatır (varsa öncekini kapatıp yeniden
  /// kurar). [onCanliDegisti] her canlı satır değişikliğinde — pull
  /// denemesinden SONRA, sonuç `null` olsa bile — çağrılır (orijinal
  /// davranış: postgres olayı geldiğinde her zaman `notifyListeners`
  /// çağrılırdı, pull'un veri getirip getirmediğine bakılmaksızın).
  void baslat({
    required SupabaseClient client,
    required String slug,
    required StoreLocalStorageService storage,
    required void Function(StoreData? guncel) onCanliDegisti,
    required void Function(String etiket) onTaslakDegisti,
  }) {
    if (slug.trim().isEmpty) return;
    durdur(client);

    try {
      _canliKanal =
          client
              .channel('vitrin_$slug')
              .onPostgresChanges(
                event: PostgresChangeEvent.update,
                schema: 'public',
                table: 'stores',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'slug',
                  value: slug,
                ),
                callback: (_) async {
                  // Satır değişti; hangi alan olduğuna bakmadan taze
                  // hâlini al. pullFromCloudIfNewer içindeki zaman damgası
                  // karşılaştırması: uygulamada yapılıp henüz
                  // yayınlanmamış düzenleme ezilmez.
                  final guncel = await pullFromCloudIfNewer(
                    client: client,
                    slug: slug,
                    storage: storage,
                  );
                  onCanliDegisti(guncel);
                },
              )
              .subscribe();
    } catch (e) {
      // Canlı dinleme kurulmazsa uygulama çalışmaya devam eder; yalnız
      // açılıştaki senkronla yetinir. Çevrimdışı çalışabilmek esastır.
      if (kDebugMode) debugPrint('Canlı dinleme kurulamadı: $e');
    }

    try {
      _taslakKanal =
          client
              .channel('draft:$slug')
              .onBroadcast(
                event: 'alan_guncellendi',
                callback: (payload) {
                  // Payload: {kolon, anahtar, etiket, deger} — yalnız
                  // etiket kullanılır (Türkçe alan adı, örn. "İşletme
                  // Adı"). Veri Flutter'ın yerel kaydına yazılmaz; yalnız
                  // bildirim.
                  final etiket =
                      (payload['etiket'] as String?) ??
                      (payload['anahtar'] as String?) ??
                      '';
                  if (etiket.isNotEmpty) onTaslakDegisti(etiket);
                },
              )
              .subscribe();
    } catch (e) {
      // Taslak broadcast başarısız olursa yalnız bildirim gösterilmez;
      // editör ve senkron çalışmaya devam eder.
      if (kDebugMode) debugPrint('Taslak broadcast kurulamadı: $e');
    }
  }

  /// Her iki kanalı da kapatır. `client` null olsa bile güvenli.
  void durdur(SupabaseClient? client) {
    final canli = _canliKanal;
    if (canli != null) {
      _canliKanal = null;
      try {
        client?.removeChannel(canli);
      } catch (_) {}
    }
    final taslak = _taslakKanal;
    if (taslak != null) {
      _taslakKanal = null;
      try {
        client?.removeChannel(taslak);
      } catch (_) {}
    }
  }
}
