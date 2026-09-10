/**
 * VIXREX BLOGU — merkezî kurumsal blog kaynağı.
 *
 * `store_articles` işletme vitrini yazıları içindir. Kurumsal Vixrex blogu
 * dosya tabanlı kalır; yeni CMS/veritabanı bu kapsamda eklenmez.
 *
 * `yayinda` mevcut yayın anahtarıdır ve geriye dönük güvenlik sözleşmesidir.
 * `durum` editoryal yaşam döngüsünü taşır. Taslak ve arşiv içerik normal blog,
 * sitemap ve RSS yüzeylerine giremez.
 */

export const BLOG_KATEGORILERI = [
  "Dijital Vitrin",
  "Google ve Keşfedilme",
  "Müşteri İletişimi",
  "Vixrex’te Yenilikler",
  "İşletme Hikâyeleri",
] as const;

export type BlogKategori = (typeof BLOG_KATEGORILERI)[number];
export type BlogIcerikTuru =
  | "rehber"
  | "haber"
  | "urun_guncellemesi"
  | "isletme_hikayesi";
export type BlogDurumu = "taslak" | "yayinda" | "inceleme_gerekli" | "arsiv";
export type BlogKontrolSinifi = "harici_platform" | "vixrex_urun" | "genel";

export type BlogYazar = {
  ad: string;
  tur: "kisi" | "kurum";
  url?: string;
};

export type BlogKaynak = {
  baslik: string;
  url: string;
};

export type BlogGuncellemeNotu = {
  tarih: string;
  aciklama: string;
};

export type BlogYazisi = {
  slug: string;
  baslik: string;
  ozet: string;
  /** Sınırlı Markdown: düz paragraf, ##, ###, - liste, 1. liste. Ham HTML yok. */
  govde: string;

  /** İçerik kalite kapısı */
  cozduguSoru: string;
  kategori: BlogKategori;
  icerikTuru: BlogIcerikTuru;
  sektorler: string[];
  yazar: BlogYazar;
  inceleyen: BlogYazar | null;
  kaynaklar: BlogKaynak[];
  urunDogrulamaOrtami: string | null;

  /** Görsel kalite kapısı */
  kapak: string | null;
  kapakAlt: string | null;
  gorselKaynagi: string | null;
  gorselKullanimHakki: string | null;

  /** Güncellik */
  yayinTarihi: string | null;
  guncellemeTarihi: string | null;
  sonKontrolTarihi: string;
  guncellemeNotlari: BlogGuncellemeNotu[];
  durum: BlogDurumu;
  /** Güncellik hedefini kategoriye bağlamadan açıkça belirler. */
  kontrolSinifi: BlogKontrolSinifi;

  /** Gezinme / gelecek asistan hazırlığı */
  ilgiliYazilar: string[];
  asistanKullaniminaUygun: boolean;

  /** Mevcut yayın anahtarı — güvenlik sözleşmesi korunur. */
  yayinda: boolean;
};

export type YayindakiBlogYazisi = BlogYazisi & { yayinTarihi: string };

/**
 * Blog ana sayfasına gönderilen hafif görünüm modeli. Tam gövde, kaynaklar,
 * editoryal notlar ve kalite alanları Client Component'e taşınmaz.
 */
export type BlogListeYazisi = Pick<
  YayindakiBlogYazisi,
  | "slug"
  | "baslik"
  | "ozet"
  | "kategori"
  | "icerikTuru"
  | "sektorler"
  | "kapak"
  | "kapakAlt"
  | "yayinTarihi"
  | "guncellemeTarihi"
> & {
  okumaDakika: number;
};

export const BLOG_YAZILARI: BlogYazisi[] = [
  {
    slug: "kuafor-icin-internet-sitesi",
    baslik: "Kuaför salonu için dijital vitrin nasıl hazırlanır?",
    ozet:
      "Kuaför ve berberler için müşterinin temel sorularını tek sayfada " +
      "yanıtlayan, gerçek işletme bilgilerine dayalı bir dijital vitrin kontrol rehberi.",
    govde: `## Önce müşterinin aradığı temel bilgileri tamamlayın

Bir kuaför vitrini yalnız güzel görünmemeli; ziyaretçinin işletme hakkında temel sorularına cevap verebilmelidir. Vixrex'in mevcut alan şemasında işletme adı, kategori, işletme türü, kısa tanıtım, WhatsApp, telefon, açık adres, il, ilçe ve çalışma saatleri ayrı alanlar olarak tutulur.

Yayın öncesinde ilk kontrolünüz şu olmalı:

- İşletme adı gerçek hayatta kullanılan adla aynı mı?
- Kuaför, berber, kadın kuaförü veya erkek kuaförü gibi işletme türü doğru mu?
- WhatsApp ve telefon numarası gerçekten işletmeye mi ait?
- Açık adres, il ve ilçe doğru mu?
- Çalışma saatleri güncel mi?

Bu bilgilerden biri eskiyse, iyi tasarlanmış bir vitrin bile müşteriye yanlış bilgi verebilir.

## İşletme adını ve kısa tanıtımı sade yazın

İşletme adını slogan, telefon numarası veya gereksiz anahtar kelimelerle uzatmak yerine gerçek adını kullanın. Kısa tanıtımda ise müşterinin vitrini açtığında ilk bakışta anlayacağı bilgiler yeterlidir: ne tür hizmet verdiğiniz ve hangi bölgede olduğunuz.

Örnek biçim:

- İşletme adı: gerçek tabela veya marka adı
- İşletme türü: Erkek kuaförü
- Kısa tanıtım: Saç kesimi, sakal bakımı ve bakım hizmetleri
- Konum metni: Kadıköy, İstanbul

Buradaki amaç reklam cümlesi üretmek değil, işletmeyi doğru ve anlaşılır biçimde tanımlamaktır.

## İletişimi tek dokunuşta kontrol edin

Vitrindeki WhatsApp ve telefon alanları yalnız yazılı bilgi olarak bırakılmamalıdır. Yayın öncesinde bağlantıları gerçek cihazdan açın ve doğru numaraya ulaştığını kontrol edin.

Yanlış numara, eksik ülke kodu veya başka bir kişiye ait iletişim bilgisi yayınlanmamalıdır. İşletme iletişim bilgisi değiştiğinde vitrin de aynı anda güncellenmelidir.

## Adres ve çalışma saatlerini gerçek işletmeyle karşılaştırın

Adres alanında müşterinin işletmeyi bulmasına yetecek açık ve güncel bilgi bulunmalıdır. İl ve ilçe bilgileri de gerçek adresle uyuşmalıdır.

Çalışma saatleri özellikle değişken bir bilgidir. Haftalık düzen, geçici kapanış veya çalışma saati değişikliği olduğunda vitrindeki bilgi de kontrol edilmelidir. Yayında görünen saat, işletmenin gerçekten müşteri kabul ettiği saat olmalıdır.

## Hizmetleri müşterinin anlayacağı adlarla yazın

Hizmet listesi, işletmenin gerçekten sunduğu hizmetleri göstermelidir. İçeride kullanılmayan mesleki ifadeler yerine müşterinin anlayacağı açık adlar tercih edin.

Örneğin işletme gerçekten sunuyorsa şu tür adlar kullanılabilir:

- Saç kesimi
- Sakal kesimi ve şekillendirme
- Saç boyama
- Saç bakımı
- Gelin saçı

Fiyat gösterecekseniz yalnız işletmenin güncel olarak doğruladığı fiyatı kullanın. Fiyat bilinmiyorsa tahmin üretmeyin; yanlış fiyat göstermek yerine alanı güncel bilgi gelene kadar boş bırakmak daha doğrudur.

## Görselleri seçerken gerçeklik ve kullanım hakkını birlikte kontrol edin

Kapak ve galeri görselleri işletmenin kendisine ait olmalı veya kullanım izni açıkça bulunmalıdır. Başka bir salonun çalışmasını kendi işi gibi gösterecek fotoğraf kullanılmamalıdır.

İyi bir görsel seçimi için üç basit kontrol yeterlidir:

1. Fotoğraf gerçekten bu işletmeye veya bu işletmenin çalışmasına mı ait?
2. Görsel yeterince net ve güncel mi?
3. Bu görseli yayınlama hakkı işletmede mi?

Bu üç sorudan biri cevaplanamıyorsa görsel yayınlanmamalıdır.

## Yayın öncesi son kontrol

Vitrini yayınlamadan önce masaüstü ve telefondan açarak aşağıdaki sırayla kontrol edin:

1. İşletme adı ve işletme türü doğru mu?
2. WhatsApp ve telefon bağlantıları doğru kişiye gidiyor mu?
3. Adres, il, ilçe ve harita bilgisi gerçek konumla uyumlu mu?
4. Çalışma saatleri ve hizmetler güncel mi?
5. Kullanılan görseller gerçek ve izinli mi?

Bu rehberin amacı vitrini daha çok metinle doldurmak değil; müşterinin karşısına çıkan bilgilerin doğru, anlaşılır ve kontrol edilmiş olmasını sağlamaktır.`,
    cozduguSoru:
      "Kuaför veya berber vitrini hazırlanırken hangi işletme bilgileri ve görseller yayın öncesinde kontrol edilmelidir?",
    kategori: "Dijital Vitrin",
    icerikTuru: "rehber",
    sektorler: ["kuaför", "berber"],
    yazar: { ad: "Vixrex", tur: "kurum", url: "/hakkimizda" },
    inceleyen: null,
    kaynaklar: [],
    urunDogrulamaOrtami:
      "public_web/src/lib/vitrinFieldSchema.ts — alan şeması, 10 Eylül 2026 kontrolü",
    kapak: null,
    kapakAlt: null,
    gorselKaynagi: null,
    gorselKullanimHakki: null,
    yayinTarihi: null,
    guncellemeTarihi: null,
    sonKontrolTarihi: "2026-09-10",
    guncellemeNotlari: [],
    durum: "taslak",
    kontrolSinifi: "vixrex_urun",
    ilgiliYazilar: ["isletmemi-googleda-nasil-gosteririm"],
    asistanKullaniminaUygun: false,
    yayinda: false,
  },
  {
    slug: "isletmemi-googleda-nasil-gosteririm",
    baslik: "İşletmemi Google'da nasıl gösterebilirim?",
    ozet:
      "Google İşletme Profili, doğrulama seçenekleri ve web sayfanızın " +
      "Google tarafından keşfedilmesi için resmi Google belgelerine dayalı uygulama rehberi.",
    govde: `## Önce işletmenizin Google İşletme Profili için uygun olup olmadığını kontrol edin

Google İşletme Profili; müşterilerin ziyaret edebildiği fiziksel konuma sahip işletmeler veya müşterilere bulundukları yerde hizmet veren uygun hizmet bölgesi işletmeleri için kullanılabilir. İşletmeniz Google'da zaten görünüyorsa yeni bir profil açmak yerine mevcut profili sahiplenmeniz gerekebilir.

İlk adımınız, Google'da işletme adınızı aramak ve mevcut bir profil olup olmadığını kontrol etmektir.

## İşletmeyi gerçek hayattaki haliyle temsil edin

Google'ın resmi kuralları, işletmenin gerçek dünyada nasıl tanınıyorsa o şekilde temsil edilmesini ister. İşletme adı tabela, web sitesi ve diğer gerçek işletme materyallerindeki adla uyumlu olmalıdır.

Profilde özellikle şu bilgileri dikkatle kontrol edin:

- İşletme adı
- Adres veya hizmet bölgesi
- Ana işletme kategorisi
- Telefon numarası
- Web sitesi
- Normal çalışma saatleri
- Tatil veya geçici dönemler için özel çalışma saatleri

İşletme adına şehir, hizmet veya anahtar kelime ekleyerek adı yapay biçimde uzatmak doğru değildir. Adres ve hizmet bölgesi de gerçek işletme faaliyetini yansıtmalıdır.

## Google'ın size sunduğu doğrulama yöntemini kullanın

Google, doğrulama yöntemlerini otomatik olarak belirlediğini ve kullanıcının istediği yöntemi seçemeyeceğini açıkça belirtiyor. Kullanılabilir seçenekler işletme türüne, herkese açık bilgilere, bölgeye veya çalışma saatlerine göre değişebilir. Bazı işletmeler için birden fazla yöntem gerekebilir.

Bu nedenle “Google her işletmeye kartpostal gönderir” şeklinde sabit bir yöntem yoktur. Profilinizde görünen doğrulama seçeneklerini kullanın.

Video doğrulaması sunulursa Google, kaydın işletmenin konumunu, işletmenin varlığını ve işletmeyi yönetmeye yetkili olduğunuzu doğrulayacak bilgileri gösterebilmesini ister. Google'ın güncel yardım sayfasındaki koşullar doğrulama başlamadan önce kontrol edilmelidir.

## İşletme bilgilerinin farklı yüzeylerde birbiriyle çelişmemesine dikkat edin

Google, işletme adının gerçek dünyadaki kullanımını, adres veya hizmet bölgesinin doğruluğunu ve işletmeye ait telefon/web sitesi bilgisini açıkça vurguluyor.

Bu nedenle Google profilinizle kendi web sayfanız arasında şu bilgileri karşılaştırmanız yararlıdır:

- İşletme adı
- Telefon
- Adres veya hizmet bölgesi
- Çalışma saatleri
- İşletmenin sunduğu temel hizmetlerin tanımı

Buradaki hedef “Google'a sinyal göndermek” gibi doğrulanması zor bir iddia değildir. Hedef, müşterinin farklı yerlerde birbirini tutmayan işletme bilgileriyle karşılaşmasını önlemektir.

## Web sayfanızın Google tarafından taranabilir olmasını sağlayın

Bir web sayfasının Google Search'e girebilmesi için Googlebot'un sayfaya erişebilmesi, sayfanın başarılı bir HTTP yanıtı vermesi ve indekslenebilir içeriğe sahip olması temel teknik gereksinimler arasındadır.

Fakat bu koşulları karşılamak “kesin indekslenme” anlamına gelmez. Google, tarama ve indeksleme için sabit süre garantisi vermiyor.

Yeni veya önemli ölçüde değiştirilmiş birkaç URL için Search Console'daki URL Denetleme aracı kullanılabilir. Çok sayıda URL için sitemap, Google'ın URL'leri keşfetmesine yardımcı olan yöntemlerden biridir.

## Tarama isteğini sıralama garantisi gibi görmeyin

Google'ın yeniden tarama belgesi, tarama isteğinin arama sonuçlarına anında veya kesin dahil edilme garantisi olmadığını açıkça belirtir. Aynı URL için tekrar tekrar istek göndermek de taramayı hızlandırmaz.

Bu nedenle şu tür kesin vaatlerden kaçının:

- “24 saatte Google'da çıkar.”
- “Bir haftada ilk sayfaya gelir.”
- “Doğrulamadan sonra sıralama garanti olur.”
- “Aynı isteği çok kez gönderirsek daha hızlı indekslenir.”

Bu ifadelerin hiçbiri Google'ın resmi belgeleri tarafından garanti edilmiyor.

## Profil yayınlandıktan sonra bilgileri güncel tutun

İşletme adı, adres, telefon veya çalışma saatleri değiştiğinde Google profilini de güncelleyin. Google, normal çalışma saatlerine ek olarak tatil veya geçici dönemler için özel çalışma saatlerinin girilebildiğini belirtiyor.

Özellikle adres değişikliği gibi büyük değişikliklerde yeniden doğrulama gerekebilir. Bu nedenle profil bir kez açılıp unutulacak sabit bir kayıt olarak görülmemelidir.

## Uygulama kontrol listesi

İşletmenizi Google'da yönetirken şu sırayla ilerleyebilirsiniz:

1. Google'da mevcut işletme profilinizi arayın.
2. Yoksa uygunluk koşullarını kontrol ederek ekleyin; varsa sahiplenin.
3. İşletme adı, adres/hizmet bölgesi, kategori, telefon ve çalışma saatlerini gerçek bilgilerle doldurun.
4. Google'ın profiliniz için sunduğu doğrulama yöntemini tamamlayın.
5. Kendi web sayfanızın taranabilir ve indekslenebilir olduğundan emin olun.
6. Gerekirse Search Console ile URL Denetleme veya sitemap kullanın.
7. İşletme bilgileri değiştikçe profilinizi ve web sayfanızı güncel tutun.

Bu rehber, Google'da belirli bir sıralama veya belirli sürede indekslenme vaadi vermez; yalnız Google'ın güncel resmi belgelerinde doğrulanabilen adımları açıklar.`,
    cozduguSoru:
      "Bir işletme Google İşletme Profili ve kendi web sayfası için hangi doğrulanmış adımları izleyebilir, hangi sonuçları ise garanti olarak görmemelidir?",
    kategori: "Google ve Keşfedilme",
    icerikTuru: "rehber",
    sektorler: [],
    yazar: { ad: "Vixrex", tur: "kurum", url: "/hakkimizda" },
    inceleyen: null,
    kaynaklar: [
      {
        baslik: "Google İşletme Profili Yardım — İşletmenizin Google'da gösterilmesiyle ilgili kurallar",
        url: "https://support.google.com/business/answer/3038177?hl=tr",
      },
      {
        baslik: "Google İşletme Profili Yardım — İşletme Profilinizi düzenleme",
        url: "https://support.google.com/business/answer/3039617?hl=tr",
      },
      {
        baslik: "Google Business Profile Help — Verify your business on Google",
        url: "https://support.google.com/business/answer/7107242",
      },
      {
        baslik: "Google Search Central — Technical requirements",
        url: "https://developers.google.com/search/docs/essentials/technical",
      },
      {
        baslik: "Google Search Central — Ask Google to recrawl your URLs",
        url: "https://developers.google.com/search/docs/crawling-indexing/ask-google-to-recrawl",
      },
      {
        baslik: "Google Search Central — Creating helpful, reliable, people-first content",
        url: "https://developers.google.com/search/docs/fundamentals/creating-helpful-content?hl=tr",
      },
    ],
    urunDogrulamaOrtami: null,
    kapak: null,
    kapakAlt: null,
    gorselKaynagi: null,
    gorselKullanimHakki: null,
    yayinTarihi: null,
    guncellemeTarihi: null,
    sonKontrolTarihi: "2026-09-10",
    guncellemeNotlari: [],
    durum: "taslak",
    kontrolSinifi: "harici_platform",
    ilgiliYazilar: ["kuafor-icin-internet-sitesi"],
    asistanKullaniminaUygun: false,
    yayinda: false,
  },
];

const GUN_MS = 24 * 60 * 60 * 1000;

/**
 * Planın kontrol hedefleri:
 * - Haricî platform rehberi: en geç 60 günde yeniden kontrol.
 * - Genel işletme rehberi: 90 günde yeniden kontrol.
 * - Vixrex ürün değişiklikleri: zaman sayacıyla değil ürün değiştiğinde.
 *
 * 30–60 günlük Google kontrol penceresinin üst sınırı olan 60 gün,
 * otomatik "inceleme gerekli" eşiğidir; 30. gün içerik eskimiş sayılmaz.
 */
function otomatikKontrolEsigiGun(yazi: BlogYazisi): number | null {
  if (yazi.kontrolSinifi === "harici_platform") return 60;
  if (yazi.kontrolSinifi === "vixrex_urun") return null;
  return 90;
}

function isoTarihMs(iso: string | null): number | null {
  if (!iso) return null;
  const ms = Date.parse(`${iso}T00:00:00Z`);
  return Number.isNaN(ms) ? null : ms;
}

export function yaziDurumunuHesapla(
  yazi: BlogYazisi,
  bugun = new Date()
): BlogDurumu {
  if (yazi.durum === "arsiv") return "arsiv";
  if (!yazi.yayinda || yazi.durum === "taslak") return "taslak";
  if (yazi.durum === "inceleme_gerekli") return "inceleme_gerekli";

  const esikGun = otomatikKontrolEsigiGun(yazi);
  if (esikGun === null) return "yayinda";

  const kontrolMs = isoTarihMs(yazi.sonKontrolTarihi);
  if (kontrolMs === null) return "inceleme_gerekli";

  const gecenGun = Math.floor((bugun.getTime() - kontrolMs) / GUN_MS);
  return gecenGun > esikGun ? "inceleme_gerekli" : "yayinda";
}

/**
 * Yayın anahtarına ek kalite kapısı. İçerik eksikliği yazıyı otomatik
 * düzeltmez; yalnız yanlışlıkla yayına açılmasını engeller.
 */
export function yaziYayinKalitesiUygun(yazi: BlogYazisi): boolean {
  if (!yazi.cozduguSoru.trim() || !yazi.yazar.ad.trim()) return false;
  if (!yazi.sonKontrolTarihi.trim()) return false;

  if (
    yazi.kaynaklar.some(
      (kaynak) => !kaynak.baslik.trim() || !/^https:\/\//i.test(kaynak.url)
    )
  ) {
    return false;
  }

  if (yazi.kontrolSinifi === "harici_platform" && yazi.kaynaklar.length === 0) {
    return false;
  }

  if (yazi.kontrolSinifi === "vixrex_urun" && !yazi.urunDogrulamaOrtami?.trim()) {
    return false;
  }

  if (yazi.kapak) {
    if (!yazi.kapakAlt?.trim()) return false;
    if (!yazi.gorselKaynagi?.trim()) return false;
    if (!yazi.gorselKullanimHakki?.trim()) return false;
  }

  if (yazi.yayinTarihi) {
    if (yazi.sonKontrolTarihi < yazi.yayinTarihi) return false;

    if (yazi.guncellemeTarihi) {
      if (yazi.guncellemeTarihi < yazi.yayinTarihi) return false;
      if (
        yazi.guncellemeTarihi !== yazi.yayinTarihi &&
        yazi.guncellemeNotlari.length === 0
      ) {
        return false;
      }
    }
  }

  return true;
}

function yayinaUygun(yazi: BlogYazisi): yazi is YayindakiBlogYazisi {
  return (
    yazi.yayinda === true &&
    yazi.durum !== "taslak" &&
    yazi.durum !== "arsiv" &&
    typeof yazi.yayinTarihi === "string" &&
    yazi.yayinTarihi.length > 0 &&
    yaziYayinKalitesiUygun(yazi)
  );
}

/** Taslak ve arşiv içerikleri dışarı sızdırmadan yeniden eskiye sıralar. */
export function yayindakiYazilar(): YayindakiBlogYazisi[] {
  return BLOG_YAZILARI.filter(yayinaUygun).sort((a, b) =>
    b.yayinTarihi.localeCompare(a.yayinTarihi)
  );
}

/** Yayındaki bir yazıyı adresinden bulur. Taslak/arşiv asla dönmez. */
export function yaziyiBul(slug: string): YayindakiBlogYazisi | undefined {
  return yayindakiYazilar().find((yazi) => yazi.slug === slug);
}

export function blogYayindaMi(): boolean {
  return yayindakiYazilar().length > 0;
}

/** Süresi dolan veya editörce işaretlenen yazıları tek yerde toplar. */
export function incelemeGerekenYazilar(bugun = new Date()): BlogYazisi[] {
  return BLOG_YAZILARI.filter(
    (yazi) => yazi.yayinda && yaziDurumunuHesapla(yazi, bugun) === "inceleme_gerekli"
  );
}

/** Blog ve yazı sitemap lastmod için yalnız anlamlı yayın/güncelleme tarihleri. */
export function blogSonAnlamliDegisiklikTarihi(): string | null {
  const tarihler = yayindakiYazilar()
    .map((yazi) => yazi.guncellemeTarihi || yazi.yayinTarihi)
    .filter((tarih): tarih is string => Boolean(tarih))
    .sort((a, b) => b.localeCompare(a));

  return tarihler[0] || null;
}

/** Boş kategorileri göstermemek için yayımlanmış içerikten kategori listesi üretir. */
export function aktifBlogKategorileri(): BlogKategori[] {
  const aktif = new Set(yayindakiYazilar().map((yazi) => yazi.kategori));
  return BLOG_KATEGORILERI.filter((kategori) => aktif.has(kategori));
}

/** En fazla üç ilgili içerik; yalnız yayımlanmış yazılardan. */
export function ilgiliYazilariBul(yazi: BlogYazisi): YayindakiBlogYazisi[] {
  if (yazi.ilgiliYazilar.length === 0) return [];
  const yayin = new Map(yayindakiYazilar().map((aday) => [aday.slug, aday]));
  return yazi.ilgiliYazilar
    .map((slug) => yayin.get(slug))
    .filter((aday): aday is YayindakiBlogYazisi => Boolean(aday))
    .slice(0, 3);
}
