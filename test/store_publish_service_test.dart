import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/store_publish_service.dart';

// Dynamically handle methods using noSuchMethod to bypass compile-time signature checks
class FakeSupabaseClient implements SupabaseClient {
  final Map<String, dynamic> queries = {};
  final List<Map<String, dynamic>> insertedPayloads = [];
  final List<Map<String, dynamic>> rpcCalls = [];

  Object? selectResponse;
  PostgrestException? postgrestExceptionToThrow;
  PostgrestException? postgrestExceptionToThrowOnInsert;

  @override
  GoTrueClient get auth => FakeGoTrueClient();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #from) {
      return FakeSupabaseQueryBuilder(this);
    }
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

class FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSupabaseQueryBuilder implements SupabaseQueryBuilder {
  final FakeSupabaseClient client;
  FakeSupabaseQueryBuilder(this.client);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #select) {
      return FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(client);
    }
    if (invocation.memberName == #insert) {
      final values = invocation.positionalArguments[0];
      if (values is Map<String, dynamic>) {
        client.insertedPayloads.add(values);
      } else if (values is List<Map<String, dynamic>>) {
        client.insertedPayloads.addAll(values.cast<Map<String, dynamic>>());
      }
      return FakePostgrestFilterBuilder<dynamic>(client, isInsert: true);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakePostgrestFilterBuilder<T>
    implements PostgrestFilterBuilder<T>, Future<T> {
  final FakeSupabaseClient client;
  final bool isInsert;
  FakePostgrestFilterBuilder(this.client, {this.isInsert = false});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #eq) {
      final column = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1];
      client.queries[column] = value;
      return this;
    }
    if (invocation.memberName == #maybeSingle) {
      return FakePostgrestTransformBuilder<Map<String, dynamic>?>(client);
    }
    return super.noSuchMethod(invocation);
  }

  Future<T> get _future {
    if (isInsert && client.postgrestExceptionToThrowOnInsert != null) {
      return Future<T>.error(client.postgrestExceptionToThrowOnInsert!);
    }
    if (!isInsert && client.postgrestExceptionToThrow != null) {
      return Future<T>.error(client.postgrestExceptionToThrow!);
    }
    final val = (client.selectResponse ?? <String, dynamic>{}) as T;
    return Future<T>.value(val);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }
}

class FakePostgrestTransformBuilder<T>
    implements PostgrestTransformBuilder<T>, Future<T> {
  final FakeSupabaseClient client;
  FakePostgrestTransformBuilder(this.client);

  Future<T> get _future {
    if (client.postgrestExceptionToThrow != null) {
      return Future<T>.error(client.postgrestExceptionToThrow!);
    }
    final val = client.selectResponse as T;
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
  late StorePublishService service;
  late StoreData sampleStore;

  setUp(() {
    fakeClient = FakeSupabaseClient();
    service = StorePublishService(supabaseClient: fakeClient);
    sampleStore = StoreData(
      isStore: true,
      name: 'Test Mağazası',
      kategori: 'Giyim',
      isEsnafMode: true,
      address: 'Test Adresi',
      whatsapp: '905555555555',
      description: 'Açıklama',
    );
  });

  group('StorePublishService.publishStore - Yeni Kayıt', () {
    test('Mağaza mevcut değilse insert yapar ve publicPath döner', () async {
      fakeClient.selectResponse = null;

      final result = await service.publishStore(sampleStore, editToken: 't123');

      expect(result.wasUpdated, isFalse);
      expect(result.publicPath, '/v/test-magazasi');
      expect(fakeClient.queries['slug'], 'test-magazasi');
      expect(fakeClient.insertedPayloads.length, 1);
      expect(fakeClient.insertedPayloads.first['edit_token'], 't123');
    });

    test('Validasyondan geçemeyen mağaza hata fırlatır', () async {
      final invalidStore = StoreData(isStore: true, name: '');
      expect(
        () => service.publishStore(invalidStore, editToken: 't123'),
        throwsA(isA<StorePublishException>()),
      );
    });
  });

  group('StorePublishService.publishStore - Güncelleme', () {
    test(
      'Mağaza zaten mevcutsa update_store_with_token rpc fonksiyonunu çağırır',
      () async {
        fakeClient.selectResponse = {'slug': 'test-magazasi'};

        final result = await service.publishStore(
          sampleStore,
          editToken: 't123',
        );

        expect(result.wasUpdated, isTrue);
        expect(result.publicPath, '/v/test-magazasi');
        expect(fakeClient.rpcCalls.length, 1);
        expect(fakeClient.rpcCalls.first['fn'], 'update_store_with_token');
        expect(fakeClient.rpcCalls.first['params']['p_edit_token'], 't123');
      },
    );

    test(
      'Duplicate slug hatası (23505) aldığında token update fonksiyonunu tetikler',
      () async {
        fakeClient.selectResponse = null;
        fakeClient.postgrestExceptionToThrowOnInsert = const PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        );

        final result = await service.publishStore(
          sampleStore,
          editToken: 't123',
        );

        expect(result.wasUpdated, isTrue);
        expect(result.publicPath, '/v/test-magazasi');
        expect(fakeClient.rpcCalls.length, 1);
        expect(fakeClient.rpcCalls.first['fn'], 'update_store_with_token');
      },
    );

    test(
      'Yetki/RLS hatası aldığında uygun açıklayıcı mesaj fırlatır',
      () async {
        fakeClient.selectResponse = {'slug': 'test-magazasi'};
        fakeClient.postgrestExceptionToThrow = const PostgrestException(
          message: 'row-level security policy violation',
          code: '42501',
        );

        expect(
          () => service.publishStore(sampleStore, editToken: 't123'),
          throwsA(
            isA<StorePublishException>().having(
              (e) => e.toString(),
              'message',
              contains('Supabase tarafında eksik'),
            ),
          ),
        );
      },
    );
  });
}
