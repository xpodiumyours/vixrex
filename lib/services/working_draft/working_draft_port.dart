import 'package:vixrex/core/result.dart';

/// Çalışma taslağının tek arayüzü — controller yalnız bunu bilir.
///
/// PR5-C19: iki gerçek adaptör (Supabase + yerel kuyruk) bu portun
/// arkasında durur. Yeni sorumluluk büyük controller'a eklenmez.
abstract class WorkingDraftPort {
  /// Taslağı yetkili kaynaktan yükler.
  Future<Result<WorkingDraftSnapshot>> yukle({required String sessionToken});

  /// Tek alanı sürüm kontrollü yazar. Bu mevcut/manual working-draft yoludur;
  /// Akıllı Motor action receipt/idempotency için [akilliMotorYamasiUygula]
  /// kullanır.
  Future<Result<WorkingDraftPatchResult>> yamaUygula({
    required String sessionToken,
    required String anahtar,
    required dynamic deger,
    int? beklenenSurum,
    String? clientId,
  });

  /// 5.8: Flutter owner-edit Akıllı Motor'un authoritative mutation sınırı.
  /// Yeni persistence portu açılmaz; aynı WorkingDraftPort 5.5 RPC contract'ını
  /// taşır. Flutter permanent auth yolunda [sessionToken] null'dır ve server
  /// `auth.uid()` sahipliğini doğrular.
  Future<Result<WorkingDraftAssistantPatchResult>> akilliMotorYamasiUygula({
    String? sessionToken,
    required String anahtar,
    required dynamic deger,
    required int beklenenSurum,
    required String actionId,
    required String commandId,
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

enum WorkingDraftPatchStatus { succeeded, queuedOffline }

class WorkingDraftPatchResult {
  const WorkingDraftPatchResult._({
    required this.status,
    required this.draftVersion,
  });

  const WorkingDraftPatchResult.succeeded({required int draftVersion})
    : this._(
        status: WorkingDraftPatchStatus.succeeded,
        draftVersion: draftVersion,
      );

  const WorkingDraftPatchResult.queuedOffline()
    : this._(
        status: WorkingDraftPatchStatus.queuedOffline,
        draftVersion: null,
      );

  final WorkingDraftPatchStatus status;

  /// Yalnız authoritative `succeeded` sonucunda vardır. Offline queue için
  /// uydurma `-1` sürümü kullanılmaz.
  final int? draftVersion;

  bool get succeeded => status == WorkingDraftPatchStatus.succeeded;
  bool get queuedOffline => status == WorkingDraftPatchStatus.queuedOffline;
}

/// Flutter Akıllı Motor action sonucu. `Result.failure` gerçek failure'ı
/// taşır; bu model yalnız server success veya güvenle kalıcı local queue'ya
/// alınmış pending action'ı temsil eder.
class WorkingDraftAssistantPatchResult {
  const WorkingDraftAssistantPatchResult._({
    required this.status,
    required this.actionId,
    required this.commandId,
    required this.fieldKey,
    required this.normalizedValue,
    required this.draftVersion,
    required this.idempotentReplay,
  });

  const WorkingDraftAssistantPatchResult.succeeded({
    required String actionId,
    required String commandId,
    required String fieldKey,
    required dynamic normalizedValue,
    required int draftVersion,
    bool idempotentReplay = false,
  }) : this._(
         status: WorkingDraftPatchStatus.succeeded,
         actionId: actionId,
         commandId: commandId,
         fieldKey: fieldKey,
         normalizedValue: normalizedValue,
         draftVersion: draftVersion,
         idempotentReplay: idempotentReplay,
       );

  const WorkingDraftAssistantPatchResult.queuedOffline({
    required String actionId,
    required String commandId,
    required String fieldKey,
    required dynamic normalizedValue,
  }) : this._(
         status: WorkingDraftPatchStatus.queuedOffline,
         actionId: actionId,
         commandId: commandId,
         fieldKey: fieldKey,
         normalizedValue: normalizedValue,
         draftVersion: null,
         idempotentReplay: false,
       );

  final WorkingDraftPatchStatus status;
  final String actionId;
  final String commandId;
  final String fieldKey;
  final dynamic normalizedValue;
  final int? draftVersion;
  final bool idempotentReplay;

  bool get succeeded => status == WorkingDraftPatchStatus.succeeded;
  bool get queuedOffline => status == WorkingDraftPatchStatus.queuedOffline;
}

class WorkingDraftPublishResult {
  const WorkingDraftPublishResult({required this.liveVersion});
  final int liveVersion;
}
