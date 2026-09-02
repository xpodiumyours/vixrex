// Faz D (Tek Asistan planı, 2026-09-02) — kiralanan bir şablonu işletmeye
// uyarlarken asistanın kendi hazırlayabileceği metinlerin tek kaynağı.
//
// KURAL SETİ (kullanıcı onayıyla karara bağlandı):
//   1) Yalnız `vitrinFieldSchema.ts`'te `otomatikDoldurulabilir: true`
//      işaretli alanlar buradan beslenir. Gerçek işletme kimliği (ad,
//      WhatsApp, adres, il/ilçe, çalışma saatleri, gerçek ürünler),
//      "hikaye" metni (hakkındaMetin — 1200 karakter, sahtesi güven
//      kırar) ve yanlışsa utandırıcı ince ayrımlar (işletmeTuru — "Kuaför"
//      kategorisinden "Erkek kuaförü" tahmini yanlış çıkarsa boş
//      bırakmaktan daha kötüdür) HİÇBİR ZAMAN buraya girmez.
//   2) Kampanya bandı (bant*) da yok: gerçek kampanya bilgisi olmadan
//      "499 TL'den başlayan" gibi sahte bir fiyat/indirim iddiası
//      müşteriyi yanıltır — asistan bunun yerine bölümü kapalı bırakır
//      (bkz. uygula() — section_visibility.featured = false).
//   3) İçerik derinliği bilinçli olarak eşit değil: heroRozet, kısaTanıtım,
//      kategori/ürün bölüm başlığı gibi GÖRÜNÜRLÜĞÜ yüksek alanlar 19
//      kategoriye özel yazıldı (aşağıdaki KATEGORIYE_OZEL_METIN). Galeri/
//      blog/SSS başlıkları gibi düşük görünürlüklü, kategoriden bağımsız
//      iyi çalışan alanlar TEK evrensel metinle kaldı (EVRENSEL_METIN) —
//      19 kategoriye "İşlerimizden" gibi bir başlığı ayrı ayrı yazmak
//      katma değersiz mühendislik olurdu.
//   4) "Diğer" kategorisi hariç: şema zaten "Diğer"i işlevsel olarak boş
//      sayıyor (bosDegerler), otomatik doldurma da uygulanmaz.

import { resolveBusinessCategory } from "./businessCategories";
import type { VitrinField } from "./vitrinFieldSchema";

type KategoriyeOzelAlan =
  | "heroRozet"
  | "kisaTanitim"
  | "kategoriBolumBaslik"
  | "urunBolumBaslik";

/**
 * 19 kanonik kategorinin her biri için, görünürlüğü en yüksek dört alan.
 * "Diğer" bilerek yok — kategori seçilmemiş sayılır (bosDegerler).
 */
const KATEGORIYE_OZEL_METIN: Record<string, Record<KategoriyeOzelAlan, string>> = {
  giyim: {
    heroRozet: "Güncel Koleksiyon",
    kisaTanitim: "Sezonun öne çıkan parçalarını ve günlük şıklığı tamamlayacak seçkiyi bir arada sunan bir giyim mağazası.",
    kategoriBolumBaslik: "Koleksiyonlar",
    urunBolumBaslik: "Ürünlerimiz",
  },
  butik: {
    heroRozet: "Özenle Seçilmiş Parçalar",
    kisaTanitim: "Kalabalıklardan sıyrılan, özenle seçilmiş ve sınırlı sayıda parçanın bir araya geldiği bir butik.",
    kategoriBolumBaslik: "Koleksiyonlar",
    urunBolumBaslik: "Ürünlerimiz",
  },
  gida: {
    heroRozet: "Taze ve Günlük",
    kisaTanitim: "Taze ürünleri ve günlük seçkisiyle mutfağınıza en iyisini taşıyan bir gıda işletmesi.",
    kategoriBolumBaslik: "Ürün Grupları",
    urunBolumBaslik: "Ürünlerimiz",
  },
  firin: {
    heroRozet: "Günlük Taze Fırın",
    kisaTanitim: "Her sabah taze pişen ekmek ve unlu mamulleriyle mahallenin fırını.",
    kategoriBolumBaslik: "Ürün Grupları",
    urunBolumBaslik: "Fırından Bugün",
  },
  kozmetik: {
    heroRozet: "Cilt ve Bakım Uzmanı",
    kisaTanitim: "Cilt bakımından makyaja, güvenilir markaları ve doğru ürünleri bir arada sunan bir kozmetik mağazası.",
    kategoriBolumBaslik: "Ürün Grupları",
    urunBolumBaslik: "Ürünlerimiz",
  },
  dekorasyon: {
    heroRozet: "Evinize Dokunuş",
    kisaTanitim: "Evinize ve mekânınıza karakter katacak dekorasyon ürünlerini bir araya getiren bir mağaza.",
    kategoriBolumBaslik: "Ürün Grupları",
    urunBolumBaslik: "Ürünlerimiz",
  },
  elektronik: {
    heroRozet: "Güvenilir Teknoloji",
    kisaTanitim: "Doğru ürünü doğru fiyata bulmanızı sağlayan, güvenilir elektronik ve teknoloji mağazası.",
    kategoriBolumBaslik: "Ürün Grupları",
    urunBolumBaslik: "Ürünlerimiz",
  },
  kirtasiye: {
    heroRozet: "Okul ve Ofis İhtiyacın Burada",
    kisaTanitim: "Okul, ofis ve günlük kırtasiye ihtiyaçlarınızı tek adreste toplayan bir kırtasiye.",
    kategoriBolumBaslik: "Ürün Grupları",
    urunBolumBaslik: "Ürünlerimiz",
  },
  kafe_lokanta: {
    heroRozet: "Lezzet Durağınız",
    kisaTanitim: "Günün her saatinde keyifli bir mola ya da doyurucu bir öğün için doğru adres.",
    kategoriBolumBaslik: "Menü",
    urunBolumBaslik: "Menümüz",
  },
  kuafor: {
    heroRozet: "Profesyonel Kuaför Hizmeti",
    kisaTanitim: "Uzman ellerde, ihtiyacınıza uygun saç ve bakım hizmetleri sunan bir kuaför salonu.",
    kategoriBolumBaslik: "Hizmet Grupları",
    urunBolumBaslik: "Hizmetlerimiz",
  },
  teknik_servis: {
    heroRozet: "Profesyonel Teknik Servis",
    kisaTanitim: "Cihazlarınız için hızlı, güvenilir ve garantili teknik servis hizmeti.",
    kategoriBolumBaslik: "Hizmet Grupları",
    urunBolumBaslik: "Hizmetlerimiz",
  },
  hizmet_danismanlik: {
    heroRozet: "Uzman Danışmanlık",
    kisaTanitim: "İhtiyacınıza özel çözümler sunan, alanında deneyimli bir danışmanlık hizmeti.",
    kategoriBolumBaslik: "Hizmet Grupları",
    urunBolumBaslik: "Hizmetlerimiz",
  },
  egitim_ders: {
    heroRozet: "Uzman Eğitmen Kadrosu",
    kisaTanitim: "Alanında deneyimli eğitmenlerle, hedefinize uygun ders ve eğitim programları.",
    kategoriBolumBaslik: "Ders Grupları",
    urunBolumBaslik: "Derslerimiz",
  },
  ev_temizlik: {
    heroRozet: "Güvenilir Temizlik Hizmeti",
    kisaTanitim: "Eviniz ve iş yeriniz için güvenilir, düzenli ve titiz temizlik hizmeti.",
    kategoriBolumBaslik: "Hizmet Grupları",
    urunBolumBaslik: "Hizmetlerimiz",
  },
  spor_fitness: {
    heroRozet: "Formda Kalmanın Adresi",
    kisaTanitim: "Hedefinize uygun antrenman programları ve uzman eşliğinde spor deneyimi.",
    kategoriBolumBaslik: "Hizmet Grupları",
    urunBolumBaslik: "Hizmetlerimiz",
  },
  pet_shop_veteriner: {
    heroRozet: "Dostunuz İçin En İyisi",
    kisaTanitim: "Evcil dostunuzun sağlığı ve bakımı için güvenilir ürün ve hizmetler.",
    kategoriBolumBaslik: "Ürün ve Hizmet Grupları",
    urunBolumBaslik: "Ürün ve Hizmetlerimiz",
  },
  saglik_yasam: {
    heroRozet: "Sağlıklı Yaşamın Adresi",
    kisaTanitim: "Sağlığınız ve yaşam kaliteniz için güvenilir hizmet ve uzman destek.",
    kategoriBolumBaslik: "Hizmet Grupları",
    urunBolumBaslik: "Hizmetlerimiz",
  },
  oto_arac: {
    heroRozet: "Aracınız Güvenli Ellerde",
    kisaTanitim: "Aracınızın bakım ve onarımı için güvenilir, uzman ve şeffaf hizmet.",
    kategoriBolumBaslik: "Hizmet Grupları",
    urunBolumBaslik: "Hizmetlerimiz",
  },
};

/** Kategoriden bağımsız, tek iyi metinle her işletmede çalışan alanlar. */
const EVRENSEL_METIN: Record<string, string> = {
  hakkindaBaslik: "Bizi Tanıyın",
  galeriUstBaslik: "İşlerimizden",
  galeriBaslik: "Galeri",
  galeriAksiyonMetni: "Hepsini Gör",
  blogUstBaslik: "Bilgi Köşesi",
  blogBaslik: "Yazılarımız",
  sssUstBaslik: "Merak Edilenler",
  sssBaslik: "Sıkça Sorulan Sorular",
  sssAciklama: "Aklınıza takılan soruların cevapları burada. Aradığınızı bulamazsanız bize ulaşabilirsiniz.",
};

/**
 * Bir alan için otomatik değer üretir — üretemezse `null` döner (asistan
 * bu durumda alanı boş bırakır, kullanıcıdan ister).
 *
 * `kapakGorseli` burada YOK: o metin değil, mevcut hazır-görsel
 * mekanizmasından (useOwnerActions.hazirGorseller) gelir — çağıran taraf
 * onu ayrı çözer.
 */
export function otomatikDeger(
  alan: Pick<VitrinField, "anahtar" | "otomatikDoldurulabilir">,
  kategoriEtiketi: string | null | undefined
): string | null {
  if (!alan.otomatikDoldurulabilir) return null;

  const evrensel = EVRENSEL_METIN[alan.anahtar];
  if (evrensel) return evrensel;

  const kategori = kategoriEtiketi ? resolveBusinessCategory(kategoriEtiketi) : null;
  if (!kategori) return null;

  const kategoriyeOzel = KATEGORIYE_OZEL_METIN[kategori.id];
  if (!kategoriyeOzel) return null; // "Diğer" dahil — kasıtlı

  if (alan.anahtar in kategoriyeOzel) {
    return kategoriyeOzel[alan.anahtar as KategoriyeOzelAlan];
  }
  return null;
}
