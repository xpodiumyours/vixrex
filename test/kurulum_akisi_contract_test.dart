import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kurulum akışının bekçisi.
///
/// NEDEN VAR: geçmişte bir düzenleme sırasında karşılama ekranındaki
/// vitrin oluşturma yolu silindi ve kimse fark etmedi. Bu dosya o yolların
/// var olduğunu doğrular — biri kaldırırsa test kırmızı olur.
///
/// Bunlar DAVRANIŞ değil VARLIK testleridir: ekran çalıştırmaz, kaynak
/// dosyada aranan yapının durduğuna bakar. Ucuz ve hızlıdır; asıl işi
/// "yanlışlıkla silinmesini" engellemektir.
void main() {
  final root = Directory.current.path;
  String read(String path) => File('$root/$path').readAsStringSync();

  group('Karşılama ekranında vitrin oluşturma yolları duruyor', () {
    // Üç ayrı giriş var. Herhangi biri silinirse esnafın bir kısmı
    // vitrin oluşturamaz hale gelir.
    late final String landing = read('lib/screens/landing_screen.dart');

    test('maskot düğmesi ve kurulum sohbeti duruyor', () {
      expect(landing, contains('ChatbotBadge('));
      expect(landing, contains('onOpen: _openMockupChat'));
    });

    test('alttaki çağrı düğmesi editöre götürüyor', () {
      expect(landing, contains('LandingBottomCta('));
      expect(landing, contains('_navigateToEditor'));
    });

    test('maskot sayfanın son satırlarını kapatmıyor', () {
      // 2026-08-07: maskot sağ altta yüzüyor ve içeriğin üstünde duruyor.
      // Bu boşluk olmadan sayfanın sonu maskotun altında kalıyordu.
      expect(landing, contains('SizedBox(height: 96)'));
    });

    test('şablon kataloğu duruyor', () {
      expect(landing, contains('LandingTemplateCatalog('));
    });
  });

  group('Kurulum sohbetinin adımları eksilmiyor', () {
    late final String chat = read(
      'lib/screens/vixrex_onboarding_chat_screen.dart',
    );
    // Faz D (Tek Asistan planı): adım makinesi, doğrulama ve kaydetme
    // çağrıları `vixrex_onboarding_controller.dart`'a, kategori ızgarası
    // `widgets/onboarding/kategori_secici.dart`'a taşındı. Bu testler artık
    // davranışın GERÇEKTEN yaşadığı dosyaya bakar — ekrana değil.
    late final String controller = read(
      'lib/controllers/vixrex_onboarding_controller.dart',
    );
    late final String kategoriIzgarasi = read(
      'lib/widgets/onboarding/kategori_secici.dart',
    );

    test('yedi adımın hepsi tanımlı', () {
      // Yeni adım EKLENMESİ bu testi kırmaz; yalnız mevcutların
      // kaybolması kırar. Bu yüzden sayı değil, varlık kontrol edilir.
      for (final adim in [
        'welcome',
        'name',
        'category',
        'whatsapp',
        'location',
        'legal',
        'publishing',
        'done',
      ]) {
        expect(controller, contains(adim), reason: '$adim adımı kaybolmuş');
      }
    });

    test('ad, WhatsApp ve konum girişleri duruyor', () {
      expect(controller, contains('submitName'));
      expect(controller, contains('submitWhatsapp'));
      expect(controller, contains('submitLocationText'));
    });

    test('kategori adımı sohbetin içinde, ayrı ekrana götürmüyor', () {
      // Kategori şemada zorunlu; sorulmazsa vitrin 'Diğer' kalıyor ve
      // kategoriye bağlı hiçbir şey çalışmıyor. Seçim sohbetin içinde
      // yapılır — kullanıcı başka ekrana atılmaz.
      expect(controller, contains('selectCategory'));
      expect(kategoriIzgarasi, contains('BusinessCategoryConfig.categories'));
      expect(chat, contains('KategoriSecici('));
    });

    test('kategori seçimi ikili ızgara, gizli kaydırma kutusu yok', () {
      // 2026-08-07: kategoriler `Wrap` ile diziliyordu; satırlar 5/3/3/2/2
      // diye kırılıyor, kutular farklı genişlikte çıkıyordu. Üstelik 220
      // piksellik gizli bir kaydırma kutusu vardı — 19 kategorinin 5'i hiç
      // görünmüyor, kaydırılabildiğine dair işaret de yoktu.
      //
      // Casper'ın ifadesi: "bu kategori çekmesi hiç UI UX mu deniyor artık".
      expect(
        kategoriIzgarasi,
        contains('SliverGridDelegateWithFixedCrossAxisCount'),
      );
      expect(kategoriIzgarasi, contains('crossAxisCount: 2'));
      // Izgara sohbetin altındaki sabit panelde; yükseklik sınırı kalmalı
      // (yoksa taşar). Ama devamı olduğu GÖRÜNMELİ — alttaki solma bunu
      // söyler. Solma kaldırılırsa 5 kategori yine görünmez olur.
      expect(
        kategoriIzgarasi,
        contains('ShaderMask'),
        reason:
            'Alttaki solma kaldırılmış; kategorilerin devamı olduğu '
            'anlaşılmaz, esnaf 5 kategoriyi hiç göremez.',
      );
    });

    test('konum düğmesi zorunlu alanlar eksikken pasif', () {
      // 2026-08-07: doğrulama vardı ve boş alanla geçmiyordu, ama düğme
      // hazır görünüyordu. Casper: "zorunluluk işareti var, karşılığı yok".
      // Aynı kural hem düğmenin görünümünü hem geçişi belirlemeli.
      expect(controller, contains('konumEksigi'));
      expect(chat, contains('Devam etmek için:'));
    });

    test('kurulum sonunda tek kapı var', () {
      // 2026-08-07 (bulgu 8): iki düğme aynı sayfayı açıyordu — biri
      // "Canlı vitrini aç", diğeri "Vitrinimi birlikte düzenleyelim".
      // Esnaf önce bakıp geri dönüyor, sonra ikincisine basıyordu.
      //
      // Artık asıl kapı tek: "Vitrinini aç" (sahip modunda). Diğeri
      // ikincil ve işi değişti — müşterinin gördüğü hâli göstermek
      // (bulgu 7).
      expect(chat, contains("'Vitrinini aç'"));
      expect(chat, contains('Müşterinin gördüğü hâli'));
      expect(
        // Dart dizisi olarak aranır; açıklama satırındaki geçiş sayılmaz.
        chat.contains("'Canlı vitrini aç'"),
        isFalse,
        reason:
            'İkinci birincil kapı geri gelmiş; esnaf yine iki kez '
            'yolculuk yapar.',
      );
    });

    test('kurulum sonrası asistan devri duruyor', () {
      // 2026-08-06 tek asistan kararı: kurulum bitince aynı Vixrex
      // vitrini sahip modunda açar. Bu kaldırılırsa sert devir geri gelir.
      expect(controller, contains('openOwnerWorkspace'));
      expect(chat, contains('_onboarding.openOwnerWorkspace'));
    });

    test('manuel form paneline giden ikincil yol duruyor', () {
      // VIXREX_RULES §1: manuel üyelik paneli taşınmaz, silinmez.
      // Çevrimdışı ve toplu iş yolu odur.
      expect(chat, contains('_navigateAfterHandoff'));
    });
  });

  group('Yasal onay atlanamıyor', () {
    late final String chat = read(
      'lib/screens/vixrex_onboarding_chat_screen.dart',
    );

    test('yasal onay adımı ve bölümü akışta duruyor', () {
      // Onaysız yayın hem KVKK açısından yanlış, hem de veritabanı
      // tetikleyicisi zaten reddediyor (PUBLICATION_CONSENT_REQUIRED).
      // Buradan kaldırılırsa kullanıcı sebebini anlamayan bir hataya düşer.
      expect(chat, contains('LegalConsentSection'));
      expect(chat, contains('VixRexOnboardingStep.legal'));
    });
  });

  group('Kategoriler ve şablon kataloğu duruyor', () {
    late final String kategoriler = read(
      'lib/widgets/landing/landing_template_category.dart',
    );
    late final List<Map<String, dynamic>> kanonik =
        ((jsonDecode(read('shared/business_categories.json'))
                    as Map<String, dynamic>)['categories']
                as List<dynamic>)
            .cast<Map<String, dynamic>>();

    test('katalog yalnız aktif kategorileri taşır', () {
      for (final kategori in kanonik) {
        expect(
          kategoriler.contains("'${kategori['id']}'"),
          kategori['aktif'] == true,
          reason:
              '${kategori['id']} kutusu aktif durumuyla uyuşmuyor '
              '(shared/business_categories.json tek kaynak)',
        );
      }
    });

    test('kutu sayısı aktif kategori sayısıyla aynı', () {
      final adet = RegExp(r'TemplateCategory\(').allMatches(kategoriler).length;
      final aktif = kanonik.where((k) => k['aktif'] == true).length;
      expect(adet, aktif + 1);
    });
  });
}
