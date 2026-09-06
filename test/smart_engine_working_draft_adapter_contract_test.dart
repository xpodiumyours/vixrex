import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

String _between(String source, String start, String end) {
  final from = source.indexOf(start);
  final to = source.indexOf(end, from + start.length);
  expect(from, greaterThanOrEqualTo(0));
  expect(to, greaterThan(from));
  return source.substring(from, to);
}

void main() {
  test(
    'Supabase assistant adapter 5.5 authoritative RPC + permanent auth kullanır',
    () {
      final source = _read(
        'lib/services/working_draft/supabase_working_draft_adapter.dart',
      );
      final method = _between(
        source,
        'Future<Result<WorkingDraftAssistantPatchResult>> akilliMotorYamasiUygula',
        'Future<Result<WorkingDraftPublishResult>> yayinla',
      );

      expect(method, contains("c.auth.currentUser"));
      expect(method, contains('user.isAnonymous'));
      expect(method, contains("'vixrex_apply_storefront_action'"));
      expect(method, contains("'p_session_token'"));
      expect(method, contains("'p_field_key': anahtar"));
      expect(method, contains("'p_expected_draft_version': beklenenSurum"));
      expect(method, contains("'p_action_id': actionId"));
      expect(method, contains("'p_command_id': commandId"));
      expect(method, contains("m['replayed'] == true"));
      expect(method, isNot(contains("'update_working_draft_field'")));
    },
  );

  test(
    'assistant queue actionId/commandId/version kimliklerini kalıcı tutar',
    () {
      final source = _read(
        'lib/services/working_draft/local_queue_working_draft_adapter.dart',
      );

      expect(source, contains("'kind': _assistantKind"));
      expect(source, contains("'vs': beklenenSurum"));
      expect(source, contains("'aid': actionId"));
      expect(source, contains("'cmd': commandId"));
      expect(source, contains("m['aid'] == actionId"));
      expect(source, contains("actionId: m['aid'] as String"));
      expect(source, contains("commandId: m['cmd'] as String"));
      expect(
        source,
        contains('WorkingDraftAssistantPatchResult.queuedOffline'),
      );
      expect(source, isNot(contains('draftVersion: -1')));
    },
  );

  test('assistant queue aynı actionId için duplicate local item üretmez', () {
    final source = _read(
      'lib/services/working_draft/local_queue_working_draft_adapter.dart',
    );
    final queueMethod = _between(
      source,
      'Future<void> _assistantKuyrugaEkle',
      'Future<void> _legacyKuyruktanSil',
    );

    expect(queueMethod, contains('final alreadyQueued = list.any'));
    expect(queueMethod, contains("m['aid'] == actionId"));
    expect(queueMethod, contains('if (alreadyQueued) return;'));
  });
}
