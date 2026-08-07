import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/screens/landing_screen.dart';

/// SMOKE TEST — Gerçek E2E değil.
///
/// Widget smoke kontrolü.
///
/// VM: `flutter test integration_test/smoke_landing_boots_test.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('landing screen boots and shows brand cue', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Vixrex', findRichText: true), findsWidgets);
  });
}
