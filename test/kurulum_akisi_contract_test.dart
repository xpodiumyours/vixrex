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

    test('şablon kataloğu duruyor', () {
      expect(landing, contains('LandingTemplateCatalog('));
    });
  });

  group('Kurulum sohbetinin adımları eksilmiyor', () {
    late final String chat = read(
      'lib/screens/vixrex_onboarding_chat_screen.dart',
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
        expect(chat, contains(adim), reason: '$adim adımı kaybolmuş');
      }
    });

    test('ad, WhatsApp ve konum girişleri duruyor', () {
      expect(chat, contains('_submitName'));
      expect(chat, contains('_submitWhatsapp'));
      expect(chat, contains('_submitLocationText'));
    });

    test('kategori adımı sohbetin içinde, ayrı ekrana götürmüyor', () {
      // Kategori şemada zorunlu; sorulmazsa vitrin 'Diğer' kalıyor ve
      // kategoriye bağlı hiçbir şey çalışmıyor. Seçim sohbetin içinde
      // yapılır — kullanıcı başka ekrana atılmaz.
      expect(chat, contains('_selectCategory'));
      expect(chat, contains('BusinessCategoryConfig.categories'));
    });

    test('kategori seçimi ikili ızgara, gizli kaydırma kutusu yok', () {
      // 2026-08-07: kategoriler `Wrap` ile diziliyordu; satırlar 5/3/3/2/2
      // diye kırılıyor, kutular farklı genişlikte çıkıyordu. Üstelik 220
      // piksellik gizli bir kaydırma kutusu vardı — 19 kategorinin 5'i hiç
      // görünmüyor, kaydırılabildiğine dair işaret de yoktu.
      //
      // Casper'ın ifadesi: "bu kategori çekmesi hiç UI UX mu deniyor artık".
      expect(chat, contains('SliverGridDelegateWithFixedCrossAxisCount'));
      expect(chat, contains('crossAxisCount: 2'));
      // Izgara sohbetin altındaki sabit panelde; yükseklik sınırı kalmalı
      // (yoksa taşar). Ama devamı olduğu GÖRÜNMELİ — alttaki solma bunu
      // söyler. Solma kaldırılırsa 5 kategori yine görünmez olur.
      expect(
        chat,
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
      expect(chat, contains('_konumEksigi'));
      expect(chat, contains('Devam etmek için:'));
    });

    test('kurulum sonrası asistan devri duruyor', () {
      // 2026-08-06 tek asistan kararı: kurulum bitince aynı Vixrex
      // vitrini sahip modunda açar. Bu kaldırılırsa sert devir geri gelir.
      expect(chat, contains('_openOwnerWorkspace'));
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
      expect(chat, contains('_OnboardingStep.legal'));
    });
  });

  group('Kategoriler ve şablon kataloğu duruyor', () {
    late final String kategoriler = read(
      'lib/widgets/landing/landing_template_category.dart',
    );

    test('19 kategori kutusunun hepsi duruyor', () {
      for (final anahtar in [
        'butik_giyim',
        'kuafor_guzellik',
        'kafe_restoran',
        'teknik_servis',
        'butik',
        'kozmetik',
        'elektronik',
        'kirtasiye',
        'pet_shop_veteriner',
        'hizmet_danismanlik',
        'egitim_ders',
        'ev_temizlik',
      ]) {
        expect(kategoriler, contains(anahtar), reason: '$anahtar silinmiş');
      }
    });

    test('kutu sayısı azalmamış', () {
      final adet = RegExp('TemplateCategory\\(').allMatches(kategoriler).length;
      // 20 kutu + sınıfın kendi kurucusu = 21
      expect(adet, greaterThanOrEqualTo(21));
    });
  });
}
