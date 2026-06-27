import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/repositories/explore_repository.dart';
import 'package:vitrinx/services/local_storage_keys.dart';

class MockHttpClient extends Fake implements http.Client {
  final String responseBody;
  final int statusCode;
  MockHttpClient(this.responseBody, {this.statusCode = 200});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = http.Response(
      responseBody,
      statusCode,
      headers: {'content-type': 'application/json'},
    );
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('ExploreRepository Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'favorite_stores': ['Aymira Giyim'],
        LocalStorageKeys.lastPublishedSlug: 'aymira-giyim',
      });
      prefs = await SharedPreferences.getInstance();
    });

    test('loadFavoriteStoreNames loads correct favorites', () async {
      final repo = ExploreRepository(sharedPreferences: prefs);
      final favorites = await repo.loadFavoriteStoreNames();
      expect(favorites, contains('Aymira Giyim'));
      expect(favorites.length, 1);
    });

    test('saveFavoriteStoreNames saves correctly', () async {
      final repo = ExploreRepository(sharedPreferences: prefs);
      await repo.saveFavoriteStoreNames(['Aymira Giyim', 'Lezzet Durağı']);
      final favorites = await repo.loadFavoriteStoreNames();
      expect(favorites, containsAll(['Aymira Giyim', 'Lezzet Durağı']));
      expect(favorites.length, 2);
    });

    test('loadLastPublishedSlug loads correctly', () async {
      final repo = ExploreRepository(sharedPreferences: prefs);
      final slug = await repo.loadLastPublishedSlug();
      expect(slug, 'aymira-giyim');
    });

    test(
      'fetchPublishedStores parses published stores JSON correctly via HTTP Mock',
      () async {
        final mockData = [
          {
            'name': 'Aymira Giyim',
            'description': 'Description 1',
            'category': 'Giyim & Butik',
            'whatsapp': '05551234567',
            'address': 'Address 1',
            'slug': 'aymira-giyim',
            'shelfImageUrl': '',
            'is_store': true,
            'is_published': true,
          },
        ];

        final mockClient = MockHttpClient(jsonEncode(mockData));
        final fakeSupabase = SupabaseClient(
          'https://dummyproject.supabase.co',
          'dummyAnonKey',
          httpClient: mockClient,
        );

        final repo = ExploreRepository(
          supabaseClient: fakeSupabase,
          sharedPreferences: prefs,
        );

        final stores = await repo.fetchPublishedStores();
        expect(stores.length, 1);
        expect(stores[0].name, 'Aymira Giyim');
        expect(stores[0].kategori, 'Giyim & Butik');
      },
    );
  });
}
