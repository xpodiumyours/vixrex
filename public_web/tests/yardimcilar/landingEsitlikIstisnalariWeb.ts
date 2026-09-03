/**
 * Web landing'inde OLUP Flutter'da BİLEREK olmayan metinler.
 *
 * Kural basit: Web'deki her kullanıcı metni Flutter'da da bulunmalı;
 * bulunmayan her metin ya Flutter'a eklenmeli ya da BURAYA gerekçesiyle
 * yazılmalı. Üçüncü seçenek yok — sessizce ayrışmak mümkün değil.
 *
 * Liste bayatlarsa da test kırılır: burada olup web'de artık bulunmayan
 * bir metin, temizlenmemiş istisna demektir ve gerçek bir ayrışmayı
 * gizleyebilir.
 *
 * Bu dosya, landingEsitlikIstisnalari.ts'nin ayna karşılığıdır.
 * İkisini karıştırma: biri "Flutter'da var, webde yok" (diğer dosya),
 * diğeri "Web'de var, Flutter'da yok" (bu dosya).
 */

type Istisna = { metin: string; neden: string };

const DINAMIK_URETIM =
  "Flutter'da bu metin profil verisinden dinamik üretiliyor (ör. '" +
  "${profile.links.length} bağlantı'). Sabit yazı olmadığı için çıkarıcı " +
  "bulamıyor; web'de ise sabit olarak yazılı.";

const ERISEBILIRLIK =
  "Ekran okuyucu etiketi (aria-label), gözle görünen metin değil. Flutter'da " +
  "erişilebilirlik farklı bir mekanizmayla sağlanıyor.";

const KONUM_WEB_OZEL =
  "Web landing'i konumu tarayıcının `navigator.geolocation` özelliğiyle " +
  "alıyor; Flutter landing'inde konum adımı YOK — orada konum vitrin " +
  "düzenleme ekranında `Geolocator` ile toplanıyor (form_location_info). " +
  "Yani bu dört cümle pencereye özel: aynı karar motoruna aynı " +
  "`konum_onaylandi` olayı gidiyor, yalnız izin isteme yüzeyi farklı. " +
  "Flutter landing'ine konum adımı eklenirse bu kayıtlar silinmeli.";

export const LANDING_ESITLIK_ISTISNALARI_WEB: Istisna[] = [
  // --- Landing maket sohbeti (PhoneMockup AsistanSohbetIcerigi) ---

  // --- Dinamik üretim ---
  {
    metin: "2 bağlantı",
    neden: DINAMIK_URETIM,
  },

  // --- Erişilebilirlik ---
  {
    metin: "Vixrex Asistan'ı aç",
    neden: ERISEBILIRLIK,
  },

  // --- Çıkarıcı kapsamı ---
  {
    metin: "Dijital vitrin asistanı",
    neden:
      "Bu metin Flutter'da DA var — `lib/screens/vixrex_onboarding_chat_" +
      "screen.dart:325`, aynı cümle. Gerçek bir ayrışma değil: çıkarıcı " +
      "yalnız `landing_screen.dart`, `widgets/landing/` ve " +
      "`chatbot_badge.dart` dosyalarını tarıyor, asistan ekranını değil. " +
      "Kapsamı asistan ekranını da içerecek şekilde genişletmek ayrı bir " +
      "iş: o dosyada tek seferde onlarca yeni metin dökülür ve her biri " +
      "tek tek değerlendirilmeli. Toplu istisnaya yazmamak için burada " +
      "tek kayıt olarak duruyor.",
  },
  // --- Konum akışı: web tarayıcı GPS'i, Flutter kendi ekranında ---
  {
    metin: "GPS Taranıyor...",
    neden: KONUM_WEB_OZEL,
  },
  {
    metin: "GPS konumu alındı ✓",
    neden: KONUM_WEB_OZEL,
  },
  {
    metin: "Adres verisi © OpenStreetMap katkıcıları",
    neden:
      "Web, Flutter ile aynı Nominatim adres verisini sunucu vekili üzerinden " +
      "kullanıyor. Nominatim kullanım politikası web yüzeyinde görünür kaynak " +
      "göstermeyi gerektirdiği için bu yasal/servis atfı yalnız webde bulunur.",
  },
  {
    metin: "Konum izni alınamadı; il, ilçe ve adresi elle yazabilirsin.",
    neden: KONUM_WEB_OZEL,
  },
  {
    metin: "Örn: Çatalmeşe Mah. 207. Sokak No: 12",
    neden:
      "Flutter FormLocationInfo hint’i — `location_editor_section.dart:417` " +
      "aynen bu metin; web placeholder’ı parite için buna eşitlendi.",
  },
  {
    metin: "Açık Adres (Mahalle, Cadde, Sokak, No)",
    neden:
      "Flutter label — `location_editor_section.dart:389` aynı metin; " +
      "web label’ı parite için eklendi, extractor kapsamı dışında.",
  },
  {
    metin: "Örnek adres",
    neden:
      "Açık adres sr-only ipucu — Flutter'da hint olarak aynı örnek var " +
      "ama landing extractor'ında değil; erişilebilirlik için eklendi.",
  },
  {
    metin: "Konumu onayla, devam",
    neden:
      "Flutter primary buton — `vixrex_onboarding_chat_screen.dart:456` " +
      "aynı metin; web katalog `Adres Ekle` diyordu, parite için Flutter’a hizalandı.",
  },
  {
    metin: "İl seç",
    neden:
      "Flutter konumEksigi helper — `vixrex_onboarding_controller.dart:307` " +
      "`İl seç`; web helper’ı parite için eklendi, landing extractor " +
      "onboarding controller’ı taramıyor.",
  },
  {
    metin: "İlçe seç",
    neden:
      "Flutter konumEksigi helper — `vixrex_onboarding_controller.dart:308` " +
      "`İlçe seç`; aynı gerekçe.",
  },
  {
    metin: "Açık adresi yaz",
    neden:
      "Flutter konumEksigi helper — `vixrex_onboarding_controller.dart:311` " +
      "`Açık adresi yaz`; aynı gerekçe.",
  },

  // --- Bitiş mesajları (Flutter Web onboarding bitişi) ---
  {
    metin: "İşte bu kadar!",
    neden:
      "Flutter Web onboarding bitiş balonu. Katalog `all_done_baslik` " +
      "olarak 'Tebrikler!' diyor; Flutter Web ise 'İşte bu kadar!' " +
      "kullanıyor. Bitiş metni parity'si ayrı değerlendirilmeli.",
  },
  {
    metin: "Artık dijitalde varsın. İşletme adına özel vitrinin hazır.",
    neden:
      "Flutter Web onboarding bitiş açıklaması. Katalog `all_done_aciklama` " +
      "ile farklı metin içeriyor.",
  },

  // --- Hata mesajları (platform-spesifik) ---
  {
    metin: "Vitrin oluşturulamadı.",
    neden:
      "Landing publish hata mesajı. Flutter'da bu hata aynı API tarafından " +
      "döndürülüyor ama landing akışında gösterilmiyor — orada asistan " +
      "hata mesajını kendi içinde yönetiyor.",
  },
  {
    metin: "Bir hata oluştu. Lütfen tekrar dene.",
    neden:
      "Landing publish catch hata mesajı. Flutter Web'de benzer mesaj " +
      "var ama landing akışında farklı yüzeyde gösteriliyor.",
  },
  {
    metin: "Yayın için yasal onayları işaretlemeniz gerekiyor.",
    neden:
      "Landing yasal onay hata mesajı. Flutter Web'de bu kontrol " +
      "farklı bir katmanda (asistan controller) yapılıyor, landing'de " +
      "yok.",
  },
  {
    metin: "[landing-asistan] publish error:",
    neden:
      "console.error teknik logu, kullanıcıya gösterilmiyor. " +
      "Flutter'da karşılığı debugPrint ile loglanıyor.",
  },

  // --- Select option metinleri ---
  {
    metin: "İlçe seçiniz",
    neden:
      "İlçe dropdown boş seçenek metni. Flutter Web'de bu metin " +
      "dropdown içinde sabit yazılıyor, katalogdan gelmiyor.",
  },
  {
    metin: "Önce il seçiniz",
    neden:
      "İlçe dropdown devre dışıyken gösterilen metin. Flutter Web'de " +
      "aynı metin kullanılıyor.",
  },
  {
    metin: "İl seçiniz",
    neden:
      "İl dropdown boş seçenek metni. Flutter Web ile aynı.",
  },



  // --- Karşılama / hızlı seçim buton metinleri ---
  {
    metin: "Hızlı Seçenekler",
    neden:
      "Flutter Web onboarding karşılama başlığı. Katalogda " +
      "karşılığı yok — Flutter Web'de sabit yazılı.",
  },
  {
    metin: "Hazır Vitrin Seç",
    neden:
      "Flutter Web karşılama butonu. Katalogda karşılığı yok.",
  },
  {
    metin: "Sıfırdan Oluştur",
    neden:
      "Flutter Web karşılama butonu. Katalogda karşılığı yok.",
  },
  {
    metin: "Detaylı formu aç",
    neden:
      "Flutter Web bitiş butonu. Katalogda karşılığı yok.",
  },
  {
    metin: "İşini seç",
    neden:
      "Flutter Web kategori grid başlığı. Katalogda karşılığı yok.",
  },

  // --- Kategori sunum label farkları (A sınıfı — sunum label) ---
  {
    metin: "Spor & Fitness",
    neden:
      "Flutter Web kategori presentation label'ı. Next.js shared JSON " +
      "'Spor / Fitness' kullanıyor. Sunum label farkı (A sınıfı).",
  },
  {
    metin: "Sağlık / Yaşam",
    neden:
      "Shared JSON kategori label'ı. Flutter Web 'Sağlık & Yaşam' " +
      "kullanıyor. Sunum label farkı (A sınıfı).",
  },
  {
    metin: "Sağlık & Yaşam",
    neden:
      "Flutter Web kategori presentation label'ı. Sunum label farkı.",
  },
  {
    metin: "Oto / Araç",
    neden:
      "Shared JSON kategori label'ı. Flutter Web 'Oto & Araç Hizmetleri' " +
      "kullanıyor. Sunum label farkı.",
  },
  {
    metin: "Oto & Araç Hizmetleri",
    neden:
      "Flutter Web kategori presentation label'ı. Sunum label farkı.",
  },

  // --- Hesap bağlama / Google kimlik bağlama metinleri ---
  {
    metin: "Vitrinini hesabına bağla",
    neden:
      "Web landing'inde yayınlanan vitrin sonrası hesap bağlama uyarısı. " +
      "Flutter landing'inde bu uyarı henüz yok — hesap bağlama akışı " +
      "Flutter'da farklı bir yüzeyde (sahiplik paneli) yürütülüyor.",
  },
  {
    metin: "Şu an vitrinin bu cihaza bağlı. Telefonunu değiştirirsen ya da " +
      "tarayıcı verilerini silersen erişimini kaybedersin.",
    neden:
      "Web landing'inde hesap bağlama uyarısı açıklaması. Flutter " +
      "landing'inde aynı uyarı henüz eklenmedi.",
  },
  {
    metin: "Google ile bağla",
    neden:
      "Web landing'inde hesap bağlama butonu. Flutter'da bu buton " +
      "sahiplik panelinde farklı bir akışla sunuluyor.",
  },
  {
    metin: "Google açılıyor…",
    neden:
      "Web landing'inde hesap bağlama yükleniyor durumu. Flutter'da " +
      "aynı durum mesajı henüz eklenmedi.",
  },
  {
    metin: "Google hesabı bağlanamadı.",
    neden:
      "Web landing'inde hesap bağlama hata mesajı. Flutter'da bu hata " +
      "farklı bir yüzeyde gösteriliyor.",
  },

  // --- Yasal onay link metinleri ---
  {
    metin: "Aydınlatma Metni",
    neden:
      "Yasal onay checkbox link metni. Flutter Web'de aynı metin " +
      "kullanılıyor ama Flutter landing extractoru bu ekranı kapsamıyor.",
  },
  {
    metin: "Açık Rıza Beyanı",
    neden:
      "Yasal onay checkbox link metni. Aynı neden.",
  },
  {
    metin: "nı okudum, anladım ve kabul ediyorum.",
    neden:
      "Yasal onay checkbox açıklama metni parçası. Flutter Web'de " +
      "aynı metin kullanılıyor ama Flutter landing extractoru bu " +
      "ekranı kapsamıyor.",
  },
  {
    metin: "Vitrinini aç",
    neden:
      "Flutter Web bitiş butonu. Katalogda `landing_finish_buton` olarak " +
      "'Hesap Aç ve Vitrini Kur' yazıyor; Flutter Web ise 'Vitrinini aç' " +
      "kullanıyor.",
  },

  // --- Faz C1 (Tek Asistan planı, 2026-09-02) → Akış 1 paritesi (2026-09-03):
  // "Hazır Vitrin Seç" niyet sorusu artık katalogda
  // (shared/vixrex_mesajlar.json `niyet_*`) — iki yüzey de aynı
  // anahtarları okuyor, istisnaya gerek kalmadı. Kayıtlar silindi;
  // soru metinleri bileşende literal olarak geçmiyor.
];

// Blog altbilgi bağlantısı (28 Ağustos) buraya İSTİSNA OLARAK GİRMEDİ ve
// girmemeli: web→Flutter yönündeki çıkarıcı yalnız
// `public_web/src/components/landing` dizinini tarıyor ve en az 6 karakter
// + boşluk arıyor. "Blog" ikisini de karşılamıyor, altbilgi de o dizinde
// değil. Buraya yazılırsa "bayat istisna" kontrolü kırılır — ölçüldü.
