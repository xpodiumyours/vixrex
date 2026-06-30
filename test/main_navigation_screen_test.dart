import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitrinx/config/chatbot_config.dart';
import 'package:vitrinx/screens/profile_screen.dart';
import 'package:vitrinx/screens/xrex_screen.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';
import 'package:vitrinx/widgets/chatbot_overlay.dart';

void main() {
  testWidgets('X-rex ekranı Türkçe başlıkları gösterir', (tester) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: XrexScreen(
          snapshot: const XrexProfileSnapshot(
            nameCompleted: true,
            whatsappCompleted: true,
            addressCompleted: true,
            legalCompleted: true,
            coverCompleted: true,
            galleryCompleted: true,
            descriptionCompleted: true,
            catalogCompleted: true,
            isPublished: true,
            storeName: 'Test Mağazası',
            category: 'Kategori',
            district: 'İlçe',
            publicLink: 'https://vitrinx.com/test',
          ),
          hasShared: false,
          dismissedRecommendationId: null,
          onAction: (_) {},
          onDismissRecommendation: (_) {},
          onCopyPromotionText: (_) {},
          onSharePromotionText: (_) {},
        ),
      ),
    );

    expect(find.text('X-rex Rehber'), findsOneWidget);
    expect(find.text('X-rex'), findsOneWidget);
    expect(find.text('VitrinX Rehberi'), findsOneWidget);
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

  testWidgets(
    'X-rex chatbot overlay shows guided step when snapshot is incomplete',
    (tester) async {
      XrexOverlay.close();
      addTearDown(XrexOverlay.close);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const mockSnapshot = XrexProfileSnapshot(
        nameCompleted: false,
        whatsappCompleted: false,
        addressCompleted: false,
        legalCompleted: false,
        coverCompleted: false,
        galleryCompleted: false,
        descriptionCompleted: false,
        catalogCompleted: false,
        isPublished: false,
        storeName: '',
        category: '',
        district: '',
        publicLink: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: ChatbotBadge(snapshot: mockSnapshot)),
          ),
        ),
      );

      await tester.tap(find.byType(ChatbotBadge));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('İşletme Adı Ekle'), findsOneWidget);
    },
  );
}
