import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:http/http.dart' as http;

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
/// `flutter test integration_test/asistan_e2e.dart`
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

  testWidgets('asistan isim değişikliği e2e', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await controller.initialize('Eski İsim');

    // Asistan komutu simüle et
    controller.updateName('Asistan Yeni İsim');

    expect(controller.data.name, 'Asistan Yeni İsim');

    // UI'da da görünmeli
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Text(controller.data.name),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Asistan Yeni İsim'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('asistan kategori değişikliği e2e', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await controller.initialize('Test');

    controller.selectCategory('Kafe & Lokanta');

    expect(controller.data.kategori, 'Kafe & Lokanta');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Text(controller.data.kategori),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Kafe & Lokanta'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('asistan çoklu alan değişikliği e2e', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await controller.initialize('Boş');

    controller.updateName('Yeni Mağaza');
    controller.selectCategory('Kuaför');
    controller.updateWhatsapp('05551112233');
    controller.setDescription('Asistan açıklaması');

    expect(controller.data.name, 'Yeni Mağaza');
    expect(controller.data.kategori, 'Kuaför');
    expect(controller.data.whatsapp, '05551112233');
    expect(controller.data.description, 'Asistan açıklaması');

    controller.dispose();
  });
}
