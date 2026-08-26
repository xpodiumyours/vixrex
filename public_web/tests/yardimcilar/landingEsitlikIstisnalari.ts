/**
 * Flutter landing'inde OLUP webde BİLEREK olmayan metinler.
 *
 * Kural basit: Flutter'daki her kullanıcı metni webde de bulunmalı;
 * bulunmayan her metin ya webe eklenmeli ya da BURAYA gerekçesiyle
 * yazılmalı. Üçüncü seçenek yok — sessizce ayrışmak mümkün değil.
 *
 * Liste bayatlarsa da test kırılır: burada olup Flutter'da artık bulunmayan
 * bir metin, temizlenmemiş istisna demektir ve gerçek bir ayrışmayı
 * gizleyebilir.
 */

type Istisna = { metin: string; neden: string };

const MOCKUP_ICERIGI =
  "Telefon mockup'ındaki örnek işletmelerin uydurma menü/eylem içeriği. " +
  "Web mockup'ı sadeleştirildi: kapak ve galeri küçükleri gösteriliyor, " +
  "sahte menü ile sahte pazaryeri bağlantıları taşınmadı.";

const KATALOG_ETIKETI =
  "Flutter kataloğunun 20 arayüz anahtarından biri. Web, paylaşılan " +
  "sözleşmedeki (shared/business_categories.json) 19 kanonik etiketi " +
  "kullanıyor; Flutter'ın anahtarlarının 11'i veritabanında karşılıksız.";

const ALT_SAYFA =
  "Flutter kataloğu bir alt sayfa (bottom sheet) açıyor. Webde onun yerine " +
  "gerçek bir sayfa var (/kesfet/[kategori]) — modal içeriğini arama motoru " +
  "göremez, isin amaci taranabilir yüzey üretmek.";

export const LANDING_ESITLIK_ISTISNALARI: Istisna[] = [
  { metin: "Yeni sezon reyonları ve mağaza fotoğrafları tek vitrinde.", neden: MOCKUP_ICERIGI },
  { metin: "Vitrin galerisi", neden: MOCKUP_ICERIGI },
  { metin: "Raf ve reyon fotoğrafları", neden: MOCKUP_ICERIGI },
  { metin: "Mağazayı ziyaret edin", neden: MOCKUP_ICERIGI },
  { metin: "Menü, konum ve WhatsApp sipariş bilgileri tek ekranda.", neden: MOCKUP_ICERIGI },
  { metin: "Yol tarifi", neden: MOCKUP_ICERIGI },
  { metin: "Günün menüsü", neden: MOCKUP_ICERIGI },
  { metin: "Sıcak yemek ve tatlılar", neden: MOCKUP_ICERIGI },
  { metin: "Paket servis", neden: MOCKUP_ICERIGI },
  { metin: "WhatsApp ile sipariş", neden: MOCKUP_ICERIGI },
  { metin: "Randevu, hizmetler ve sosyal medya bağlantıları hazır.", neden: MOCKUP_ICERIGI },
  { metin: "Kesim, boya ve bakım", neden: MOCKUP_ICERIGI },
  { metin: "Randevu al", neden: MOCKUP_ICERIGI },
  { metin: "WhatsApp ile hızlı iletişim", neden: MOCKUP_ICERIGI },
  { metin: "Servis talebi, adres ve güvenilir iletişim tek vitrinde.", neden: MOCKUP_ICERIGI },
  { metin: "Servis kaydı", neden: MOCKUP_ICERIGI },
  { metin: "Ekran, batarya ve bakım", neden: MOCKUP_ICERIGI },
  { metin: "Google yorumları", neden: MOCKUP_ICERIGI },
  { metin: "Müşteri güveni", neden: MOCKUP_ICERIGI },

  { metin: "Butik & Giyim", neden: KATALOG_ETIKETI },
  { metin: "Kuaför & Güzellik", neden: KATALOG_ETIKETI },
  { metin: "Kafe & Restoran", neden: KATALOG_ETIKETI },
  { metin: "Oto Kuaför", neden: KATALOG_ETIKETI },
  { metin: "Market & Bakkal", neden: KATALOG_ETIKETI },
  { metin: "Pastane & Tatlıcı", neden: KATALOG_ETIKETI },
  { metin: "Mobilya & Dekorasyon", neden: KATALOG_ETIKETI },
  { metin: "Spor Salonu", neden: KATALOG_ETIKETI },
  { metin: "Diş Kliniği", neden: KATALOG_ETIKETI },
  { metin: "Teknik Servis", neden: KATALOG_ETIKETI },
  { metin: "Pet Shop & Veteriner", neden: KATALOG_ETIKETI },
  { metin: "Hizmet & Danışmanlık", neden: KATALOG_ETIKETI },
  { metin: "Eğitim & Ders", neden: KATALOG_ETIKETI },
  { metin: "Ev & Temizlik", neden: KATALOG_ETIKETI },

  { metin: "Hazır görseller yükleniyor...", neden: ALT_SAYFA },
  { metin: "Kapak Görselleri", neden: ALT_SAYFA },
  { metin: "Galeri Görselleri", neden: ALT_SAYFA },
  { metin: "Ürün Görselleri", neden: ALT_SAYFA },
  { metin: "Bu kategori için henüz hazır görsel bulunmuyor.", neden: ALT_SAYFA },

  {
    metin: "Kayıtlı Vitrinimi Düzenle",
    neden:
      "Cihazda kayıtlı vitrin varsa görünen durum. Webde hesap oturumu yok " +
      "(Faz 2). Web girişi geldiğinde bu istisna kaldırılmalı.",
  },
  {
    metin: "Farklı vitrinleri incele",
    neden:
      "Yukarıdaki kayıtlı-vitrin durumunun ikincil bağlantısı; aynı sebeple " +
      "webde karşılığı yok.",
  },
  {
    metin: "Veri Silme",
    neden:
      "Flutter altbilgisi /data-deletion adresine bağlanıyor ama public_web'de " +
      "yalnız /data-deletion/status/[code] var, dizinin kendisi 404. Kırık " +
      "bağlantı eklenmedi; o sayfa açılınca istisna kaldırılmalı.",
  },
  {
    metin: "Demo vitrin önizlemesi açılamadı.",
    neden:
      "Uygulama içi hata bildirimi. Webde mockup demo vitrine değil kategori " +
      "sayfasına bağlanıyor, dolayısıyla böyle bir hata oluşamaz.",
  },
  {
    metin: "Vitrin hazır",
    neden:
      "Uygulama içi kurulum sohbetinin durum metni; webde sohbet motoru yok.",
  },
  {
    metin:
      "12 farklı kategoride profesyonel, telifsiz görsellerle vitrinini saniyeler içinde oluştur.",
    neden:
      "Sayı Flutter'da tutarsız: metin 12 diyor, katalog 20 kart çiziyor, " +
      "veritabanında 19 kanonik kategori var. Web sayıyı tek kaynaktan " +
      "(BUSINESS_CATEGORIES.length) basıyor.",
  },
  {
    metin: "Sıradaki adım: Kategorini seç",
    neden:
      "Flutter asistan motorunun (VixRexGuidanceService) dinamik mesajı. " +
      "Web'de bu motor henüz yok (Faz 2); asistan web'e taşındığında bu istisna kaldırılmalı.",
  },
  {
    metin: "✨ Vitrinin harika görünüyor!",
    neden:
      "Flutter asistan motorunun (VixRexGuidanceService) dinamik mesajı. " +
      "Web'de bu motor henüz yok (Faz 2); asistan web'e taşındığında bu istisna kaldırılmalı.",
  },
];
