import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/services/working_draft/smart_engine_working_draft_orchestrator.dart';
import 'package:vixrex/services/working_draft/working_draft_port.dart';
import 'package:vixrex/utils/failure.dart';

class _AssistantCall {
  const _AssistantCall({
    required this.fieldKey,
    required this.expectedVersion,
    required this.actionId,
    required this.commandId,
  });

  final String fieldKey;
  final int expectedVersion;
  final String actionId;
  final String commandId;
}

class _FakeWorkingDraftPort implements WorkingDraftPort {
  final calls = <_AssistantCall>[];
  final outcomes =
      <
        Result<WorkingDraftAssistantPatchResult> Function(
          String fieldKey,
          dynamic value,
          int expectedVersion,
          String actionId,
          String commandId,
        )
      >[];

  @override
  Future<Result<WorkingDraftAssistantPatchResult>> akilliMotorYamasiUygula({
    String? sessionToken,
    required String anahtar,
    required dynamic deger,
    required int beklenenSurum,
    required String actionId,
    required String commandId,
    String? clientId,
  }) async {
    calls.add(
      _AssistantCall(
        fieldKey: anahtar,
        expectedVersion: beklenenSurum,
        actionId: actionId,
        commandId: commandId,
      ),
    );
    final outcome = outcomes.removeAt(0);
    return outcome(anahtar, deger, beklenenSurum, actionId, commandId);
  }

  final undoCalls = <String>[];

  @override
  Future<Result<WorkingDraftAssistantUndoResult>> akilliMotorCommandGeriAl({
    String? sessionToken,
    required String commandId,
  }) async {
    undoCalls.add(commandId);
    return Result.success(
      WorkingDraftAssistantUndoResult(
        commandId: commandId,
        draftVersion: 1,
        rolledBackActionCount: 1,
        idempotentReplay: false,
      ),
    );
  }

  @override
  Stream<int> degisimSinyali({required String slug}) => const Stream.empty();

  @override
  Future<Result<WorkingDraftPublishResult>> yayinla({
    required String sessionToken,
  }) async => Result.success(const WorkingDraftPublishResult(liveVersion: 1));

  @override
  Future<Result<WorkingDraftSnapshot>> yukle({
    required String sessionToken,
  }) async => Result.success(
    const WorkingDraftSnapshot(
      slug: 'test',
      draftData: {},
      draftVersion: 1,
      baseLiveVersion: 1,
    ),
  );

  @override
  Future<Result<WorkingDraftPatchResult>> yamaUygula({
    required String sessionToken,
    required String anahtar,
    required dynamic deger,
    int? beklenenSurum,
    String? clientId,
  }) async =>
      Result.success(const WorkingDraftPatchResult.succeeded(draftVersion: 1));
}

Result<WorkingDraftAssistantPatchResult> _success(
  String fieldKey,
  dynamic value,
  int expectedVersion,
  String actionId,
  String commandId,
) => Result.success(
  WorkingDraftAssistantPatchResult.succeeded(
    actionId: actionId,
    commandId: commandId,
    fieldKey: fieldKey,
    normalizedValue: value,
    draftVersion: expectedVersion + 1,
  ),
);

void main() {
  test('iki action returned draftVersion ile 4→5→6 zinciri kurar', () async {
    final port = _FakeWorkingDraftPort()..outcomes.addAll([_success, _success]);
    final ids = <String>['cmd', 'a1', 'a2'].iterator;
    String nextId() {
      ids.moveNext();
      return ids.current;
    }

    final result = await FlutterSmartEngineWorkingDraftOrchestrator(
      port: port,
      idFactory: nextId,
    ).execute(
      initialDraftVersion: 4,
      actions: const [
        FlutterSmartEngineAction(fieldKey: 'isletmeAdi', value: 'Vixrex'),
        FlutterSmartEngineAction(fieldKey: 'whatsapp', value: '05551234567'),
      ],
    );

    expect(result.status, FlutterSmartEngineCommandStatus.succeeded);
    expect(result.commandId, 'cmd');
    expect(result.draftVersion, 6);
    expect(port.calls.map((c) => c.expectedVersion), [4, 5]);
    expect(port.calls.map((c) => c.actionId), ['a1', 'a2']);
    expect(port.calls.every((c) => c.commandId == 'cmd'), isTrue);
  });

  test(
    'field-level reject aynı version ile sonraki bağımsız actiona devam eder',
    () async {
      final port =
          _FakeWorkingDraftPort()
            ..outcomes.addAll([
              (_, __, ___, ____, _____) =>
                  Result.failure(Failure('INVALID_FIELD_VALUE')),
              _success,
            ]);
      final ids = <String>['cmd', 'a1', 'a2'].iterator;
      String nextId() {
        ids.moveNext();
        return ids.current;
      }

      final result = await FlutterSmartEngineWorkingDraftOrchestrator(
        port: port,
        idFactory: nextId,
      ).execute(
        initialDraftVersion: 8,
        actions: const [
          FlutterSmartEngineAction(fieldKey: 'website', value: 'hatalı'),
          FlutterSmartEngineAction(fieldKey: 'isletmeAdi', value: 'Vixrex'),
        ],
      );

      expect(result.status, FlutterSmartEngineCommandStatus.partialResult);
      expect(result.failed.single.errorCode, 'INVALID_FIELD_VALUE');
      expect(result.succeeded.single.fieldKey, 'isletmeAdi');
      expect(port.calls.map((c) => c.expectedVersion), [8, 8]);
      expect(result.draftVersion, 9);
    },
  );

  test('version conflict sonrası kalan action hiç gönderilmez', () async {
    final port =
        _FakeWorkingDraftPort()
          ..outcomes.addAll([
            _success,
            (_, __, ___, ____, _____) =>
                Result.failure(Failure('DRAFT_VERSION_CONFLICT')),
          ]);
    final ids = <String>['cmd', 'a1', 'a2'].iterator;
    String nextId() {
      ids.moveNext();
      return ids.current;
    }

    final result = await FlutterSmartEngineWorkingDraftOrchestrator(
      port: port,
      idFactory: nextId,
    ).execute(
      initialDraftVersion: 10,
      actions: const [
        FlutterSmartEngineAction(fieldKey: 'isletmeAdi', value: 'A'),
        FlutterSmartEngineAction(
          fieldKey: 'website',
          value: 'https://vixrex.com',
        ),
        FlutterSmartEngineAction(fieldKey: 'instagram', value: 'vixrex'),
      ],
    );

    expect(port.calls, hasLength(2));
    expect(result.succeeded, hasLength(1));
    expect(result.failed.single.errorCode, 'DRAFT_VERSION_CONFLICT');
    expect(result.stopped.single.fieldKey, 'instagram');
    expect(result.stopped.single.errorCode, 'DRAFT_VERSION_CONFLICT');
  });

  test('offline queue success değildir ve kalan action durur', () async {
    final port =
        _FakeWorkingDraftPort()
          ..outcomes.add(
            (fieldKey, value, _, actionId, commandId) => Result.success(
              WorkingDraftAssistantPatchResult.queuedOffline(
                actionId: actionId,
                commandId: commandId,
                fieldKey: fieldKey,
                normalizedValue: value,
              ),
            ),
          );
    final ids = <String>['cmd', 'a1'].iterator;
    String nextId() {
      ids.moveNext();
      return ids.current;
    }

    final result = await FlutterSmartEngineWorkingDraftOrchestrator(
      port: port,
      idFactory: nextId,
    ).execute(
      initialDraftVersion: 3,
      actions: const [
        FlutterSmartEngineAction(fieldKey: 'isletmeAdi', value: 'A'),
        FlutterSmartEngineAction(fieldKey: 'whatsapp', value: '05551234567'),
      ],
    );

    expect(result.status, FlutterSmartEngineCommandStatus.queuedOffline);
    expect(result.succeeded, isEmpty);
    expect(result.queuedOffline.single.actionId, 'a1');
    expect(result.stopped.single.fieldKey, 'whatsapp');
    expect(result.draftVersion, 3);
    expect(port.calls, hasLength(1));
  });

  test('retry için caller-provided commandId/actionId aynen korunur', () async {
    final port = _FakeWorkingDraftPort()..outcomes.add(_success);
    final result = await FlutterSmartEngineWorkingDraftOrchestrator(
      port: port,
      idFactory: () => 'unused',
    ).execute(
      initialDraftVersion: 12,
      commandId: 'cmd-existing',
      actions: const [
        FlutterSmartEngineAction(
          fieldKey: 'isletmeAdi',
          value: 'Vixrex',
          actionId: 'action-existing',
        ),
      ],
    );

    expect(result.commandId, 'cmd-existing');
    expect(result.succeeded.single.actionId, 'action-existing');
    expect(port.calls.single.commandId, 'cmd-existing');
    expect(port.calls.single.actionId, 'action-existing');
  });
}
