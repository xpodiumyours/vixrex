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

const KATALOG_ETIKETI =
  "Flutter şablon kataloğu (landing_template_category.dart) artık kanonik " +
  "kimlikleri kullanıyor; etiket webde başka bir bölümde geçtiği için " +
  "çıkarıcı eşleştiremiyor.";

const ALT_SAYFA =
  "Flutter kataloğu bir alt sayfa (bottom sheet) açıyor. Webde onun yerine " +
  "gerçek bir sayfa var (/kesfet/[kategori]) — modal içeriğini arama motoru " +
  "göremez, isin amaci taranabilir yüzey üretmek.";

export const LANDING_ESITLIK_ISTISNALARI: Istisna[] = [
  { metin: "Teknik Servis", neden: KATALOG_ETIKETI },


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
      "6 farklı kategoride profesyonel, telifsiz görsellerle vitrinini saniyeler içinde oluştur.",
    neden:
      "İki taraf da 6 diyor; web sayıyı tek kaynaktan " +
      "(AKTIF_BUSINESS_CATEGORIES.length) basarken Flutter sabit yazıyor. " +
      "Çıkarıcı web'deki şablon ifadesini düz metne çeviremediği için " +
      "eşleşmiyor. Sayı, landing-katalog-parite testiyle kilitli.",
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
