import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;

  String read(String path) => File('$root/$path').readAsStringSync();

  test('edit token is never selected or used as a REST filter', () {
    final publishService = read('lib/services/store_publish_service.dart');
    final editorController = read(
      'lib/controllers/store_editor_controller.dart',
    );
    final authService = read('lib/services/auth_service.dart');
    final repository = read('lib/repositories/supabase_store_repository.dart');

    expect(publishService, isNot(contains(".eq('edit_token'")));
    expect(editorController, isNot(contains("select('slug, edit_token")));
    expect(authService, isNot(contains("select('edit_token')")));
    expect(repository, isNot(contains(".eq('edit_token'")));
  });

  test(
    'migration keeps guest credentials write-only and locks booking writes',
    () {
      final migration = read(
        'supabase/migrations/20260717_close_store_authorization_gap.sql',
      );

      expect(
        migration,
        contains(
          'REVOKE SELECT ON TABLE public.stores FROM anon, authenticated;',
        ),
      );
      expect(migration, contains("attname <> 'edit_token'"));
      expect(migration, contains('auth.uid() IS NOT NULL'));
      expect(
        migration,
        contains('DROP POLICY IF EXISTS "Anyone can upsert booking_settings"'),
      );
      expect(
        migration,
        contains('CREATE POLICY "Owners can update their store appointments"'),
      );
    },
  );
}
