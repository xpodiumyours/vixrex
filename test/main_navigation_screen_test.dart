import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/config/chatbot_config.dart';
import 'package:vixrex/screens/profile_screen.dart';
import 'package:vixrex/screens/vixrex_screen.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/widgets/chatbot_badge.dart';
import 'package:vixrex/widgets/vixrex/vixrex_hero.dart';

void main() {
  testWidgets('Vixrex ekranı Türkçe başlıkları gösterir', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
          onSaveField: (_, __) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vixrex'), findsWidgets);
    expect(find.text('SIRADAKİ ADIM'), findsOneWidget);
    expect(find.text('Vitrin araçları'), findsNothing);

    await tester.tap(find.byType(VixRexHero));
    await tester.pump();
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.focusNode?.hasFocus, isTrue);
  });

  test('Vixrex karşılama metni düz ve desteklenen karakterlerden oluşur', () {
    final text = ChatbotConfig.welcomeMessage.text;

    expect(text, isNot(contains('**')));
    expect(text, isNot(contains('👋')));
    expect(text, contains('Merhaba! Ben Vixrex'));
  });

  testWidgets('ChatbotBadge onOpen tek kapıyı çağırır, overlay açmaz', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ChatbotBadge(onOpen: () => opened = true)),
        ),
      ),
    );
    await tester.tap(find.byType(ChatbotBadge));
    await tester.pump();

    expect(opened, isTrue);
    expect(find.text('Üyelik / Kullanım'), findsNothing);
    expect(find.text('İşletme Adı Ekle'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profil ekranı Türkçe başlığı gösterir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Vixrex Kullanıcısı'), findsOneWidget);
  });
}
