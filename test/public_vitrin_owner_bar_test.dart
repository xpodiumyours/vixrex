import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/home_shell_screen.dart';
import 'package:vixrex/screens/public_vitrin_screen.dart';
import 'package:vixrex/services/local_storage_keys.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

void main() {
  setUp(() {
    StoreLocalStorageService.resetCache();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Public vitrin local sahip bilgisinde düzenle barı gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.lastPublishedSlug: 'test-vitrin',
      LocalStorageKeys.lastPublishedLink: 'https://vixrex.app/v/test-vitrin',
      LocalStorageKeys.lastPublishedName: 'Test Vitrin',
      LocalStorageKeys.lastPublishedEditToken: 'token123',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PublicVitrinScreen(
          slug: 'test-vitrin',
          mockStoreData: StoreData(name: 'Test Vitrin'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vitrinin yayında'), findsOneWidget);
    expect(find.text('Yalnızca sen bu alanı görürsün'), findsOneWidget);
    expect(find.text('Düzenle'), findsOneWidget);

    await tester.tap(find.text('Düzenle'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HomeShellScreen), findsOneWidget);
    expect(find.text('Vixrex Düzenle'), findsOneWidget);
  });

  testWidgets('Public vitrin local sahip bilgisi yoksa düzenle barı gizler', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: PublicVitrinScreen(
          slug: 'test-vitrin',
          mockStoreData: StoreData(name: 'Test Vitrin'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vitrinin yayında'), findsNothing);
    expect(find.text('Düzenle'), findsNothing);
  });

  testWidgets('Public sahip paneli dar mobil ekranda taşmaz', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.lastPublishedSlug: 'test-vitrin',
      LocalStorageKeys.lastPublishedLink: 'https://vixrex.app/v/test-vitrin',
      LocalStorageKeys.lastPublishedName: 'Test Vitrin',
      LocalStorageKeys.lastPublishedEditToken: 'token123',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PublicVitrinScreen(
          slug: 'test-vitrin',
          mockStoreData: StoreData(name: 'Test Vitrin'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vitrinin yayında'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
