import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/main.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/home_shell_screen.dart';
import 'package:vixrex/screens/landing_screen.dart';
import 'package:vixrex/screens/my_vitrin_screen.dart';
import 'package:vixrex/services/local_storage_keys.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vixrex/config/app_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() async {
    StoreLocalStorageService.resetCache();
    SharedPreferences.setMockInitialValues({});
    final mockClient = MockClient((request) async {
      final urlStr = request.url.toString();
      if (urlStr.contains('legal_documents')) {
        String docType = 'privacy';
        if (urlStr.contains('terms')) docType = 'terms';
        if (urlStr.contains('consent')) docType = 'consent';
        return http.Response(
          jsonEncode({
            'document_type': docType,
            'version': '$docType-2026-07-05',
            'title': docType == 'privacy'
                ? 'Gizlilik'
                : (docType == 'terms' ? 'Kullanım Koşulları' : 'Açık Rıza'),
            'subtitle': '',
            'content_hash': 'hash',
            'sections': [],
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '[]',
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    });

    try {
      await Supabase.instance.dispose();
    } catch (_) {}

    await Supabase.initialize(
      url: 'https://dummyproject.supabase.co',
      anonKey: 'dummyAnonKey',
      httpClient: mockClient,
    );
  });

  tearDown(() async {
    try {
      await Supabase.instance.dispose();
    } catch (_) {}
  });

  testWidgets('Vixrex ilk açılışta karşılama ekranını gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VixRexApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text('Vixrex Oluştur'), findsAtLeastNWidgets(1));
  });

  testWidgets('HomeShell Vitrinim hızlı yayın ekranını gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(home: HomeShellScreen(initialIndex: 0)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Keşfet'), findsOneWidget);
    expect(find.text('Vitrinim'), findsOneWidget);
    expect(find.text('Vixrex Oluştur'), findsAtLeastNWidgets(1));
    expect(find.text('Vitrinimi Yayına Al'), findsOneWidget);
  });

  testWidgets('Geçersiz route karşılama ekranına düşer', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VixRexApp());
    await tester.pump();

    AppRouter.router.go('/app/gecersiz-route');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LandingScreen), findsAtLeastNWidgets(1));
  });

  testWidgets('Landing pasif yakında butonlarını göstermez', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.storeData: jsonEncode(
        StoreData(name: 'Kayıtlı İşletme', isStore: true).toJson(),
      ),
    });

    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Yakında'), findsNothing);
    expect(find.text('Vitrinleri Keşfet'), findsAtLeastNWidgets(1));
  });

  testWidgets('Vitrinim yayınlanmış vitrini aynı sayfada düzenletir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.vitrinData: jsonEncode(
        StoreData(name: 'Kayitli Vitrin', description: 'Vitrin').toJson(),
      ),
      LocalStorageKeys.lastPublishedSlug: 'kayitli-vitrin',
      LocalStorageKeys.lastPublishedLink:
          'https://vixrex-public.vercel.app/v/kayitli-vitrin',
      LocalStorageKeys.lastPublishedName: 'Kayitli Vitrin',
      LocalStorageKeys.lastPublishedEditToken: 'token123',
    });

    await tester.pumpWidget(const MaterialApp(home: MyVitrinScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Vixrex Düzenle'), findsOneWidget);
    expect(find.text('Vixrex Oluştur'), findsNothing);
    expect(find.text('Değişiklikleri Kaydet & Yayına Al'), findsOneWidget);
    expect(find.text('İşletme / Vixrex Adı'), findsOneWidget);
    expect(find.text('Yayındaki Vitrini Aç'), findsOneWidget);
    expect(find.text('Linki Kopyala'), findsOneWidget);
    expect(find.text('QR Göster'), findsOneWidget);
  });
}
