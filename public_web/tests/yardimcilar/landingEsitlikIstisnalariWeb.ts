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
 */

type Istisna = { metin: string; neden: string };

const ERISEBILIRLIK =
  "Ekran okuyucu etiketi (aria-label), gözle görünen metin değil. Flutter'da " +
  "erişilebilirlik farklı bir mekanizmayla sağlanıyor.";

const KONUM_WEB_OZEL =
  "Web landing'i konumu tarayıcının `navigator.geolocation` özelliğiyle " +
  "alıyor; Flutter tarafında aynı konum alanları kendi platform API'siyle " +
  "toplanıyor. Aynı veri sözleşmesine gidiyor, izin isteme yüzeyi platforma " +
  "özgü kalıyor.";

export const LANDING_ESITLIK_ISTISNALARI_WEB: Istisna[] = [
  // --- Erişilebilirlik ---
  {
    metin: "Vixrex Asistan'ı aç",
    neden: ERISEBILIRLIK,
  },

  // --- Çıkarıcı kapsamı ---
  {
    metin: "Dijital vitrin asistanı",
    neden:
      "Bu metin Flutter'da da `vixrex_onboarding_chat_screen.dart` içinde " +
      "bulunuyor. Landing metin çıkarıcısı asistan ekranını taramadığı için " +
      "burada kapsam istisnası olarak tutuluyor.",
  },

  // --- Konum akışı: tarayıcı/platform API farkları ---
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
      "Web aynı adres çözümleme verisini sunucu vekili üzerinden kullanıyor. " +
      "Web yüzeyindeki görünür servis atfı platforma özgü yasal sunumdur.",
  },
  {
    metin: "Konum izni alınamadı; il, ilçe ve adresi elle yazabilirsin.",
    neden: KONUM_WEB_OZEL,
  },
  {
    metin: "Örn: Çatalmeşe Mah. 207. Sokak No: 12",
    neden:
      "Flutter FormLocationInfo hint'i ile aynı metindir; Flutter landing " +
      "çıkarıcısının taramadığı ortak onboarding yüzeyinden gelir.",
  },
  {
    metin: "Açık Adres (Mahalle, Cadde, Sokak, No)",
    neden:
      "Flutter konum formundaki aynı label'ın web karşılığıdır; Flutter landing " +
      "metin çıkarıcısı konum formu dosyasını kapsamıyor.",
  },
  {
    metin: "Örnek adres",
    neden:
      "Ekran okuyucu için kullanılan yardımcı metindir; Flutter'da aynı örnek " +
      "hint olarak bulunur ancak landing çıkarıcısının kapsamı dışındadır.",
  },
  {
    metin: "Konumu onayla, devam",
    neden:
      "Flutter VixRex onboarding ekranındaki aynı birincil buton metnidir; " +
      "landing çıkarıcısı asistan ekranını taramadığı için burada tutulur.",
  },
  {
    metin: "İl seç",
    neden:
      "Flutter VixRex onboarding controller konum eksikliği metniyle aynıdır; " +
      "controller landing metin çıkarıcısının kapsamı dışındadır.",
  },
  {
    metin: "İlçe seç",
    neden:
      "Flutter VixRex onboarding controller konum eksikliği metniyle aynıdır; " +
      "controller landing metin çıkarıcısının kapsamı dışındadır.",
  },
  {
    metin: "Açık adresi yaz",
    neden:
      "Flutter VixRex onboarding controller konum eksikliği metniyle aynıdır; " +
      "controller landing metin çıkarıcısının kapsamı dışındadır.",
  },

  // --- Bitiş mesajları ---
  {
    metin: "İşte bu kadar!",
    neden:
      "Flutter onboarding bitiş yüzeyindeki aynı metindir; Flutter landing " +
      "çıkarıcısı onboarding ekranını kapsamıyor.",
  },
  {
    metin: "Artık dijitalde varsın. İşletme adına özel vitrinin hazır.",
    neden:
      "Flutter onboarding bitiş yüzeyindeki aynı açıklamadır; Flutter landing " +
      "çıkarıcısı onboarding ekranını kapsamıyor.",
  },

  // --- Hata mesajları: web API/Browser yüzeyi ---
  {
    metin: "Vitrin oluşturulamadı.",
    neden:
      "Web create-store API hata yüzeyidir. Flutter aynı başarısızlığı kendi " +
      "controller hata yüzeyinde işler; kullanıcı akışındaki görev aynıdır.",
  },
  {
    metin: "Bir hata oluştu. Lütfen tekrar dene.",
    neden:
      "Web publish catch hata mesajıdır. Flutter'da hata controller üzerinden " +
      "sunulduğu için literal landing kaynağında bulunmaz.",
  },
  {
    metin: "Yayın için yasal onayları işaretlemeniz gerekiyor.",
    neden:
      "Web yasal yayın kapısı hata mesajıdır. Flutter aynı kapıyı onboarding " +
      "controller ve LegalConsentSection üzerinden uygular.",
  },
  {
    metin: "[landing-asistan] publish error:",
    neden:
      "Kullanıcıya görünmeyen teknik console hata önekidir; Flutter karşılığı " +
      "debug log mekanizmasıdır.",
  },

  // --- Select option metinleri ---
  {
    metin: "İlçe seçiniz",
    neden:
      "Web select boş seçenek metnidir; Flutter konum seçim yüzeyinde aynı " +
      "işlev native seçim bileşeni üzerinden sunulur.",
  },
  {
    metin: "Önce il seçiniz",
    neden:
      "Web ilçe alanı devre dışı durumu için açıklayıcı select metnidir; " +
      "platform seçim bileşeni farkıdır.",
  },
  {
    metin: "İl seçiniz",
    neden:
      "Web select boş seçenek metnidir; Flutter konum seçim yüzeyinde aynı " +
      "işlev native seçim bileşeni üzerinden sunulur.",
  },

  // --- Karşılama / hızlı seçim metinleri ---
  {
    metin: "Hızlı Seçenekler",
    neden:
      "Flutter VixRex onboarding ekranında aynı başlık bulunur; landing " +
      "çıkarıcısı asistan ekranını taramadığı için kapsam istisnasıdır.",
  },
  {
    metin: "Hazır Vitrin Seç",
    neden:
      "Flutter VixRex onboarding hızlı seçeneğiyle aynıdır; landing çıkarıcısı " +
      "asistan ekranını taramadığı için kapsam istisnasıdır.",
  },
  {
    metin: "Sıfırdan Oluştur",
    neden:
      "Flutter VixRex onboarding hızlı seçeneğiyle aynıdır; landing çıkarıcısı " +
      "asistan ekranını taramadığı için kapsam istisnasıdır.",
  },
  {
    metin: "Detaylı formu aç",
    neden:
      "Web sahip paneli geçiş butonudur. Flutter aynı hedefi HomeShell/vitrin " +
      "düzenleme navigasyonu üzerinden sunar.",
  },
  {
    metin: "İşini seç",
    neden:
      "Flutter VixRex onboarding kategori seçici başlığıyla aynıdır; landing " +
      "çıkarıcısı asistan ekranını taramadığı için kapsam istisnasıdır.",
  },

  // --- Kategori sunum label farkları ---
  {
    metin: "Spor & Fitness",
    neden:
      "Kategori sunum label'ı ortak kategori sözlüğündeki alternatif yazımdan " +
      "gelir; iş kuralı ve kategori kimliği değişmez.",
  },
  {
    metin: "Sağlık / Yaşam",
    neden:
      "Kategori sunum label'ı ortak kategori sözlüğündeki alternatif yazımdan " +
      "gelir; iş kuralı ve kategori kimliği değişmez.",
  },
  {
    metin: "Sağlık & Yaşam",
    neden:
      "Kategori sunum label'ı Flutter presentation karşılığıdır; kategori " +
      "kimliği aynı kaldığı için yalnız sunum farkıdır.",
  },
  {
    metin: "Oto / Araç",
    neden:
      "Kategori sunum label'ı ortak kategori sözlüğündeki alternatif yazımdan " +
      "gelir; iş kuralı ve kategori kimliği değişmez.",
  },
  {
    metin: "Oto & Araç Hizmetleri",
    neden:
      "Kategori sunum label'ı Flutter presentation karşılığıdır; kategori " +
      "kimliği aynı kaldığı için yalnız sunum farkıdır.",
  },

  // --- Yasal onay bağlantı metinleri ---
  {
    metin: "Aydınlatma Metni",
    neden:
      "Flutter LegalConsentSection içinde aynı yasal belge bağlantısı bulunur; " +
      "landing çıkarıcısı o dosyayı kapsamıyor.",
  },
  {
    metin: "Açık Rıza Beyanı",
    neden:
      "Flutter LegalConsentSection içinde aynı yasal belge bağlantısı bulunur; " +
      "landing çıkarıcısı o dosyayı kapsamıyor.",
  },
  {
    metin: "nı okudum, anladım ve kabul ediyorum.",
    neden:
      "Yasal onay açıklamasının ortak parçasıdır; Flutter yasal bileşeni landing " +
      "metin çıkarıcısının kapsamı dışındadır.",
  },
  {
    metin: "Vitrinini aç",
    neden:
      "Flutter onboarding bitişinde aynı hedef bulunur; route oluşturma şekli " +
      "platforma özgü olsa da kullanıcı eylemi aynıdır.",
  },
];
