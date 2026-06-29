import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/config/chatbot_config.dart';
import 'package:vitrinx/screens/profile_screen.dart';
import 'package:vitrinx/screens/xrex_screen.dart';
import 'package:vitrinx/widgets/chatbot_overlay.dart';

void main() {
  testWidgets('X-rex ekranı Türkçe başlıkları gösterir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: XrexScreen()));

    expect(find.text('X-rex Yapay Zekâ'), findsOneWidget);
    expect(find.text('VitrinX Yapay Zekâ Asistanı'), findsOneWidget);
    expect(find.text('Yakında'), findsNWidgets(3));
  });

  test('X-rex karşılama metni düz ve desteklenen karakterlerden oluşur', () {
    final text = ChatbotConfig.welcomeMessage.text;

    expect(text, isNot(contains('**')));
    expect(text, isNot(contains('👋')));
    expect(text, contains('Merhaba! Ben Xrex'));
  });

  testWidgets('X-rex hızlı aksiyonları dar ekranda taşmaz', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: ChatbotBadge()))),
    );
    await tester.tap(find.byType(ChatbotBadge));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Üyelik / Kullanım'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profil ekranı Türkçe başlığı gösterir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('VitrinX Kullanıcısı'), findsOneWidget);
  });
}
