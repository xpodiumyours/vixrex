import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/screens/profile_screen.dart';
import 'package:vixrex/screens/vixrex_screen.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/widgets/chatbot_badge.dart';

void main() {
  testWidgets('VixRex ekranı Türkçe başlıkları gösterir', (tester) async {
    tester.view.physicalSize = const Size(1200, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: VixRexScreen(
          snapshot: const VixRexProfileSnapshot(
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
            publicLink: 'https://vixrex.com/test',
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

    expect(find.text('VixRex Rehber'), findsOneWidget);
    expect(find.text('VixRex'), findsOneWidget);
    expect(find.text('VixRex Rehberi'), findsOneWidget);
  });

  test('VixRex karşılama metni düz ve desteklenen karakterlerden oluşur', () {
    final text = ChatbotConfig.welcomeMessage.text;

    expect(text, isNot(contains('**')));
    expect(text, isNot(contains('👋')));
    expect(text, contains('Merhaba! Ben VixRex'));
  });

  testWidgets('VixRex hızlı aksiyonları dar ekranda taşmaz', (tester) async {
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
    expect(find.text('VixRex Kullanıcısı'), findsOneWidget);
  });

  testWidgets(
    'VixRex chatbot overlay shows guided step when snapshot is incomplete',
    (tester) async {
      VixRexOverlay.close();
      addTearDown(VixRexOverlay.close);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const mockSnapshot = VixRexProfileSnapshot(
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
