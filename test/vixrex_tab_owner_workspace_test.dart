import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/services/owner_preview_service.dart';
import 'package:vixrex/services/store_publish_service.dart';

void main() {
  test('existing store opens verified owner editor', () async {
    final calls = <String>[];
    final client = SupabaseClient(
      'https://dummyproject.supabase.co',
      'dummyAnonKey',
      httpClient: MockClient((request) async {
        calls.add(request.url.path);
        if (request.url.path.endsWith('/rpc/get_or_create_working_draft')) {
          expect(jsonDecode(request.body)['p_slug'], 'existing-store');
          return http.Response(
            jsonEncode({'slug': 'existing-store', 'version_conflict': false}),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path.endsWith('/rpc/create_owner_session')) {
          expect(jsonDecode(request.body)['p_edit_token'], 'verified-token');
          return http.Response(
            jsonEncode({'code': 'one-time-code'}),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        fail('Unexpected owner session request: ${request.url.path}');
      }),
    );
    addTearDown(client.dispose);
    final service = OwnerPreviewService(
      clientProvider: () => client,
      draftEditTokenProvider: () async => fail('New store token requested'),
      publishService: const StorePublishService(),
    );

    final result = await service.openExistingStore(
      slug: ' existing-store ',
      editToken: ' verified-token ',
    );

    expect(result.slug, 'existing-store');
    expect(result.versionConflict, false);
    expect(result.url, contains('/api/owner-session?'));
    expect(result.url, contains('slug=existing-store'));
    expect(result.url, contains('ocode=one-time-code'));
    expect(result.url, isNot(contains('verified-token')));
    expect(calls, [
      '/rest/v1/rpc/get_or_create_working_draft',
      '/rest/v1/rpc/create_owner_session',
    ]);
  });

  test('store mismatch cannot produce a session code', () async {
    final calls = <String>[];
    final client = SupabaseClient(
      'https://dummyproject.supabase.co',
      'dummyAnonKey',
      httpClient: MockClient((request) async {
        calls.add(request.url.path);
        return http.Response(
          jsonEncode({'slug': 'different-store', 'version_conflict': false}),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final service = OwnerPreviewService(
      clientProvider: () => client,
      draftEditTokenProvider: () async => fail('New store token requested'),
      publishService: const StorePublishService(),
    );

    await expectLater(
      service.openExistingStore(slug: 'my-store', editToken: 'my-token'),
      throwsA(isA<Exception>()),
    );
    expect(calls, ['/rest/v1/rpc/get_or_create_working_draft']);
  });

  test('Vixrex tab resolves account ownership on both layouts', () {
    final home = File('lib/screens/home_shell_screen.dart').readAsStringSync();
    final controller =
        File('lib/controllers/store_editor_controller.dart').readAsStringSync();
    final service =
        File('lib/services/owner_preview_service.dart').readAsStringSync();

    expect(home, contains('OwnerBootstrapService().getir()'));
    expect(home, contains('if (owner.hasStore)'));
    expect(home, contains('openExistingOwnerWorkspace('));
    final publishedGuard =
        'if (publishedInfo != null && publishedInfo.isComplete)';
    expect(home, contains(publishedGuard));
    expect(home, contains('publishedInfo.canEditRemote'));
    expect(home, contains('AppRouter.openPublicUrl('));
    final navTap = RegExp(r'if \(index == 2\) \{\s*_openVixrexTab\(\);');
    expect(navTap.allMatches(home).length, 2);
    final assistantTap = RegExp('onOpen: _openVixrexTab,');
    expect(assistantTap.allMatches(home).length, 2);
    expect(controller, contains('_ownerPreviewService.openExistingStore('));
    final secureEntry = 'buildOwnerSessionEntryLink(normalizedSlug, code)';
    expect(service, contains(secureEntry));
  });
}
