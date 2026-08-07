import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/public_store_mapper.dart';
import 'package:vixrex/services/store_publish_service.dart';

void main() {
  test('v2 mapStoreFromSupabase ürünleri JSON’dan doldurmaz', () {
    final store = PublicStoreMapper.mapStoreFromSupabase(
      slug: 'demo',
      data: {
        'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'product_storage_version': 2,
        'name': 'Demo',
        'products': [
          {'id': 'json-1', 'name': 'JSON Ürün', 'isVisible': true},
        ],
        'gallery_items': [],
      },
    );

    expect(store.id, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
    expect(store.products, isEmpty);
  });

  test('mapStoreFromSupabase JSON ürünleri hicbir kosulda okumaz', () {
    final store = PublicStoreMapper.mapStoreFromSupabase(
      slug: 'demo',
      data: {
        'product_storage_version': 1,
        'name': 'Demo',
        'products': [
          {'id': 'json-1', 'name': 'JSON Ürün', 'isVisible': true},
        ],
        'gallery_items': [],
      },
    );

    expect(store.products, isEmpty);
  });

  test(
    'StorePublishPayloadBuilder toStoreUpdateMap includes product_storage_version = 2',
    () {
      final map = const StorePublishPayloadBuilder().toStoreUpdateMap(
        StoreData(name: 'Demo'),
      );
      expect(map['product_storage_version'], 2);
    },
  );
}
