import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_executor.dart';
import 'package:vixrex/services/working_draft/local_queue_working_draft_adapter.dart';
import 'package:vixrex/services/working_draft/smart_engine_owner_context_service.dart';
import 'package:vixrex/services/working_draft/smart_engine_working_draft_orchestrator.dart';

/// Yayın sonrası Flutter Vixrex Asistan owner-edit yazma sınırı.
///
/// Sıra değiştirilemez:
/// 1. Ekranda görülen 46-alan projection'ı canonical working draft ile aynı mı?
/// 2. Gerçek draftVersion ile authoritative command çalıştır.
/// 3. Yalnız server `succeeded` sonuçlarını local controller'a yansıt.
/// 4. Local persistence yalnız cache/projection; server success'in kaynağı değil.
///
/// Onboarding bu sınıfı kullanmaz ve mevcut local setup akışı değişmez.
class FlutterSmartEngineOwnerExecutor {
  FlutterSmartEngineOwnerExecutor({
    SmartEngineOwnerContextService? contextService,
    FlutterSmartEngineWorkingDraftOrchestrator? orchestrator,
    VixrexExecutor? projectionExecutor,
  }) : _contextService =
           contextService ?? const SmartEngineOwnerContextService(),
       _orchestrator =
           orchestrator ??
           FlutterSmartEngineWorkingDraftOrchestrator(
             port: LocalQueueWorkingDraftAdapter(),
           ),
       _projectionExecutor = projectionExecutor ?? const VixrexExecutor();

  final SmartEngineOwnerContextService _contextService;
  final FlutterSmartEngineWorkingDraftOrchestrator _orchestrator;
  final VixrexExecutor _projectionExecutor;

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
        // Server success authoritative'dir. Local projection hatası server
        // mutation'ı geri almaz; sonraki canonical bootstrap tekrar düzeltir.
      }
    }

    if (projectedAny) {
      try {
        await controller.saveLocally();
      } catch (_) {
        // Local cache yazımı authoritative server success değildir.
      }
    }

    return result;
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
