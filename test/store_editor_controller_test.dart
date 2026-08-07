import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/editor_gallery_item.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/repositories/product_repository.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/services/product_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';
import 'package:vixrex/utils/failure.dart';

class FakeLocationService extends Fake implements LocationService {
  FakeLocationService({this.useApproximate = false});

  final bool useApproximate;

  @override
  Future<LocationResult> getCurrentLocation() async {
    final position = Position(
      latitude: 41.0082,
      longitude: 28.9784,
      timestamp: DateTime.now(),
      accuracy: useApproximate ? 120 : 10,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    if (useApproximate) {
      return LocationResult.approximate(
        position,
        LocationService.buildAccuracyMessage(position.accuracy),
      );
    }
    return LocationResult.success(position);
  }

  @override
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    return 'İstanbul Kadıköy Moda';
  }
}

class FakeStorePublishService extends Fake implements StorePublishService {
  Result<void> deleteResult = const Result.success(null);
  String? deletedSlug;
  String? deletedEditToken;
  int saveDraftCalls = 0;
  List<StoreGalleryItem> galleryAtDraftSave = const [];

  @override
  final StorePublishPayloadBuilder payloadBuilder =
      const StorePublishPayloadBuilder();

  @override
  Future<Result<StorePublishResult>> publishStore(
    StoreData data, {
    required String editToken,
  }) async {
    return Result.success(
      StorePublishResult(
        slug: 'test-store',
        publicPath: '/test-store',
        wasUpdated: false,
        editToken: editToken,
      ),
    );
  }

  @override
  Future<Result<void>> updateStorePatch({
    required String slug,
    required String editToken,
    required Map<String, dynamic> patch,
  }) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteStore({
    required String slug,
    String? editToken,
  }) async {
    deletedSlug = slug;
    deletedEditToken = editToken;
    return deleteResult;
  }

  @override
  Future<Result<StoreDraftResult>> saveDraft(
    StoreData data, {
    required String editToken,
  }) async {
    saveDraftCalls++;
    galleryAtDraftSave = List<StoreGalleryItem>.of(data.galleryItems);
    return Result.success(
      StoreDraftResult(slug: 'draft-store', editToken: editToken),
    );
  }
}

class FakeStoreShelfUploadService extends Fake
    implements StoreShelfUploadService {
  @override
  Future<String> uploadShelfImage(
    Uint8List bytes,
    String path, {
    String fileExtension = 'jpg',
    String contentType = 'image/jpeg',
  }) async {
    return 'https://dummy.co/cover.jpg';
  }
}

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

/// `create_owner_session` RPC'sine tek kullanımlık kod döndürür; diğer
/// isteklere boş nesne yanıtlar. Commit 5 akışını (openOwnerPreview) test eder.
class OwnerSessionMockHttpClient extends Fake implements http.Client {
  final String code;
  OwnerSessionMockHttpClient({this.code = 'test-owner-code-1234'});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isOwnerSession = request.url.path.endsWith(
      '/rpc/create_owner_session',
    );
    final body =
        isOwnerSession
            ? jsonEncode({'code': code, 'expires_at': '2026-08-04T10:00:00Z'})
            : jsonEncode({});
    final response = http.Response(
      body,
      200,
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

class FakeProductRepository extends Fake implements ProductRepository {
  @override
  Future<List<Product>> getProductsByStoreId(String storeId) async => [];
}

void main() {
  group('StoreEditorController Tests', () {
    late StoreLocalStorageService storageService;
    late SupabaseClient fakeSupabase;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      StoreLocalStorageService.resetCache();
      storageService = const StoreLocalStorageService();

      final mockClient = MockHttpClient(jsonEncode({}));
      fakeSupabase = SupabaseClient(
        'https://dummyproject.supabase.co',
        'dummyAnonKey',
        httpClient: mockClient,
      );
    });

    test('initialize loads empty default store data correctly', () async {
      final controller = StoreEditorController(
        storage: storageService,
        supabaseClient: fakeSupabase,
      );

      await controller.initialize('New Store');

      expect(controller.isLoading, isFalse);
      expect(controller.data.name, 'New Store');
      expect(controller.selectedKategori, 'Diğer');
      expect(controller.selectedStatus, 'Açık');
    });

    test(
      'form inputs modify controller state and trigger notifyListeners',
      () async {
        final controller = StoreEditorController(
          storage: storageService,
          supabaseClient: fakeSupabase,
        );

        await controller.initialize(null);

        controller.updateName('My Store');
        expect(controller.data.name, 'My Store');

        controller.updateWhatsapp('05551234567');
        expect(controller.data.whatsapp, '05551234567');

        controller.selectCategory('Giyim & Butik');
        expect(controller.selectedKategori, 'Giyim & Butik');
        expect(controller.data.kategori, 'Giyim & Butik');
        expect(controller.bookingIsEnabled, isFalse);

        controller.selectCategory('Kuaför');
        expect(controller.bookingIsEnabled, isTrue);

        controller.selectCategory('Butik');
        expect(controller.bookingIsEnabled, isFalse);
      },
    );

    test(
      'fetchLocation retrieves coordinates and matched province/district',
      () async {
        final controller = StoreEditorController(
          storage: storageService,
          locationService: FakeLocationService(),
          supabaseClient: fakeSupabase,
        );

        await controller.initialize(null);
        await controller.triggerFetchLocation();

        expect(controller.latitude, 41.0082);
        expect(controller.longitude, 28.9784);
        expect(controller.data.address, 'İstanbul Kadıköy Moda');
        expect(controller.selectedProvinceName, 'İstanbul');
      },
    );

    test(
      'fetchLocation YAKLAŞIK konumu REDDEDER — koordinat yazılmaz',
      () async {
        // 2026-08-06 ürün kararı: konum en fazla 10 metre sapmayla kabul
        // edilir. Bu test eskiden tersini kilitliyordu ("accepts approximate
        // web GPS") ve masaüstünde kilometrelerce sapmış konum sessizce
        // kaydediliyordu — esnaf yanlış konumla vitrin yayınlıyordu.
        //
        // Vitrinin işi "yakınındaki dükkânı" bulmak. Yanlış pin müşteriyi
        // yanlış sokağa gönderir; yokluğundan beterdir.
        final controller = StoreEditorController(
          storage: storageService,
          locationService: FakeLocationService(useApproximate: true),
          supabaseClient: fakeSupabase,
        );

        await controller.initialize(null);
        await controller.triggerFetchLocation();

        // Koordinat YAZILMAZ.
        expect(controller.latitude, isNull);
        expect(controller.longitude, isNull);

        // Adres de çözülmez, il/ilçe otomatik doldurulmaz.
        expect(controller.data.districtName, isEmpty);

        // Kullanıcı neden kabul edilmediğini ve ne yapacağını öğrenir.
        expect(controller.locationStatusMessage, isNotNull);
        expect(controller.locationStatusMessage, contains('TELEFONDAN'));
      },
    );

    test('publish validation throws error on invalid fields', () async {
      final controller = StoreEditorController(
        storage: storageService,
        supabaseClient: fakeSupabase,
      );

      await controller.initialize('Invalid Store');
      // WhatsApp is empty, should throw
      expect(() => controller.publish(), throwsException);
    });

    test(
      'publish updates status and stores published info successfully on valid data',
      () async {
        final controller = StoreEditorController(
          storage: storageService,
          publishService: FakeStorePublishService(),
          uploadService: FakeStoreShelfUploadService(),
          supabaseClient: fakeSupabase,
        );

        await controller.initialize('Valid Store');
        controller.updateWhatsapp('05551234567');
        controller.updateAddress(controller.data, 'Valid Address');
        controller.selectProvince(controller.data, '34', 'İstanbul');
        controller.selectDistrict(controller.data, 'Kadıköy', 'Kadıköy');

        final publicLink = await controller.publish();
        expect(publicLink, contains('test-store'));
        expect(controller.publishedInfo?.slug, 'test-store');
      },
    );

    test('authenticated owner can delete without a local edit token', () async {
      await storageService.savePublishedVitrinInfo(
        slug: 'owner-store',
        publicLink: 'https://vixrex-public.vercel.app/v/owner-store',
        name: 'Owner Store',
        editToken: '',
      );
      final fakePublish = FakeStorePublishService();
      final controller = StoreEditorController(
        storage: storageService,
        publishService: fakePublish,
        supabaseClient: fakeSupabase,
      );

      await controller.initialize(null);
      await controller.deleteVitrin();

      expect(fakePublish.deletedSlug, 'owner-store');
      expect(fakePublish.deletedEditToken, isEmpty);
      expect(await storageService.loadPublishedVitrinInfo(), isNull);
    });

    test('remote delete failure keeps local published store data', () async {
      await storageService.savePublishedVitrinInfo(
        slug: 'owner-store',
        publicLink: 'https://vixrex-public.vercel.app/v/owner-store',
        name: 'Owner Store',
        editToken: 'edit-token-12345678901234567890',
      );
      final fakePublish =
          FakeStorePublishService()
            ..deleteResult = Result.failure(Failure('remote delete failed'));
      final controller = StoreEditorController(
        storage: storageService,
        publishService: fakePublish,
        supabaseClient: fakeSupabase,
      );

      await controller.initialize(null);

      expect(controller.deleteVitrin(), throwsA('remote delete failed'));
      expect(await storageService.loadPublishedVitrinInfo(), isNotNull);
    });

    test('openOwnerPreview taslak için sahip giriş adresi döndürür', () async {
      final ownerSupabase = SupabaseClient(
        'https://dummyproject.supabase.co',
        'dummyAnonKey',
        httpClient: OwnerSessionMockHttpClient(),
      );
      final controller = StoreEditorController(
        storage: storageService,
        publishService: FakeStorePublishService(),
        supabaseClient: ownerSupabase,
      );

      await controller.initialize('Taslak Mağaza');
      final owner = await controller.openOwnerPreview();

      expect(owner.url, contains('/api/owner-session'));
      expect(owner.url, contains('slug=draft-store'));
      expect(owner.url, contains('ocode=test-owner-code-1234'));
      expect(owner.url, isNot(contains('preview_token')));
      expect(owner.url, isNot(contains('edit-token')));
    });

    test(
      'openOwnerPreview yayınlanmış vitrin için müşteri linki yerine sahip giriş adresi döndürür',
      () async {
        await storageService.savePublishedVitrinInfo(
          slug: 'owner-store',
          publicLink: 'https://vixrex-public.vercel.app/v/owner-store',
          name: 'Owner Store',
          editToken: 'edit-token-12345678901234567890',
        );
        final ownerSupabase = SupabaseClient(
          'https://dummyproject.supabase.co',
          'dummyAnonKey',
          httpClient: OwnerSessionMockHttpClient(),
        );
        final controller = StoreEditorController(
          storage: storageService,
          publishService: FakeStorePublishService(),
          supabaseClient: ownerSupabase,
        );

        await controller.initialize(null);
        final owner = await controller.openOwnerPreview();

        expect(
          owner.url,
          isNot('https://vixrex-public.vercel.app/v/owner-store'),
        );
        expect(owner.url, contains('/api/owner-session'));
        expect(owner.url, contains('slug=owner-store'));
        expect(owner.url, contains('ocode=test-owner-code-1234'));
        expect(owner.url, isNot(contains('preview_token')));
        expect(owner.url, isNot(contains('edit-token')));
      },
    );

    test(
      'openOwnerPreview taslak için önce taslağı güvenli şekilde kaydeder ve yerel veriyi senkronlar',
      () async {
        final ownerSupabase = SupabaseClient(
          'https://dummyproject.supabase.co',
          'dummyAnonKey',
          httpClient: OwnerSessionMockHttpClient(),
        );
        final controller = StoreEditorController(
          storage: storageService,
          publishService: FakeStorePublishService(),
          supabaseClient: ownerSupabase,
        );

        await controller.initialize('Taslak Mağaza');
        controller.updateWhatsapp('05551234567');
        await controller.openOwnerPreview();

        expect(controller.data.slug, 'draft-store');
        final saved = await storageService.loadVitrinData();
        expect(saved?.slug, 'draft-store');
        expect(saved?.whatsapp, '05551234567');
      },
    );

    test(
      'openOwnerPreview güncel galeri verisini uzak taslağa kaydetmeden önce senkronlar',
      () async {
        final publishService = FakeStorePublishService();
        final ownerSupabase = SupabaseClient(
          'https://dummyproject.supabase.co',
          'dummyAnonKey',
          httpClient: OwnerSessionMockHttpClient(),
        );
        final controller = StoreEditorController(
          storage: storageService,
          publishService: publishService,
          supabaseClient: ownerSupabase,
        );

        await controller.initialize('Taslak Mağaza');
        controller.addGalleryItem(
          const EditorGalleryItem(
            id: 'new-gallery-item',
            imageUrl: 'https://example.com/gallery.jpg',
            title: 'Yeni galeri',
          ),
        );

        await controller.openOwnerPreview();

        expect(publishService.galleryAtDraftSave, hasLength(1));
        expect(publishService.galleryAtDraftSave.single.id, 'new-gallery-item');
      },
    );

    test(
      'openOwnerPreview token bulunmayan yayın sahibini taslak akışına düşürmez',
      () async {
        await storageService.savePublishedVitrinInfo(
          slug: 'authenticated-owner-store',
          publicLink:
              'https://vixrex-public.vercel.app/v/authenticated-owner-store',
          name: 'Authenticated Owner Store',
          editToken: '',
        );
        final publishService = FakeStorePublishService();
        final ownerSupabase = SupabaseClient(
          'https://dummyproject.supabase.co',
          'dummyAnonKey',
          httpClient: OwnerSessionMockHttpClient(),
        );
        final controller = StoreEditorController(
          storage: storageService,
          publishService: publishService,
          supabaseClient: ownerSupabase,
        );

        await controller.initialize(null);
        final owner = await controller.openOwnerPreview();

        expect(publishService.saveDraftCalls, 0);
        expect(owner.url, contains('slug=authenticated-owner-store'));
        expect(owner.url, contains('ocode=test-owner-code-1234'));
      },
    );

    test(
      'openOwnerPreview RPC yetki reddini anlaşılır mesaja çevirir',
      () async {
        await storageService.savePublishedVitrinInfo(
          slug: 'owner-store',
          publicLink: 'https://vixrex-public.vercel.app/v/owner-store',
          name: 'Owner Store',
          editToken: 'edit-token-12345678901234567890',
        );
        final failingClient = MockHttpClient(
          jsonEncode({
            'code': 'P0001',
            'message': 'OWNER_AUTHORIZATION_REQUIRED',
            'details': null,
            'hint': null,
          }),
          statusCode: 400,
        );
        final ownerSupabase = SupabaseClient(
          'https://dummyproject.supabase.co',
          'dummyAnonKey',
          httpClient: failingClient,
        );
        final controller = StoreEditorController(
          storage: storageService,
          publishService: FakeStorePublishService(),
          supabaseClient: ownerSupabase,
        );

        await controller.initialize(null);

        expect(
          () => controller.openOwnerPreview(),
          throwsA(
            isA<StorePublishException>().having(
              (e) => e.message,
              'message',
              contains('düzenleme yetkiniz yok'),
            ),
          ),
        );
      },
    );

    test('openOwnerPreview istemci yokken anlaşılır hata fırlatır', () async {
      final controller = StoreEditorController(
        storage: storageService,
        publishService: FakeStorePublishService(),
        supabaseClient: null,
        productService: ProductService(repository: FakeProductRepository()),
      );

      await controller.initialize('Taslak Mağaza');

      expect(
        () => controller.openOwnerPreview(),
        throwsA(
          isA<StorePublishException>().having(
            (e) => e.message,
            'message',
            contains('Sahip oturumu oluşturulamadı'),
          ),
        ),
      );
    });
  });
}
