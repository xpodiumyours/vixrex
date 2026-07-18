import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hesap silme tek Edge Function yolunu kullanir', () {
    final service = File('lib/services/auth_service.dart').readAsStringSync();
    final repository =
        File(
          'lib/repositories/supabase_auth_repository.dart',
        ).readAsStringSync();

    expect(
      service,
      contains("functions.invoke(\n        'delete-user-account'"),
    );
    expect(
      repository,
      contains("functions.invoke(\n      'delete-user-account'"),
    );
    expect(service, isNot(contains("rpc('delete_user_account')")));
    expect(repository, isNot(contains("rpc('delete_user_account')")));
  });

  test('Edge Function storage, domain ve auth silme sirasini korur', () {
    final function =
        File(
          'supabase/functions/delete-user-account/index.ts',
        ).readAsStringSync();

    expect(function, contains('userClient.auth.getUser()'));
    expect(function, contains('.remove(paths.slice('));
    expect(function, contains(".from('stores')\n      .delete()"));
    expect(function, contains('admin.auth.admin.deleteUser('));
    expect(function, isNot(contains("from('storage.objects')")));

    final storageDelete = function.indexOf('await removeStoragePrefix');
    final storeDelete = function.indexOf(".from('stores')\n      .delete()");
    final authDelete = function.indexOf('admin.auth.admin.deleteUser(');
    expect(storageDelete, greaterThanOrEqualTo(0));
    expect(storeDelete, greaterThan(storageDelete));
    expect(authDelete, greaterThan(storeDelete));
  });

  test('eski hesap silme RPC yolu ileri migration ile emekli edilir', () {
    final migration =
        File(
          'supabase/migrations/'
          '20260718211821_retire_legacy_delete_user_account_rpc.sql',
        ).readAsStringSync();

    expect(
      migration,
      contains('REVOKE EXECUTE ON FUNCTION public.delete_user_account()'),
    );
    expect(
      migration,
      contains('DROP FUNCTION IF EXISTS public.delete_user_account()'),
    );
  });
}
