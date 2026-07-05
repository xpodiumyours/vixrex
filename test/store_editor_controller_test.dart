import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/controllers/store_editor_controller.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/services/location_service.dart';
import 'package:vitrinx/services/store_local_storage_service.dart';
import 'package:vitrinx/services/store_publish_service.dart';
import 'package:vitrinx/services/store_shelf_upload_service.dart';

class FakeLocationService extends Fake implements LocationService {
  @override
  Future<LocationResult> getCurrentLocation() async {
    return LocationResult.success(
      Position(
        latitude: 41.0082,
        longitude: 28.9784,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
    );
  }

  @override
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    return 'İstanbul Kadıköy Moda';
  }
}

class FakeStorePublishService extends Fake implements StorePublishService {
  @override
  Future<StorePublishResult> publishStore(
    StoreData data, {
    required String editToken,
  }) async {
    return StorePublishResult(
      slug: 'test-store',
      publicPath: '/test-store',
      wasUpdated: false,
      editToken: editToken,
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
        await controller.fetchLocation();

        expect(controller.latitude, 41.0082);
        expect(controller.longitude, 28.9784);
        expect(controller.data.address, 'İstanbul Kadıköy Moda');
        expect(controller.selectedProvinceName, 'İstanbul');
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
        controller.updateAddress('Valid Address');
        controller.selectProvince('34', 'İstanbul');
        controller.selectDistrict('Kadıköy', 'Kadıköy');

        final publicLink = await controller.publish();
        expect(publicLink, contains('test-store'));
        expect(controller.publishedInfo?.slug, 'test-store');
      },
    );
  });
}
