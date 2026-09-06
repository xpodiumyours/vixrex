import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/services/working_draft/local_queue_working_draft_adapter.dart';
import 'package:vixrex/services/working_draft/working_draft_port.dart';

void main() {
  group('WorkingDraftPatchResult status', () {
    test('authoritative succeeded gerçek draft version taşır', () {
      const result = WorkingDraftPatchResult.succeeded(draftVersion: 12);

      expect(result.status, WorkingDraftPatchStatus.succeeded);
      expect(result.succeeded, true);
      expect(result.queuedOffline, false);
      expect(result.draftVersion, 12);
    });

    test('offline queue sahte draft version üretmez', () async {
      SharedPreferences.setMockInitialValues({});
      final adapter = LocalQueueWorkingDraftAdapter();

      final result = await adapter.yamaUygula(
        sessionToken: 'test-session',
        anahtar: 'phone',
        deger: '02121234567',
        beklenenSurum: 7,
        clientId: 'test-client',
      );

      expect(result.isSuccess, true);
      expect(result.data?.status, WorkingDraftPatchStatus.queuedOffline);
      expect(result.data?.queuedOffline, true);
      expect(result.data?.succeeded, false);
      expect(result.data?.draftVersion, isNull);
    });
  });
}
