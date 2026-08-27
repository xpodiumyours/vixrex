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

const LANDING_MAKET_SOHBET =
  "Landing'deki asistan sohbeti bir makettir (VIXREX_RULES.md §1) — sabit " +
  "reklam metni, motora bağlı değil. Flutter'da aynı yüzey gerçek asistan " +
  "motoruyla çalışıyor ve metinleri dinamik üretiliyor; birebir karşılığı " +
  "yok, olmamalı da.";

const DINAMIK_URETIM =
  "Flutter'da bu metin profil verisinden dinamik üretiliyor (ör. '" +
  "${profile.links.length} bağlantı'). Sabit yazı olmadığı için çıkarıcı " +
  "bulamıyor; web'de ise sabit olarak yazılı.";

const ERISEBILIRLIK =
  "Ekran okuyucu etiketi (aria-label), gözle görünen metin değil. Flutter'da " +
  "erişilebilirlik farklı bir mekanizmayla sağlanıyor.";

export const LANDING_ESITLIK_ISTISNALARI_WEB: Istisna[] = [
  // --- Landing maket sohbeti (PhoneMockup AsistanSohbetIcerigi) ---
  {
    metin: "Dijital vitrin asistanı",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Merhaba, ben Vixrex Asistan. İşletmeni ne kazandırıyorum?",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Tek Link & QR Kod:",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Dükkanına kolayca ulaşılır.",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "WhatsApp Sipariş:",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Müşterilerin tek tıkla sana ulaşır.",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Ürün & Galeri:",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Konum & Adres:",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Senin işletmen için de 2 dakikada beraber hazırlayalım mı?",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Hızlı Seçenekler",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Hazır Vitrin Seç",
    neden: LANDING_MAKET_SOHBET,
  },
  {
    metin: "Sıfırdan Oluştur",
    neden: LANDING_MAKET_SOHBET,
  },

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
];
