import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/services/store_publish_service.dart';

import '../test/helpers/fake_supabase_client.dart';

class _StubHttpClient extends Fake implements http.Client {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = http.Response(
      '{}',
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

/// SMOKE TEST — Gerçek E2E değil.
///
/// Controller unit testi (mock Supabase ile).
/// Gerçek kullanıcı akışı test etmiyor; sadece controller mantığını doğruluyor.
///
/// `flutter test integration_test/yayinlama_e2e.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StoreLocalStorageService.resetCache();

    try {
      await Supabase.instance.dispose();
    } catch (_) {}

    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-key',
      httpClient: _StubHttpClient(),
    );
  });

  tearDown(() async {
    try {
      await Supabase.instance.dispose();
    } catch (_) {}
  });

  testWidgets('yayınlama ön hazırlık akışı', (tester) async {
    final fakeSupabase = FakeSupabaseClient();

    final controller = StoreEditorController(
      storage: const StoreLocalStorageService(),
      publishService: StorePublishService(supabaseClient: fakeSupabase),
      supabaseClient: fakeSupabase,
    );
    await controller.initialize('E2E Yayın Mağazası');

    // Zorunlu alanları doldur
    controller.updateName('E2E Yayın Mağazası');
    controller.updateWhatsapp('05551234567');
    controller.updateAddress(controller.data, 'Test Adres No:1');
    controller.selectProvince(controller.data, '34', 'İstanbul');
    controller.selectDistrict(controller.data, 'Kadıköy', 'Kadıköy');
    controller.setPrivacyNoticeAcknowledged(true);
    controller.setTermsAccepted(true);
    controller.setPublicationConsentAccepted(true);

    // Yayın bilgileri henüz yok
    expect(controller.publishedInfo, isNull);

    // Yayınla
    final result = await controller.publish();

    // Başarılıysa publishedInfo dolu olmalı
    expect(result, isNotNull);
    expect(controller.publishedInfo, isNotNull);
    expect(controller.publishedInfo?.slug, 'test-store');

    controller.dispose();
  });

  testWidgets('yayınlama sonrası isim değişikliği', (tester) async {
    final fakeSupabase = FakeSupabaseClient();

    final controller = StoreEditorController(
      storage: const StoreLocalStorageService(),
      publishService: StorePublishService(supabaseClient: fakeSupabase),
      supabaseClient: fakeSupabase,
    );
    await controller.initialize('E2E Yayın');

    controller.updateName('Başlangıç');
    controller.updateWhatsapp('05551234567');
    controller.updateAddress(controller.data, 'Test Adres');
    controller.selectProvince(controller.data, '34', 'İstanbul');
    controller.selectDistrict(controller.data, 'Kadıköy', 'Kadıköy');
    controller.setPrivacyNoticeAcknowledged(true);
    controller.setTermsAccepted(true);
    controller.setPublicationConsentAccepted(true);

    await controller.publish();

    // Yayın sonrası isim değiştir
    controller.updateName('Güncellenmiş Mağaza');
    expect(controller.data.name, 'Güncellenmiş Mağaza');

    // publishedInfo hâlâ mevcut
    expect(controller.publishedInfo?.slug, 'test-store');

    controller.dispose();
  });

  testWidgets('yayınlama sonrası kategori değişikliği', (tester) async {
    final fakeSupabase = FakeSupabaseClient();

    final controller = StoreEditorController(
      storage: const StoreLocalStorageService(),
      publishService: StorePublishService(supabaseClient: fakeSupabase),
      supabaseClient: fakeSupabase,
    );
    await controller.initialize('E2E Kategori');

    controller.updateName('E2E Kategori');
    controller.updateWhatsapp('05551234567');
    controller.updateAddress(controller.data, 'Test Adres');
    controller.selectProvince(controller.data, '34', 'İstanbul');
    controller.selectDistrict(controller.data, 'Kadıköy', 'Kadıköy');
    controller.setPrivacyNoticeAcknowledged(true);
    controller.setTermsAccepted(true);
    controller.setPublicationConsentAccepted(true);

    await controller.publish();

    // Yayın sonrası kategori değiştir
    controller.selectCategory('Kuaför');
    expect(controller.data.kategori, 'Kuaför');
    expect(controller.publishedInfo, isNotNull);

    controller.dispose();
  });
}
