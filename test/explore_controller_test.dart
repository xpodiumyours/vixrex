import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/controllers/explore_controller.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/repositories/explore_repository.dart';


class FakeExploreRepository extends Fake implements ExploreRepository {
  List<StoreData>? mockStores;
  bool shouldThrow = false;
  List<String> mockFavorites = [];
  String? mockOwnSlug;

  FakeExploreRepository({
    this.mockStores,
    this.shouldThrow = false,
    this.mockOwnSlug,
  });

  @override
  Future<List<StoreData>> fetchPublishedStores() async {
    if (shouldThrow) {
      throw Exception('Supabase connection error');
    }
    return mockStores ?? [];
  }

  @override
  Future<List<String>> loadFavoriteStoreNames() async {
    return mockFavorites;
  }

  @override
  Future<void> saveFavoriteStoreNames(List<String> names) async {
    mockFavorites = names;
  }

  @override
  Future<String?> loadLastPublishedSlug() async {
    return mockOwnSlug;
  }
}

void main() {
  group('ExploreController Tests', () {
    late List<StoreData> testStores;

    setUp(() {
      testStores = [
        StoreData(
          name: 'Store A',
          description: 'Desc A',
          kategori: 'Giyim & Butik',
          slug: 'store-a',
        ),
        StoreData(
          name: 'Store B',
          description: 'Desc B',
          kategori: 'Gıda & Fırın',
          slug: 'store-b',
        ),
        StoreData(
          name: 'Store C',
          description: 'Desc C',
          kategori: 'Giyim & Butik',
          slug: 'store-c',
        ),
      ];
    });

    test('initialize loads favorites and stores successfully', () async {
      final repo = FakeExploreRepository(
        mockStores: testStores,
        mockOwnSlug: 'store-b',
      );
      repo.mockFavorites = ['Store A'];

      final controller = ExploreController(repository: repo);
      await controller.initialize();

      expect(controller.isLoading, isFalse);
      expect(controller.showingExampleStores, isFalse);
      expect(controller.favoritedStoreNames, contains('Store A'));

      // Check if own store (Store B) is put at the top of the list
      expect(controller.allStores[0].name, 'Store B');
      expect(controller.isOwnStore(controller.allStores[0]), isTrue);
    });

    test(
      'search query filter works across name, description, and kategori',
      () async {
        final repo = FakeExploreRepository(mockStores: testStores);
        final controller = ExploreController(repository: repo);
        await controller.initialize();

        // Search by name
        controller.setSearchQuery('Store A');
        expect(controller.filteredStores.length, 1);
        expect(controller.filteredStores[0].name, 'Store A');

        // Search by description
        controller.setSearchQuery('Desc B');
        expect(controller.filteredStores.length, 1);
        expect(controller.filteredStores[0].name, 'Store B');

        // Search by kategori
        controller.setSearchQuery('Giyim & Butik');
        expect(controller.filteredStores.length, 2);
      },
    );

    test('category filter and favorite filter work together', () async {
      final repo = FakeExploreRepository(mockStores: testStores);
      repo.mockFavorites = ['Store A', 'Store B'];
      final controller = ExploreController(repository: repo);
      await controller.initialize();

      // Filter by category
      controller.setCategory('Giyim & Butik');
      expect(controller.filteredStores.length, 2);

      // Filter by favorites only
      controller.setOnlyFavorites(true);
      // Only Store A is both Giyim & Butik and a favorite
      expect(controller.filteredStores.length, 1);
      expect(controller.filteredStores[0].name, 'Store A');
    });

    test('toggleFavorite adds/removes store from favorites list', () async {
      final repo = FakeExploreRepository(mockStores: testStores);
      final controller = ExploreController(repository: repo);
      await controller.initialize();

      expect(controller.isFavorite(testStores[0]), isFalse);

      await controller.toggleFavorite('Store A');
      expect(controller.isFavorite(testStores[0]), isTrue);

      await controller.toggleFavorite('Store A');
      expect(controller.isFavorite(testStores[0]), isFalse);
    });

    test('fallback to mock stores on fetch failure', () async {
      final repo = FakeExploreRepository(shouldThrow: true);
      final controller = ExploreController(repository: repo);
      await controller.initialize();

      expect(controller.isLoading, isFalse);
      expect(controller.showingExampleStores, isTrue);
      expect(controller.loadErrorMessage, isNotNull);
      expect(controller.allStores.length, 3);
      expect(controller.allStores[0].name, 'Aymira Giyim');
    });
  });
}
