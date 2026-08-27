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
];
