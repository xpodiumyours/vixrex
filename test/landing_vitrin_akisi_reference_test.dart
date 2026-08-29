import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/screens/landing_screen.dart';
import 'package:vixrex/screens/vixrex_onboarding_chat_screen.dart';
import 'package:vixrex/services/store_local_storage_service.dart';

void main() {
  testWidgets(
    'landing düğmesi asistanı açar ve işletme adını sonraki adıma taşır',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      StoreLocalStorageService.resetCache();
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      await tester.enterText(
        find.widgetWithText(TextField, 'isletmeniz'),
        'Ada Kahve',
      );
      await tester.tap(find.text('Ücretsiz Vitrinimi Hazırla'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(find.byType(VixRexOnboardingChatScreen), findsOneWidget);
      expect(
        find.textContaining('Tekrar hoş geldin, Ada Kahve'),
        findsOneWidget,
      );
    },
  );
}
