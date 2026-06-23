import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitrinx/main.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/home_shell_screen.dart';
import 'package:vitrinx/screens/landing_screen.dart';
import 'package:vitrinx/screens/my_vitrin_screen.dart';
import 'package:vitrinx/screens/vitrin_editor_screen.dart';
import 'package:vitrinx/services/local_storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  testWidgets('VitrinX ilk açılışta karşılama ekranını gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VitrinXApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text('VitrinX Oluştur'), findsAtLeastNWidgets(1));
  });

  testWidgets('HomeShell Vitrinim hızlı yayın ekranını gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(home: HomeShellScreen(initialIndex: 1)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Keşfet'), findsOneWidget);
    expect(find.text('Vitrinim'), findsOneWidget);
    expect(find.text('VitrinX Oluştur'), findsAtLeastNWidgets(1));
    expect(find.text('Vitrinimi Yayına Al'), findsOneWidget);
  });

  testWidgets('Geçersiz route karşılama ekranına düşer', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VitrinXApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/gecersiz-route');
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

  testWidgets(
    'VitrinEditorScreen kategori ve ürün kataloğunu içermez ama pazaryeri linklerini içerir',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: VitrinEditorScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Kategori'), findsNothing);
      expect(find.text('Ürün Kataloğu'), findsNothing);
      expect(find.text('Pazaryeri Linkleri'), findsOneWidget);
      expect(find.text('Yayınla'), findsNothing);
    },
  );

  testWidgets('Vitrinim yayınlanmış vitrini aynı sayfada düzenletir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.vitrinData: jsonEncode(
        StoreData(name: 'Kayitli Vitrin', description: 'Vitrin').toJson(),
      ),
      LocalStorageKeys.lastPublishedSlug: 'kayitli-vitrin',
      LocalStorageKeys.lastPublishedLink:
          'https://vitrinx.app/v/kayitli-vitrin',
      LocalStorageKeys.lastPublishedName: 'Kayitli Vitrin',
      LocalStorageKeys.lastPublishedEditToken: 'token123',
    });

    await tester.pumpWidget(const MaterialApp(home: MyVitrinScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('VitrinX Düzenle'), findsOneWidget);
    expect(find.text('VitrinX Oluştur'), findsNothing);
    expect(find.text('Değişiklikleri Kaydet & Yayına Al'), findsOneWidget);
    expect(find.text('İşletme / VitrinX Adı'), findsOneWidget);
    expect(find.text('Yayındaki Vitrini Aç'), findsOneWidget);
    expect(find.text('Linki Kopyala'), findsOneWidget);
    expect(find.text('QR Göster'), findsOneWidget);
  });
}
