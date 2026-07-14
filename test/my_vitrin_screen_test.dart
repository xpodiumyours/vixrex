import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/screens/my_vitrin_screen.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

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

  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyVitrinScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> selectKuaforAndEnableBooking(WidgetTester tester) async {
    final categoryFinder = find.text('Diğer').first;
    await tester.ensureVisible(categoryFinder);
    await tester.pumpAndSettle();
    await tester.tap(categoryFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kuaför').last);
    await tester.pumpAndSettle();

    final bookingTitle = find.textContaining('Randevu Ayarları');
    await tester.ensureVisible(bookingTitle);
    await tester.tap(bookingTitle);
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    if (switchFinder.evaluate().isNotEmpty) {
      final Switch switchWidget = tester.widget<Switch>(switchFinder.last);
      if (!switchWidget.value) {
        await tester.tap(switchFinder.last);
        await tester.pumpAndSettle();
      }
    }
  }

  testWidgets('Profil formunda Öne Çıkanlar bölümü gösterilmez', (
    WidgetTester tester,
  ) async {
    await pumpEditor(tester);

    expect(find.text('Öne Çıkanlar'), findsNothing);
    expect(find.text('Menüden Öne Çıkanlar'), findsNothing);
    expect(find.text('Randevu Hizmetleri'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('Yasal yayınlama paneli gösterilir', (WidgetTester tester) async {
    await pumpEditor(tester);

    expect(find.text('Yasal Bilgilendirme ve Yayınlama Onayı'), findsOneWidget);
    expect(
      find.textContaining('Taslağınızı onay vermeden'),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('Randevu hizmeti önerisi eklenir ve tekrar eklenemez', (
    WidgetTester tester,
  ) async {
    await pumpEditor(tester);
    await selectKuaforAndEnableBooking(tester);

    expect(find.text('Randevu Hizmetleri'), findsOneWidget);

    final chipFinder = find.textContaining('Saç Kesimi & Yıkama').first;
    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.text('Saç Kesimi & Yıkama'), findsOneWidget);

    await tester.tap(chipFinder);
    await tester.pump();

    expect(find.text('Bu hizmet zaten eklenmiş.'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Randevu hizmeti önerisi süre bilgisini korur', (
    WidgetTester tester,
  ) async {
    await pumpEditor(tester);
    await selectKuaforAndEnableBooking(tester);

    final chipFinder = find.textContaining('Saç Kesimi & Yıkama').first;
    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pump();

    final dropdownValues =
        tester
            .widgetList<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .map((dropdown) => dropdown.value)
            .toList();
    expect(dropdownValues, contains(45));
    await tester.pumpAndSettle();
  });
}
