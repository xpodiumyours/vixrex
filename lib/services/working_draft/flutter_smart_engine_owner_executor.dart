import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/services/owner_bootstrap_service.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_executor.dart';
import 'package:vixrex/services/working_draft/local_queue_working_draft_adapter.dart';
import 'package:vixrex/services/working_draft/smart_engine_owner_context_service.dart';
import 'package:vixrex/services/working_draft/smart_engine_working_draft_orchestrator.dart';

class FlutterSmartEngineUndoExecutionResult {
  const FlutterSmartEngineUndoExecutionResult._({
    required this.succeeded,
    required this.commandId,
    required this.draftVersion,
    required this.rolledBackActionCount,
    required this.idempotentReplay,
    required this.localRefreshApplied,
    this.errorCode,
    this.errorMessage,
  });

  const FlutterSmartEngineUndoExecutionResult.succeeded({
    required String commandId,
    required int draftVersion,
    required int rolledBackActionCount,
    required bool idempotentReplay,
    required bool localRefreshApplied,
  }) : this._(
         succeeded: true,
         commandId: commandId,
         draftVersion: draftVersion,
         rolledBackActionCount: rolledBackActionCount,
         idempotentReplay: idempotentReplay,
         localRefreshApplied: localRefreshApplied,
       );

  const FlutterSmartEngineUndoExecutionResult.failed({
    required String commandId,
    required String errorCode,
    required String errorMessage,
  }) : this._(
         succeeded: false,
         commandId: commandId,
         draftVersion: null,
         rolledBackActionCount: 0,
         idempotentReplay: false,
         localRefreshApplied: false,
         errorCode: errorCode,
         errorMessage: errorMessage,
       );

  final bool succeeded;
  final String commandId;
  final int? draftVersion;
  final int rolledBackActionCount;
  final bool idempotentReplay;
  final bool localRefreshApplied;
  final String? errorCode;
  final String? errorMessage;
}

/// Yayın sonrası Flutter Vixrex Asistan owner-edit execution sınırı.
///
/// Mutation sırası:
/// canonical context/version → authoritative command → server success'leri
/// local projection/cache. Undo ise server receipt/current-value kontrolünden
/// geçer; başarıdan sonra canonical draft yerel görünüme best-effort yenilenir.
class FlutterSmartEngineOwnerExecutor {
  FlutterSmartEngineOwnerExecutor({
    SmartEngineOwnerContextService? contextService,
    FlutterSmartEngineWorkingDraftOrchestrator? orchestrator,
    VixrexExecutor? projectionExecutor,
    OwnerBootstrapService? bootstrapService,
  }) : _contextService =
           contextService ?? const SmartEngineOwnerContextService(),
       _orchestrator =
           orchestrator ??
           FlutterSmartEngineWorkingDraftOrchestrator(
             port: LocalQueueWorkingDraftAdapter(),
           ),
       _projectionExecutor = projectionExecutor ?? const VixrexExecutor(),
       _bootstrapService = bootstrapService ?? const OwnerBootstrapService();

  final SmartEngineOwnerContextService _contextService;
  final FlutterSmartEngineWorkingDraftOrchestrator _orchestrator;
  final VixrexExecutor _projectionExecutor;
  final OwnerBootstrapService _bootstrapService;

  Future<FlutterSmartEngineCommandResult> execute({
    required StoreEditorController controller,
    required List<FlutterSmartEngineAction> actions,
  }) async {
    if (actions.isEmpty) {
      return const FlutterSmartEngineCommandResult(
        status: FlutterSmartEngineCommandStatus.noOp,
        commandId: '',
        draftVersion: 0,
        succeeded: [],
        queuedOffline: [],
        failed: [],
        stopped: [],
      );
    }

    final contextResult = await _contextService.resolve(
      displayedData: controller.data,
    );
    if (contextResult.isFailure) {
      return FlutterSmartEngineCommandResult.blocked(
        draftVersion: 0,
        actions: actions,
        errorCode: 'OWNER_CONTEXT_UNAVAILABLE',
        errorMessage: contextResult.failure!.message,
      );
    }

    final ownerContext = contextResult.data!;
    final draftVersion = ownerContext.draftVersion ?? 0;
    if (!ownerContext.ready || draftVersion < 1) {
      return FlutterSmartEngineCommandResult.blocked(
        draftVersion: draftVersion,
        actions: actions,
        errorCode: ownerContext.reason,
        errorMessage: _contextMessage(ownerContext.reason),
      );
    }

    final result = await _orchestrator.execute(
      initialDraftVersion: draftVersion,
      actions: actions,
    );

    if (result.succeeded.isEmpty) return result;

    var projectedAny = false;
    for (final success in result.succeeded) {
      final alan = vixrexNiyetAlanByAnahtar[success.fieldKey];
      if (alan == null) continue;
      try {
        final projected = _projectionExecutor.execute(
          controller: controller,
          alan: alan,
          deger: success.value,
        );
        projectedAny = projectedAny || projected;
      } catch (_) {
        // Server success authoritative'dir; local projection hatası mutation'ı
        // geri almaz. Sonraki canonical bootstrap yeniden eşitler.
      }
    }

    if (projectedAny) {
      try {
        await controller.saveLocally();
      } catch (_) {
        // Local cache authoritative success değildir.
      }
    }

    return result;
  }

  Future<FlutterSmartEngineUndoExecutionResult> undo({
    required StoreEditorController controller,
    required String commandId,
  }) async {
    final normalizedCommandId = commandId.trim();
    if (normalizedCommandId.isEmpty) {
      return const FlutterSmartEngineUndoExecutionResult.failed(
        commandId: '',
        errorCode: 'INVALID_UNDO_PRECONDITION',
        errorMessage: 'Geri alma işlem bilgisi eksik.',
      );
    }

    final result = await _orchestrator.port.akilliMotorCommandGeriAl(
      commandId: normalizedCommandId,
    );
    if (result.isFailure) {
      final message = result.failure!.message;
      return FlutterSmartEngineUndoExecutionResult.failed(
        commandId: normalizedCommandId,
        errorCode: _undoFailureCode(message),
        errorMessage: message,
      );
    }

    final undo = result.data!;
    var localRefreshApplied = false;

    // Server Undo authoritative'dir. Sonrasında canonical working draft'ı
    // yerel storage/controller'a best-effort yenile. Local refresh hatası
    // server rollback'i başarısız saydırmaz.
    try {
      final stateResult = await _bootstrapService.getir();
      if (stateResult.isSuccess && stateResult.data!.hasStore) {
        final applied = await _bootstrapService.cihazaUygula(stateResult.data!);
        if (applied.veriYazildi) {
          await controller.initialize(null);
          localRefreshApplied = true;
        }
      }
    } catch (_) {
      localRefreshApplied = false;
    }

    return FlutterSmartEngineUndoExecutionResult.succeeded(
      commandId: undo.commandId,
      draftVersion: undo.draftVersion,
      rolledBackActionCount: undo.rolledBackActionCount,
      idempotentReplay: undo.idempotentReplay,
      localRefreshApplied: localRefreshApplied,
    );
  }

  String _undoFailureCode(String message) {
    final upper = message.toUpperCase();
    const known = <String>[
      'UNDO_CONFLICT',
      'UNDO_COMMAND_NOT_FOUND',
      'INVALID_UNDO_PRECONDITION',
      'OWNER_AUTHORIZATION_REQUIRED',
      'INVALID_SESSION_TOKEN',
      'SMART_ENGINE_DISABLED',
      'NO_CLIENT',
    ];
    for (final code in known) {
      if (upper.contains(code)) return code;
    }
    if (upper.contains('NETWORK') ||
        upper.contains('SOCKET') ||
        upper.contains('İNTERNET') ||
        upper.contains('INTERNET') ||
        upper.contains('BAĞLANTI')) {
      return 'NETWORK_ERROR';
    }
    return 'UNKNOWN_UNDO_ERROR';
  }

  String _contextMessage(String reason) {
    switch (reason) {
      case 'OWNER_AUTHORIZATION_REQUIRED':
        return 'Bu işlem için kalıcı hesabınla giriş yapmalısın.';
      case 'OWNER_EDIT_NOT_PUBLISHED':
        return 'Bu düzenleme yayın sonrası sahip modunda kullanılabilir.';
      case 'WORKING_DRAFT_NOT_READY':
        return 'Çalışma taslağı hazırlanamadı. Tekrar dene.';
      case 'WORKING_DRAFT_STALE':
      case 'DRAFT_PROJECTION_STALE':
        return 'Taslak başka bir yerde değişti. Güncel hâli yükleyip tekrar dene.';
      default:
        return 'Güvenli düzenleme bağlamı doğrulanamadı.';
    }
  }
}
