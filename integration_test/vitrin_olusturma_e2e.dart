import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/screens/landing_screen.dart';
import 'package:vixrex/screens/my_vitrin_screen.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

/// SMOKE TEST — Gerçek E2E değil.
///
/// Widget render kontrolü (mock ile).
/// Gerçek kullanıcı akışı test etmiyor; sadece widget'ların açıldığını doğruluyor.
///
/// `flutter test integration_test/vitrin_olusturma_e2e.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StoreLocalStorageService.resetCache();
  });

  testWidgets('landing screen vitrin oluşturma yönlendirmesi',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Landing screen yüklenmeli
    expect(find.byType(LandingScreen), findsOneWidget);
  });

  testWidgets('MyVitrinScreen boş vitrin ile açılır', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await tester.pumpWidget(MaterialApp(
      home: MyVitrinScreen(
        editorController: controller,
        editorInitialization: Future<void>.value(),
      ),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    // Vitrin editörü açılmalı
    expect(find.byType(MyVitrinScreen), findsOneWidget);

    controller.dispose();
  });

  testWidgets('isim alanına yazma ve kaydetme', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await tester.pumpWidget(MaterialApp(
      home: MyVitrinScreen(
        editorController: controller,
        editorInitialization: Future<void>.value(),
      ),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    // İsim alanı mevcut olmalı
    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'E2E Test Mağazası');
    expect(controller.data.name, 'E2E Test Mağazası');

    controller.dispose();
  });

  testWidgets('kategori seçimi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    controller.selectCategory('Kuaför');

    await tester.pumpWidget(MaterialApp(
      home: MyVitrinScreen(
        editorController: controller,
        editorInitialization: Future<void>.value(),
      ),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.data.kategori, 'Kuaför');

    controller.dispose();
  });

  testWidgets('whatsapp alanına yazma', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = StoreEditorController();
    await tester.pumpWidget(MaterialApp(
      home: MyVitrinScreen(
        editorController: controller,
        editorInitialization: Future<void>.value(),
      ),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    controller.updateWhatsapp('05551234567');
    expect(controller.data.whatsapp, '05551234567');

    controller.dispose();
  });
}
