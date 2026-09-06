import 'package:vixrex/core/result.dart';

/// Çalışma taslağının tek arayüzü — controller yalnız bunu bilir.
abstract class WorkingDraftPort {
  Future<Result<WorkingDraftSnapshot>> yukle({required String sessionToken});

  /// Mevcut/manual working-draft yolu.
  Future<Result<WorkingDraftPatchResult>> yamaUygula({
    required String sessionToken,
    required String anahtar,
    required dynamic deger,
    int? beklenenSurum,
    String? clientId,
  });

  /// Flutter owner-edit Akıllı Motor authoritative mutation sınırı.
  Future<Result<WorkingDraftAssistantPatchResult>> akilliMotorYamasiUygula({
    String? sessionToken,
    required String anahtar,
    required dynamic deger,
    required int beklenenSurum,
    required String actionId,
    required String commandId,
    String? clientId,
  });

  /// 5.6/5.8 command-level authoritative Undo. Offline'da local rollback
  /// yapılmaz ve Undo queue'lanmaz; başarı yalnız server receipt sonucudur.
  Future<Result<WorkingDraftAssistantUndoResult>> akilliMotorCommandGeriAl({
    String? sessionToken,
    required String commandId,
  });

  Future<Result<WorkingDraftPublishResult>> yayinla({
    required String sessionToken,
  });

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
  final int? draftVersion;

  bool get succeeded => status == WorkingDraftPatchStatus.succeeded;
  bool get queuedOffline => status == WorkingDraftPatchStatus.queuedOffline;
}

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

class WorkingDraftAssistantUndoResult {
  const WorkingDraftAssistantUndoResult({
    required this.commandId,
    required this.draftVersion,
    required this.rolledBackActionCount,
    required this.idempotentReplay,
  });

  final String commandId;
  final int draftVersion;
  final int rolledBackActionCount;
  final bool idempotentReplay;
}

class WorkingDraftPublishResult {
  const WorkingDraftPublishResult({required this.liveVersion});
  final int liveVersion;
}
