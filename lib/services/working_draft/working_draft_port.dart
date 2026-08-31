import 'package:vixrex/core/result.dart';

/// Çalışma taslağının tek arayüzü — controller yalnız bunu bilir.
///
/// PR5-C19: iki gerçek adaptör (Supabase + yerel kuyruk) bu portun
/// arkasında durur. Yeni sorumluluk büyük controller'a eklenmez.
abstract class WorkingDraftPort {
  /// Taslağı yetkili kaynaktan yükler.
  Future<Result<WorkingDraftSnapshot>> yukle({required String sessionToken});

  /// Tek alanı sürüm kontrollü yazar. `beklenenSurum` tutmazsa
  /// `Result.failure` + `DRAFT_STALE`.
  Future<Result<WorkingDraftPatchResult>> yamaUygula({
    required String sessionToken,
    required String anahtar,
    required dynamic deger,
    int? beklenenSurum,
    String? clientId,
  });

  /// Canonical taslağı canlıya alır.
  Future<Result<WorkingDraftPublishResult>> yayinla({
    required String sessionToken,
  });

  /// Değişim sinyali — payload taşımaz, yalnız yeni sürümü bildirir.
  Stream<int> degisimSinyali({required String slug});
}

class WorkingDraftSnapshot {
  const WorkingDraftSnapshot({
    required this.slug,
    required this.draftData,
    required this.draftVersion,
    required this.baseLiveVersion,
    this.atlananAlanlar = const [],
  });
  final String slug;
  final Map<String, dynamic> draftData;
  final int draftVersion;
  final int baseLiveVersion;
  final List<String> atlananAlanlar;
}

class WorkingDraftPatchResult {
  const WorkingDraftPatchResult({required this.draftVersion});
  final int draftVersion;
}

class WorkingDraftPublishResult {
  const WorkingDraftPublishResult({required this.liveVersion});
  final int liveVersion;
}
