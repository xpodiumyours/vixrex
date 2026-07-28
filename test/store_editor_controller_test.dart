import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';
import 'package:vixrex/utils/failure.dart';
import 'package:vixrex/widgets/editor/form_location_info.dart';

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

class FailedLocationService extends Fake implements LocationService {
  @override
  Future<LocationResult> getCurrentLocation() async {
    return LocationResult.failure('Konum izni reddedildi.');
  }
}

class FakeStorePublishService extends Fake implements StorePublishService {
  Result<void> deleteResult = const Result.success(null);
  String? deletedSlug;
  String? deletedEditToken;
  int publishCount = 0;

  @override
  Future<Result<StorePublishResult>> publishStore(
    StoreData data, {
    required String editToken,
  }) async {
    publishCount += 1;
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
  Future<Result<void>> updateProductsOnly(
    StoreData data, {
    required String editToken,
  }) async {
    return const Result.success(null);
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

    test('loading a published store does not publish it again', () async {
      await storageService.saveVitrinData(
        StoreData(
          name: 'Published Store',
          shelfImageUrl: 'https://dummy.co/existing-cover.jpg',
        ),
      );
      await storageService.savePublishedVitrinInfo(
        slug: 'published-store',
        publicLink: 'https://vixrex-public.vercel.app/v/published-store',
        name: 'Published Store',
        editToken: 'edit-token-12345678901234567890',
      );
      final fakePublish = FakeStorePublishService();
      final controller = StoreEditorController(
        storage: storageService,
        publishService: fakePublish,
        supabaseClient: fakeSupabase,
      );

      await controller.initialize(null);
      await Future<void>.delayed(Duration.zero);

      expect(fakePublish.publishCount, 0);
      expect(
        controller.coverUrl,
        'https://dummy.co/existing-cover.jpg',
      );
    });

    test('selecting a cover keeps it as a draft until publish', () async {
      await storageService.savePublishedVitrinInfo(
        slug: 'published-store',
        publicLink: 'https://vixrex-public.vercel.app/v/published-store',
        name: 'Published Store',
        editToken: 'edit-token-12345678901234567890',
      );
      final fakePublish = FakeStorePublishService();
      final controller = StoreEditorController(
        storage: storageService,
        publishService: fakePublish,
        supabaseClient: fakeSupabase,
      );
      await controller.initialize(null);

      controller.setCoverUrl('https://dummy.co/new-cover.jpg');
      await Future<void>.delayed(Duration.zero);

      expect(controller.coverUrl, 'https://dummy.co/new-cover.jpg');
      expect(controller.data.shelfImageUrl, 'https://dummy.co/new-cover.jpg');
      expect(fakePublish.publishCount, 0);
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
      'fetchLocation accepts approximate web GPS and still matches il/ilçe',
      () async {
        final controller = StoreEditorController(
          storage: storageService,
          locationService: FakeLocationService(useApproximate: true),
          supabaseClient: fakeSupabase,
        );

        await controller.initialize(null);
        await controller.triggerFetchLocation();

        expect(controller.latitude, 41.0082);
        expect(controller.longitude, 28.9784);
        expect(controller.selectedProvinceName, 'İstanbul');
        expect(controller.data.districtName, 'Kadıköy');
      },
    );

    test('failed GPS keeps the manual address and exposes the error', () async {
      final controller = StoreEditorController(
        storage: storageService,
        locationService: FailedLocationService(),
        supabaseClient: fakeSupabase,
      );
      await controller.initialize(null);
      controller.updateAddress(controller.data, 'Mevcut adres');
      controller.selectProvince(controller.data, '06', 'Ankara');
      controller.selectDistrict(controller.data, 'Çankaya', 'Çankaya');

      await controller.triggerFetchLocation();

      expect(controller.data.address, 'Mevcut adres');
      expect(controller.selectedProvinceName, 'Ankara');
      expect(controller.selectedDistrictName, 'Çankaya');
      expect(controller.locationStatusMessage, 'Konum izni reddedildi.');
      expect(controller.isLocating, isFalse);
    });

    testWidgets(
      'GPS button uses controller flow and keeps the manual address on failure',
      (tester) async {
        final controller = StoreEditorController(
          storage: storageService,
          locationService: FailedLocationService(),
          supabaseClient: fakeSupabase,
        );
        await controller.initialize(null);
        controller.updateAddress(controller.data, 'Mevcut adres');
        controller.selectProvince(controller.data, '06', 'Ankara');
        controller.selectDistrict(controller.data, 'Çankaya', 'Çankaya');
        final state = MyVitrinState(controller: controller);
        final addressController = TextEditingController(text: 'Mevcut adres');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedBuilder(
                animation: controller,
                builder: (_, __) => FormLocationInfo(
                  controller: controller,
                  state: state,
                  addressController: addressController,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('GPS ile Konumumu Al'));
        await tester.pumpAndSettle();

        expect(controller.data.address, 'Mevcut adres');
        expect(controller.selectedProvinceName, 'Ankara');
        expect(controller.selectedDistrictName, 'Çankaya');
        expect(find.text('Konum izni reddedildi.'), findsOneWidget);

        addressController.dispose();
        state.dispose();
        controller.dispose();
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
  });
}
