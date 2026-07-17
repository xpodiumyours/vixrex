import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/store_publish_service.dart';

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
      return FakePostgrestFilterBuilder<dynamic>(
        this,
        isCreateRpc: fn == 'create_store_with_token',
      );
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
  final bool isCreateRpc;
  FakePostgrestFilterBuilder(
    this.client, {
    this.isInsert = false,
    this.isCreateRpc = false,
  });

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
    if ((isInsert || isCreateRpc) &&
        client.postgrestExceptionToThrowOnInsert != null) {
      return Future<T>.error(client.postgrestExceptionToThrowOnInsert!);
    }
    if (!isInsert && !isCreateRpc && client.postgrestExceptionToThrow != null) {
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
  const editToken = 'edit-token-1234567890123456';

  setUp(() {
    fakeClient = FakeSupabaseClient();
    service = StorePublishService(supabaseClient: fakeClient);
    sampleStore = StoreData(
      isStore: true,
      name: 'Test Mağazası',
      kategori: 'Giyim',
      isEsnafMode: true,
      address: 'Test Adresi',
      provinceName: 'İstanbul',
      provinceCode: '34',
      districtName: 'Kadıköy',
      districtCode: '3447',
      whatsapp: '905555555555',
      description: 'Açıklama',
      privacyNoticeAcknowledged: true,
      privacyNoticeVersion: 'privacy-v1',
      privacyNoticeHash: 'privacy-hash',
      termsAccepted: true,
      termsVersion: 'terms-v1',
      termsHash: 'terms-hash',
      publicationConsentAccepted: true,
      publicationConsentVersion: 'consent-v1',
      publicationConsentHash: 'consent-hash',
    );
  });

  group('StorePublishService.publishStore - Yeni Kayıt', () {
    test('Mağaza mevcut değilse create_store_with_token rpc çağırır', () async {
      fakeClient.selectResponse = null;

      final result = await service.publishStore(
        sampleStore,
        editToken: editToken,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.wasUpdated, isFalse);
      expect(result.data!.publicPath, '/v/test-magazasi');
      expect(fakeClient.queries['slug'], 'test-magazasi');
      expect(fakeClient.queries.containsKey('edit_token'), isFalse);
      expect(fakeClient.insertedPayloads, isEmpty);
      expect(fakeClient.rpcCalls.length, 1);
      expect(fakeClient.rpcCalls.first['fn'], 'create_store_with_token');
      expect(fakeClient.rpcCalls.first['params']['p_edit_token'], editToken);
      expect(fakeClient.rpcCalls.first['params']['p_slug'], 'test-magazasi');
    });

    test('Validasyondan geçemeyen mağaza Result.failure döner', () async {
      final invalidStore = StoreData(isStore: true, name: '');
      final result = await service.publishStore(
        invalidStore,
        editToken: editToken,
      );
      expect(result.isFailure, isTrue);
      expect(result.failure!.message, isNotEmpty);
    });
  });

  group('StorePublishService.publishStore - Güncelleme', () {
    test(
      'Mağaza zaten mevcutsa update_store_with_token rpc fonksiyonunu çağırır',
      () async {
        fakeClient.selectResponse = {'slug': 'test-magazasi'};

        final result = await service.publishStore(
          sampleStore,
          editToken: editToken,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.wasUpdated, isTrue);
        expect(result.data!.publicPath, '/v/test-magazasi');
        expect(fakeClient.rpcCalls.length, 1);
        expect(fakeClient.rpcCalls.first['fn'], 'update_store_with_token');
        expect(fakeClient.rpcCalls.first['params']['p_edit_token'], editToken);
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
          editToken: editToken,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.wasUpdated, isTrue);
        expect(result.data!.publicPath, '/v/test-magazasi');
        expect(
          fakeClient.rpcCalls.map((c) => c['fn']),
          containsAll(['create_store_with_token', 'update_store_with_token']),
        );
      },
    );

    test(
      'Yetkisiz slug çakışmasında yeni benzersiz slug ile create çağırır',
      () async {
        fakeClient.selectResponse = {'slug': 'test-magazasi'};
        fakeClient.postgrestExceptionToThrow = const PostgrestException(
          message: 'STORE_UPDATE_NOT_ALLOWED',
          code: 'P0001',
        );

        final result = await service.publishStore(
          sampleStore,
          editToken: editToken,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.wasUpdated, isFalse);
        expect(result.data!.slug, startsWith('test-magazasi-'));
        expect(result.data!.slug, isNot('test-magazasi'));
        expect(
          fakeClient.rpcCalls.map((c) => c['fn']),
          containsAll(['update_store_with_token', 'create_store_with_token']),
        );
      },
    );
  });

  group('StorePublishService publication consent withdrawal', () {
    test('withdraw RPC is called with slug and edit token', () async {
      await service.withdrawPublicationConsent(
        slug: 'test-magazasi',
        editToken: 'edit-token-12345678901234567890',
      );

      expect(
        fakeClient.rpcCalls.last['fn'],
        'withdraw_store_publication_consent',
      );
      expect(fakeClient.rpcCalls.last['params'], {
        'p_slug': 'test-magazasi',
        'p_edit_token': 'edit-token-12345678901234567890',
      });
    });
  });

  group('StorePublishService permanent deletion', () {
    test('delete RPC is called with slug and edit token', () async {
      await service.deleteStore(
        slug: 'test-magazasi',
        editToken: 'edit-token-12345678901234567890',
      );

      expect(fakeClient.rpcCalls.last['fn'], 'delete_store_with_token');
      expect(fakeClient.rpcCalls.last['params'], {
        'p_slug': 'test-magazasi',
        'p_edit_token': 'edit-token-12345678901234567890',
      });
    });
  });

  group('StorePublishService.updateProductsOnly', () {
    test('ürünleri update_store_with_token RPC ile kaydeder', () async {
      fakeClient.selectResponse = {'slug': 'test-magazasi'};
      sampleStore.products = [Product(id: 'p1', name: 'Tişört', price: '199')];
      sampleStore.slug = 'test-magazasi';

      final result = await service.updateProductsOnly(
        sampleStore,
        editToken: 'edit-token-12345678901234567890',
      );

      expect(result.isSuccess, isTrue);
      expect(fakeClient.rpcCalls.length, 1);
      expect(fakeClient.rpcCalls.first['fn'], 'update_store_with_token');
      final params =
          fakeClient.rpcCalls.first['params'] as Map<String, dynamic>;
      expect(params['p_slug'], 'test-magazasi');
      expect(params['p_edit_token'], 'edit-token-12345678901234567890');
      final pStore = params['p_store'] as Map<String, dynamic>;
      expect(pStore.containsKey('products'), isTrue);
      expect(pStore.containsKey('product_categories'), isTrue);
      expect((pStore['products'] as List).length, 1);
      expect(pStore['products'][0]['name'], 'Tişört');
    });
  });
}
