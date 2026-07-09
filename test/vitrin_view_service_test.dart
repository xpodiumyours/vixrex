import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/services/vitrin_view_service.dart';

// Dynamically handle methods using noSuchMethod to bypass compile-time signature checks
class FakeSupabaseClient implements SupabaseClient {
  final List<Map<String, dynamic>> rpcCalls = [];
  Object? rpcResponse;
  PostgrestException? postgrestExceptionToThrow;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #rpc) {
      final fn = invocation.positionalArguments[0] as String;
      final args = invocation.namedArguments;
      rpcCalls.add({
        'fn': fn,
        'params': args[#params] as Map<String, dynamic>?,
      });
      return FakePostgrestFilterBuilder<dynamic>(this);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakePostgrestFilterBuilder<T>
    implements PostgrestFilterBuilder<T>, Future<T> {
  final FakeSupabaseClient client;
  FakePostgrestFilterBuilder(this.client);

  Future<T> get _future {
    if (client.postgrestExceptionToThrow != null) {
      return Future<T>.error(client.postgrestExceptionToThrow!);
    }
    final val = (client.rpcResponse ?? 0) as T;
    return Future<T>.value(val);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSupabaseClient fakeClient;
  late VitrinViewService service;

  setUp(() {
    fakeClient = FakeSupabaseClient();
    service = VitrinViewService(supabaseClient: fakeClient);
    SharedPreferences.setMockInitialValues({});
  });

  group('VitrinViewService.recordView', () {
    test(
      'doğru parametreler ve normalleştirilmiş kaynak ile record_vitrin_view rpc çağırır',
      () async {
        await service.recordView(slug: 'butik-esra', source: ' QR ');

        expect(fakeClient.rpcCalls.length, 1);
        final call = fakeClient.rpcCalls.first;
        expect(call['fn'], 'record_vitrin_view');
        expect(call['params']?['p_slug'], 'butik-esra');
        expect(call['params']?['p_ua'], 'qr'); // lowercase and trimmed
        expect(call['params']?['p_ip'], isNotNull);
        expect(
          call['params']?['p_ip'].toString().length,
          greaterThanOrEqualTo(16),
        );
      },
    );

    test('bilinmeyen kaynakları "unknown" olarak normalize eder', () async {
      await service.recordView(slug: 'butik-esra', source: 'facebook_ads');

      expect(fakeClient.rpcCalls.length, 1);
      expect(fakeClient.rpcCalls.first['params']?['p_ua'], 'unknown');
    });

    test('SharedPreferences üzerindeki session_key değerini korur', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'vitrin_view_session_key',
        'my-custom-persistent-session-key',
      );

      await service.recordView(slug: 'butik-esra', source: 'share');

      expect(fakeClient.rpcCalls.length, 1);
      expect(
        fakeClient.rpcCalls.first['params']?['p_ip'],
        'my-custom-persistent-session-key',
      );
    });
  });

  group('VitrinViewService.fetchTodayViewCount', () {
    test('geçersiz veya boş argümanlarda 0 döner', () async {
      final count1 = await service.fetchTodayViewCount(
        slug: '',
        editToken: 't123',
      );
      final count2 = await service.fetchTodayViewCount(
        slug: 'test',
        editToken: ' ',
      );

      expect(count1, 0);
      expect(count2, 0);
      expect(fakeClient.rpcCalls, isEmpty);
    });

    test(
      'get_today_vitrin_view_count rpc çağrısı yapıp integer sonucu döner',
      () async {
        fakeClient.rpcResponse = 42;

        final count = await service.fetchTodayViewCount(
          slug: 'butik-esra',
          editToken: 'token123',
        );

        expect(count, 42);
        expect(fakeClient.rpcCalls.length, 1);
        final call = fakeClient.rpcCalls.first;
        expect(call['fn'], 'get_today_vitrin_view_count');
        expect(call['params']?['p_slug'], 'butik-esra');
        expect(call['params']?['p_edit_token'], 'token123');
      },
    );

    test('num tipindeki sonucu integera dönüştürür', () async {
      fakeClient.rpcResponse = 12.5;

      final count = await service.fetchTodayViewCount(
        slug: 'butik-esra',
        editToken: 'token123',
      );
      expect(count, 12);
    });

    test('String tipindeki sayıyı parse eder', () async {
      fakeClient.rpcResponse = '99';

      final count = await service.fetchTodayViewCount(
        slug: 'butik-esra',
        editToken: 'token123',
      );
      expect(count, 99);
    });

    test('rpc hata fırlattığında 0 döner ve crash etmez', () async {
      fakeClient.postgrestExceptionToThrow = const PostgrestException(
        message: 'Function not found',
        code: 'P0001',
      );

      final count = await service.fetchTodayViewCount(
        slug: 'butik-esra',
        editToken: 'token123',
      );
      expect(count, 0);
    });
  });
}
