import 'package:uuid/uuid.dart';
import 'package:vixrex/services/working_draft/working_draft_port.dart';
import 'package:vixrex/utils/failure.dart';

typedef SmartEngineIdFactory = String Function();

enum FlutterSmartEngineCommandStatus {
  noOp,
  succeeded,
  queuedOffline,
  failed,
  partialResult,
}

enum FlutterSmartEngineActionStatus {
  succeeded,
  queuedOffline,
  failed,
  stopped,
}

class FlutterSmartEngineAction {
  const FlutterSmartEngineAction({
    required this.fieldKey,
    required this.value,
    this.actionId,
  });

  final String fieldKey;
  final dynamic value;

  /// Retry sırasında aynı logical action kimliğinin korunmasına izin verir.
  /// Null ise orchestrator yalnız ilk denemede yeni UUID üretir.
  final String? actionId;
}

class FlutterSmartEngineActionResult {
  const FlutterSmartEngineActionResult({
    required this.status,
    required this.fieldKey,
    required this.value,
    required this.actionId,
    this.draftVersion,
    this.errorCode,
    this.errorMessage,
    this.idempotentReplay = false,
  });

  final FlutterSmartEngineActionStatus status;
  final String fieldKey;
  final dynamic value;
  final String actionId;
  final int? draftVersion;
  final String? errorCode;
  final String? errorMessage;
  final bool idempotentReplay;
}

class FlutterSmartEngineCommandResult {
  const FlutterSmartEngineCommandResult({
    required this.status,
    required this.commandId,
    required this.draftVersion,
    required this.succeeded,
    required this.queuedOffline,
    required this.failed,
    required this.stopped,
  });

  factory FlutterSmartEngineCommandResult.blocked({
    required int draftVersion,
    required List<FlutterSmartEngineAction> actions,
    required String errorCode,
    required String errorMessage,
  }) {
    if (actions.isEmpty) {
      return FlutterSmartEngineCommandResult(
        status: FlutterSmartEngineCommandStatus.failed,
        commandId: '',
        draftVersion: draftVersion,
        succeeded: const [],
        queuedOffline: const [],
        failed: const [],
        stopped: const [],
      );
    }

    final first = actions.first;
    return FlutterSmartEngineCommandResult(
      status: FlutterSmartEngineCommandStatus.failed,
      commandId: '',
      draftVersion: draftVersion,
      succeeded: const [],
      queuedOffline: const [],
      failed: [
        FlutterSmartEngineActionResult(
          status: FlutterSmartEngineActionStatus.failed,
          fieldKey: first.fieldKey,
          value: first.value,
          actionId: first.actionId ?? '',
          errorCode: errorCode,
          errorMessage: errorMessage,
        ),
      ],
      stopped: [
        for (final action in actions.skip(1))
          FlutterSmartEngineActionResult(
            status: FlutterSmartEngineActionStatus.stopped,
            fieldKey: action.fieldKey,
            value: action.value,
            actionId: action.actionId ?? '',
            errorCode: errorCode,
          ),
      ],
    );
  }

  final FlutterSmartEngineCommandStatus status;
  final String commandId;
  final int draftVersion;
  final List<FlutterSmartEngineActionResult> succeeded;
  final List<FlutterSmartEngineActionResult> queuedOffline;
  final List<FlutterSmartEngineActionResult> failed;
  final List<FlutterSmartEngineActionResult> stopped;

  String? get firstErrorCode =>
      failed.isNotEmpty ? failed.first.errorCode : queuedOffline.firstOrNull?.errorCode;

  String? get firstErrorMessage => failed.isNotEmpty ? failed.first.errorMessage : null;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// 5.8 Flutter owner-edit Akıllı Motor command orchestrator.
///
/// - intent çözmez,
/// - controller'a yazmaz,
/// - success uydurmaz,
/// - her action'ı mevcut [WorkingDraftPort] üzerinden 5.5 authoritative RPC'ye
///   taşır,
/// - bir önceki server success'in draftVersion değerini sonraki action'ın
///   expectedVersion değeri yapar,
/// - version/auth/idempotency/network zemini belirsizleşirse kalan action'ları
///   hiç göndermez.
class FlutterSmartEngineWorkingDraftOrchestrator {
  FlutterSmartEngineWorkingDraftOrchestrator({
    required this.port,
    SmartEngineIdFactory? idFactory,
  }) : _idFactory = idFactory ?? _defaultId;

  final WorkingDraftPort port;
  final SmartEngineIdFactory _idFactory;

  static String _defaultId() => const Uuid().v4();

  static const _globalStopCodes = <String>{
    'DRAFT_VERSION_CONFLICT',
    'IDEMPOTENCY_KEY_REUSE',
    'INVALID_SESSION_TOKEN',
    'OWNER_AUTHORIZATION_REQUIRED',
    'SMART_ENGINE_DISABLED',
    'RATE_LIMITED',
    'RATE_LIMIT_SERVICE_ERROR',
    'SERVICE_UNAVAILABLE',
    'UNKNOWN_MUTATION_ERROR',
    'UNKNOWN_MUTATION_OUTCOME',
    'NETWORK_ERROR',
    'NO_CLIENT',
  };

  Future<FlutterSmartEngineCommandResult> execute({
    required int initialDraftVersion,
    required List<FlutterSmartEngineAction> actions,
    String? commandId,
    String? sessionToken,
    String? clientId,
  }) async {
    final resolvedCommandId = commandId ?? _idFactory();
    var draftVersion = initialDraftVersion;
    final succeeded = <FlutterSmartEngineActionResult>[];
    final queued = <FlutterSmartEngineActionResult>[];
    final failed = <FlutterSmartEngineActionResult>[];
    final stopped = <FlutterSmartEngineActionResult>[];

    if (actions.isEmpty) {
      return FlutterSmartEngineCommandResult(
        status: FlutterSmartEngineCommandStatus.noOp,
        commandId: resolvedCommandId,
        draftVersion: draftVersion,
        succeeded: succeeded,
        queuedOffline: queued,
        failed: failed,
        stopped: stopped,
      );
    }

    for (var index = 0; index < actions.length; index += 1) {
      final action = actions[index];
      final actionId = action.actionId ?? _idFactory();
      final result = await port.akilliMotorYamasiUygula(
        sessionToken: sessionToken,
        anahtar: action.fieldKey,
        deger: action.value,
        beklenenSurum: draftVersion,
        actionId: actionId,
        commandId: resolvedCommandId,
        clientId: clientId,
      );

      if (result.isFailure) {
        final failure = result.failure!;
        final errorCode = _failureCode(failure);
        failed.add(
          FlutterSmartEngineActionResult(
            status: FlutterSmartEngineActionStatus.failed,
            fieldKey: action.fieldKey,
            value: action.value,
            actionId: actionId,
            errorCode: errorCode,
            errorMessage: failure.message,
          ),
        );

        if (_globalStopCodes.contains(errorCode)) {
          _stopRemaining(
            actions: actions,
            fromIndex: index + 1,
            errorCode: errorCode,
            target: stopped,
          );
          break;
        }
        continue;
      }

      final patch = result.data!;
      if (patch.queuedOffline) {
        queued.add(
          FlutterSmartEngineActionResult(
            status: FlutterSmartEngineActionStatus.queuedOffline,
            fieldKey: patch.fieldKey,
            value: patch.normalizedValue,
            actionId: patch.actionId,
            errorCode: 'QUEUED_OFFLINE',
          ),
        );
        _stopRemaining(
          actions: actions,
          fromIndex: index + 1,
          errorCode: 'QUEUED_OFFLINE',
          target: stopped,
        );
        break;
      }

      final nextVersion = patch.draftVersion;
      if (!patch.succeeded || nextVersion == null || nextVersion < 1) {
        failed.add(
          FlutterSmartEngineActionResult(
            status: FlutterSmartEngineActionStatus.failed,
            fieldKey: action.fieldKey,
            value: action.value,
            actionId: actionId,
            errorCode: 'UNKNOWN_MUTATION_OUTCOME',
            errorMessage: 'Kaydetme sonucu doğrulanamadı.',
          ),
        );
        _stopRemaining(
          actions: actions,
          fromIndex: index + 1,
          errorCode: 'UNKNOWN_MUTATION_OUTCOME',
          target: stopped,
        );
        break;
      }

      draftVersion = nextVersion;
      succeeded.add(
        FlutterSmartEngineActionResult(
          status: FlutterSmartEngineActionStatus.succeeded,
          fieldKey: patch.fieldKey,
          value: patch.normalizedValue,
          actionId: patch.actionId,
          draftVersion: nextVersion,
          idempotentReplay: patch.idempotentReplay,
        ),
      );
    }

    return FlutterSmartEngineCommandResult(
      status: _commandStatus(
        total: actions.length,
        succeeded: succeeded.length,
        queued: queued.length,
        failed: failed.length,
        stopped: stopped.length,
      ),
      commandId: resolvedCommandId,
      draftVersion: draftVersion,
      succeeded: succeeded,
      queuedOffline: queued,
      failed: failed,
      stopped: stopped,
    );
  }

  void _stopRemaining({
    required List<FlutterSmartEngineAction> actions,
    required int fromIndex,
    required String errorCode,
    required List<FlutterSmartEngineActionResult> target,
  }) {
    for (var i = fromIndex; i < actions.length; i += 1) {
      final action = actions[i];
      target.add(
        FlutterSmartEngineActionResult(
          status: FlutterSmartEngineActionStatus.stopped,
          fieldKey: action.fieldKey,
          value: action.value,
          actionId: action.actionId ?? '',
          errorCode: errorCode,
        ),
      );
    }
  }

  FlutterSmartEngineCommandStatus _commandStatus({
    required int total,
    required int succeeded,
    required int queued,
    required int failed,
    required int stopped,
  }) {
    if (total == 0) return FlutterSmartEngineCommandStatus.noOp;
    if (succeeded == total) return FlutterSmartEngineCommandStatus.succeeded;
    if (queued > 0 && succeeded == 0 && failed == 0) {
      return FlutterSmartEngineCommandStatus.queuedOffline;
    }
    if (succeeded == 0 && queued == 0 && failed > 0 && failed + stopped == total) {
      return FlutterSmartEngineCommandStatus.failed;
    }
    return FlutterSmartEngineCommandStatus.partialResult;
  }

  String _failureCode(Failure failure) {
    final upper = failure.message.toUpperCase();
    for (final code in _globalStopCodes) {
      if (upper.contains(code)) return code;
    }
    if (upper.contains('İNTERNET') ||
        upper.contains('INTERNET') ||
        upper.contains('NETWORK') ||
        upper.contains('SOCKET') ||
        upper.contains('BAĞLANTI')) {
      return 'NETWORK_ERROR';
    }
    if (upper.contains('INVALID_FIELD_VALUE')) return 'INVALID_FIELD_VALUE';
    if (upper.contains('FIELD_NOT_EDITABLE')) return 'FIELD_NOT_EDITABLE';
    return 'FIELD_ERROR';
  }
}
