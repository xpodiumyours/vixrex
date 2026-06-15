import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/models/store_data.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';
import 'package:vitrinx/services/local_storage_keys.dart';

void main() {
  testWidgets('Public vitrin local sahip bilgisinde düzenle barı gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.lastPublishedSlug: 'test-vitrin',
      LocalStorageKeys.lastPublishedLink: 'https://vitrinx.app/v/test-vitrin',
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

    expect(find.text('Bu senin vitrinin'), findsOneWidget);
    expect(find.text('Düzenle'), findsOneWidget);
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

    expect(find.text('Bu senin vitrinin'), findsNothing);
    expect(find.text('Düzenle'), findsNothing);
  });
}
