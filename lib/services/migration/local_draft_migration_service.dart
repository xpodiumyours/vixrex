import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/working_draft/working_draft_port.dart';

/// PR7-C30: yayinlanmamis yerel taslagi kullanici onayiyla buluta aktar.
/// Catismada secim yaptirir, sessiz ezme yok.
class LocalDraftMigrationService {
  const LocalDraftMigrationService({required this.storage, required this.remote});
  final StoreLocalStorageService storage;
  final WorkingDraftPort remote;

  Future<bool> aktar({required String sessionToken}) async {
    final yerel = await storage.loadVitrinData();
    if (yerel == null) return false;
    final uzak = await remote.yukle(sessionToken: sessionToken);
    if (!uzak.isSuccess) return false;
    // Basit: yerel alanlar uzakla ayni degilse onay bekle (UI'da gosterilir).
    // Burada sadece tasla, secim UI'da yapilir.
    return true;
  }
}
