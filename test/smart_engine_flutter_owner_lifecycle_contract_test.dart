import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test(
    'Companion handled smart-engine sonucu authoritative executor bekler',
    () {
      final source = _read('lib/widgets/vixrex/vixrex_companion_chat.dart');

      expect(
        source,
        contains(
          'final execution = await widget.onExecuteSmartEngine!(actions);',
        ),
      );
      expect(
        source,
        contains('bot = _executionMessage(execution, result.message);'),
      );
      expect(source, isNot(contains('widget.onUpdateField!(')));
      expect(source, isNot(contains("_appendBotAck('Kaydettim ✅')")));
    },
  );

  test('Flutter UX queued/partial/failed sonucu success gibi göstermez', () {
    final source = _read('lib/widgets/vixrex/vixrex_companion_chat.dart');

    expect(
      source,
      contains('Değişiklik sıraya alındı; henüz buluta kaydedilmedi.'),
    );
    expect(source, contains('FlutterSmartEngineCommandStatus.partialResult'));
    expect(source, contains('FlutterSmartEngineCommandStatus.failed'));
    expect(source, contains('case FlutterSmartEngineCommandStatus.succeeded:'));
  });

  test('owner executor context doğrulamadan mutation/projection yapmaz', () {
    final source = _read(
      'lib/services/working_draft/flutter_smart_engine_owner_executor.dart',
    );

    final contextIndex = source.indexOf('_contextService.resolve');
    final executeIndex = source.indexOf('_orchestrator.execute');
    final projectionIndex = source.indexOf(
      'for (final success in result.succeeded)',
    );

    expect(contextIndex, greaterThanOrEqualTo(0));
    expect(executeIndex, greaterThan(contextIndex));
    expect(projectionIndex, greaterThan(executeIndex));
    expect(source, contains('await controller.saveLocally();'));
    expect(source, contains('if (result.succeeded.isEmpty) return result;'));
    expect(source, isNot(contains('result.queuedOffline) {')));
  });

  test(
    'owner context latest-version bypass yerine 46 alan projection eşliği ister',
    () {
      final source = _read(
        'lib/services/working_draft/smart_engine_owner_context_service.dart',
      );

      expect(source, contains('for (final field in vitrinAlanlari)'));
      expect(source, contains("notReady('DRAFT_PROJECTION_STALE')"));
      expect(source, contains('state.draftVersion'));
      expect(source, contains('state.draftStale'));
    },
  );

  test(
    'VixrexScreen onboarding local akışını korur, published companion executor alır',
    () {
      final source = _read('lib/screens/vixrex_screen.dart');

      expect(source, contains('VixRexOnboardingChatScreen('));
      expect(source, contains('VixRexCompanionChat('));
      expect(source, contains('onExecuteSmartEngine: _executeSmartEngine'));
      expect(source, contains('onUndoSmartEngine: _undoSmartEngine'));
      expect(source, contains('_ownerExecutor.execute('));
      expect(source, contains('_ownerExecutor.undo('));
    },
  );

  test('Flutter command Undo yalnız server-backed commandId ile görünür', () {
    final source = _read('lib/widgets/vixrex/vixrex_companion_chat.dart');

    expect(source, contains("_smartEngineUndoPrefix = 'smart_engine_undo:'"));
    expect(source, contains('execution.commandId.isEmpty'));
    expect(source, contains('execution.succeeded.isEmpty'));
    expect(source, contains('execution.queuedOffline.isNotEmpty'));
    expect(source, contains("label: 'Geri al'"));
    expect(
      source,
      contains("payload: '\$_smartEngineUndoPrefix\${execution.commandId}'"),
    );
    expect(source, contains('await undo(commandId.trim())'));
  });

  test('queuedOffline command için Flutter Undo sunulmaz', () {
    final source = _read('lib/widgets/vixrex/vixrex_companion_chat.dart');

    final undoHelperStart = source.indexOf('List<QuickReply> _undoReplies');
    final executionMessageStart = source.indexOf(
      'ChatMessage _executionMessage',
      undoHelperStart,
    );
    expect(undoHelperStart, greaterThanOrEqualTo(0));
    expect(executionMessageStart, greaterThan(undoHelperStart));
    final undoHelper = source.substring(undoHelperStart, executionMessageStart);
    expect(undoHelper, contains('execution.queuedOffline.isNotEmpty'));
    expect(undoHelper, contains('return const [];'));
  });
}
