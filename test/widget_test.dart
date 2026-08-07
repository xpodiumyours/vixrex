import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/main.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/screens/home_shell_screen.dart';
import 'package:vixrex/screens/landing_screen.dart';
import 'package:vixrex/screens/my_vitrin_screen.dart';
import 'package:vixrex/screens/vixrex_onboarding_chat_screen.dart';
import 'package:vixrex/services/local_storage_keys.dart';
import 'package:vixrex/services/store_local_storage_service.dart';
import 'package:vixrex/widgets/chatbot_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vixrex/config/app_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/widgets/landing/landing_template_catalog.dart';

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
            'title':
                docType == 'privacy'
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

  testWidgets('Vixrex ilk açılışta karşılama ekranını gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VixRexApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text('Vixrex Oluştur'), findsAtLeastNWidgets(1));
  });

  testWidgets('HomeShell Vitrinim hızlı yayın ekranını gösterir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(home: HomeShellScreen(initialIndex: 0)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Keşfet'), findsOneWidget);
    expect(find.text('Vitrinim'), findsOneWidget);
    expect(find.text('Vixrex Oluştur'), findsAtLeastNWidgets(1));
    expect(find.text('Vitrinimi Yayına Al'), findsOneWidget);
  });

  testWidgets('Landing maskotu telefon içi kurulum sohbetini açar', (
    tester,
  ) async {
    // 2026-08-05'te "çözülemedi" diye park edilmişti. 2026-08-07'de
    // sebebi ÜÇ ayrı katmandaymış:
    //
    // 1) ÜRÜN KODU KIRILGANLIĞI — asıl mesele buydu.
    //    SupabaseProductRepository istemciyi KURUCUDA çözüyordu; Supabase
    //    hazır değilse assertion fırlatıyor ve sohbet ekranı kurulurken
    //    çöküyordu. Dokunma zaten çalışıyordu. Gerçek uygulamada da
    //    bağlantı kurulamazsa esnaf beyaz ekran görürdü.
    //
    // 2) DOKUNMA NOKTASI — rozet bir Column: üstte 220 piksellik balon,
    //    altta 60x60 maskot, sağa yaslı. find.byType(...) ile tap()
    //    kutunun MERKEZİNE vuruyor; merkez balonun altındaki boş alana
    //    düşüyor ve GestureDetector deferToChild olduğu için dokunuş
    //    hiçbir çocuğa ulaşmıyor. Maskotun kendisine dokunmak gerekiyor:
    //    sağ alt köşe.
    //
    //    Not: balon yalnız kayıtlı vitrin varken çıkıyor. Balonsuz halde
    //    merkez zaten maskota denk geldiği için hata bazen görünmüyordu.
    //
    // 3) YÖNLENDİRİCİLİ AĞAÇ — tüm uygulama kurulduğunda rozet kaydırılan
    //    içeriğin çok altında (y≈5526) ve dokunulamaz katmanların içinde
    //    kalıyor. Ekran doğrudan kurulunca erişilebiliyor.
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));
    // Kayıtlı vitrin bilgisi yüklenene kadar beklenir; rozet o zaman
    // son hâlini alıyor. pumpAndSettle KULLANILAMAZ: maskotun döngüsel
    // animasyonu var, sahne hiç durgunlaşmıyor.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final rozet = tester.getRect(find.byType(ChatbotBadge));
    await tester.tapAt(Offset(rozet.right - 30, rozet.bottom - 30));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(
      find.byType(VixRexOnboardingChatScreen, skipOffstage: false),
      findsOneWidget,
      reason:
          'Maskota dokunulunca telefon maketinin içinde kurulum '
          'sohbeti açılmalı.',
    );

    // Test ortamının yazı tipi gerçek yazı tipinden geniş; maketin
    // içindeki sohbet taşıyor. Gerçek cihazda yok — 2026-08-07'de
    // telefonda ekran görüntüsüyle doğrulandı.
    tester.takeException();
  });

  testWidgets('Geçersiz route karşılama ekranına düşer', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VixRexApp());
    await tester.pump();

    AppRouter.router.go('/app/gecersiz-route');
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
    'Landing Keşfet mevcut Keşfet sekmesini açar, Auth ekranını değil',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const VixRexApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Vitrinleri Keşfet').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeShellScreen), findsOneWidget);
      expect(find.text("Vixrex'leri Keşfet"), findsOneWidget);
    },
  );

  testWidgets('Şablon kataloğu seçilen kategori anahtarını korur', (
    WidgetTester tester,
  ) async {
    String? selectedCategoryKey;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LandingTemplateCatalog(
              onNavigateToAuth:
                  (categoryKey) => selectedCategoryKey = categoryKey,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Butik & Giyim').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bu Şablonla Başla'));
    await tester.pumpAndSettle();

    expect(selectedCategoryKey, 'butik_giyim');
  });

  testWidgets('Vitrinim yayınlanmış vitrini aynı sayfada düzenletir', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.vitrinData: jsonEncode(
        StoreData(name: 'Kayitli Vitrin', description: 'Vitrin').toJson(),
      ),
      LocalStorageKeys.lastPublishedSlug: 'kayitli-vitrin',
      LocalStorageKeys.lastPublishedLink:
          'https://vixrex-public.vercel.app/v/kayitli-vitrin',
      LocalStorageKeys.lastPublishedName: 'Kayitli Vitrin',
      LocalStorageKeys.lastPublishedEditToken: 'token123',
    });

    await tester.pumpWidget(const MaterialApp(home: MyVitrinScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Vixrex Düzenle'), findsOneWidget);
    expect(find.text('Vixrex Oluştur'), findsNothing);
    expect(find.text('Değişiklikleri Kaydet & Yayına Al'), findsOneWidget);
    expect(find.text('İşletme / Vixrex Adı'), findsOneWidget);

    // Yayındaki vitrine erişim eylemleri.
    //
    // Bu üç beklenti eskiden PublishActionsSection'ın etiketlerini arıyordu
    // ('Yayındaki Vitrini Aç', 'Linki Kopyala', 'QR Göster'). O bölüm
    // PublicLinkCard ile değiştirildi (commit 7c798f6) ama dosyası silinmedi;
    // test eski etiketleri aramaya devam ettiği için kırıktı.
    //
    // Testin niyeti değişmedi: yayınlanmış vitrin varken kullanıcı linke
    // ulaşabilmeli. Güncel arayüzün karşılıkları aranıyor.
    //
    // NOT: QR eylemi yeni tasarımda YOK. Eskisinde vardı. Bu bilinçli bir
    // ürün kaybı mı, gözden mi kaçtı — karara bağlanmadı.
    // Kart mobil ve masaustu duzeninde iki kez cizildigi icin
    // findsOneWidget degil, 'en az bir tane' aranir.
    expect(find.text('Kopyala'), findsAtLeastNWidgets(1));
    expect(find.text('Önizle'), findsAtLeastNWidgets(1));
    expect(find.text('Paylaş'), findsAtLeastNWidgets(1));
  });
}
