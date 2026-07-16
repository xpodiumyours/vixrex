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
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/location_service.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_publish_service.dart';
import 'package:vixrex/services/store_shelf_upload_service.dart';

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
  @override
  Future<Result<StorePublishResult>> publishStore(
    StoreData data, {
    required String editToken,
  }) async {
    return Result.success(StorePublishResult(
      slug: 'test-store',
      publicPath: '/test-store',
      wasUpdated: false,
      editToken: editToken,
    ));
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
  });
}
