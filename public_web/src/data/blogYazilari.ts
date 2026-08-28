/**
 * VIXREX BLOGU — yazı kaynağı.
 *
 * NEDEN DOSYA, NEDEN VERİTABANI DEĞİL: `store_articles` tablosu bir vitrine
 * bağlı (`store_slug` zorunlu). Vixrex'in kendi yazısının vitrini yok; o
 * tabloya yazmak için sahte bir vitrin uydurmak gerekirdi. Yeni tablo açmak
 * ise RLS + yönetim ekranı + migration demek. Yazıları Claude taslaklayıp
 * Casper düzelttiği için dosya hem yeterli hem sürüm kontrolünde duruyor.
 *
 * YAYIN ANAHTARI: `yayinda` alanı. Casper'ın kararı — blog, Keşfet gerçek
 * vitrinlerle dolmadan yayına çıkmaz; boş blog yokluktan kötüdür. Bu yüzden
 * yazılar burada birikir, `yayinda: false` durur. Hiç yayındaki yazı yokken
 * `/blog` 404 verir ve site haritasına hiçbir şey eklenmez.
 *
 * GÖVDE BİÇİMİ: düz metin. Boş satır paragraf ayırır. Gösterim tarafında
 * `formatContent` (vitrin yazılarındaki desenin aynısı) paragraflara çevirip
 * `sanitizeHtml`'den geçirir — burada HTML yazma.
 */

export type BlogYazisi = {
  /** `/blog/<slug>` adresini kurar. Yalnız a-z, 0-9 ve tire. */
  slug: string;
  baslik: string;
  /** Liste kartında ve meta açıklamasında kullanılır. */
  ozet: string;
  /** Düz metin; boş satır = yeni paragraf. */
  govde: string;
  /** ISO tarih, "2026-09-01". */
  yayinTarihi: string;
  guncellemeTarihi: string;
  okumaDakika: number;
  /** YAYIN ANAHTARI — Casper "Keşfet doldu" diyene kadar false. */
  yayinda: boolean;
};

export const BLOG_YAZILARI: BlogYazisi[] = [
  {
    slug: "kuafor-icin-internet-sitesi",
    baslik: "Kuaför salonu için internet sitesi nasıl yapılır?",
    ozet:
      "Kuaför ve berber salonları için internet sitesinin ne işe yaradığını, " +
      "hangi bilgilerin bulunması gerektiğini ve bunu ücretsiz nasıl " +
      "yapabileceğinizi adım adım anlattık.",
    govde: `Bir kuaför salonunun internet sitesine ihtiyacı var mı? Kısa cevap: evet, ama sandığınız türden değil.

Müşteriniz size gelmeden önce üç şeyi merak eder: nerede olduğunuzu, ne kadar tuttuğunu ve nasıl randevu alacağını. Onlarca sayfalık bir site kurmanıza gerek yok. Bu üç sorunun cevabını taşıyan tek bir sayfa, çoğu salon için fazlasıyla yeterlidir.

Sayfanızda mutlaka bulunması gerekenler

Salonunuzun adı ve ne yaptığınız. "Ayşe Kuaför — kadın kuaförü, saç bakımı ve gelin saçı" gibi tek cümle yeterli. İnsanlar bunu okuduğunda doğru yerde olduklarını anlamalı.

Açık adres ve harita konumu. Semt adı yazmak yetmez; müşteri telefonundan haritaya dokunup yola çıkabilmeli.

Telefon veya WhatsApp bağlantısı. Randevu almanın en kısa yolu bu. Numarayı düz yazı olarak koymayın, dokununca arayan ya da WhatsApp açan bir bağlantı olsun.

Çalışma saatleri. "Pazartesi kapalı" bilgisini görmeyen müşteri boşuna yola çıkar ve bir daha gelmez.

Hizmetler ve fiyatlar. Fiyat yazmaktan çekinmeyin. Fiyat görmeyen müşteri en pahalı ihtimali varsayar ve aramaz bile.

Çalışmalarınızdan fotoğraflar. Kuaförlükte en güçlü satış aracı budur. Beş temiz fotoğraf, uzun bir metinden çok daha fazla iş getirir.

Alan adı almalı mısınız?

Başlangıçta gerek yok. Önce sayfanızı kurun, müşterilere gönderin, işe yarayıp yaramadığını görün. İşler yürüdüğünde kendi alan adınıza geçmek her zaman mümkün.

Instagram hesabım var, yetmez mi?

Instagram müşteri bulmak için iyidir ama bilgi vermek için kötüdür. Adresiniz nerede yazıyor? Fiyatlarınız hangi gönderinin altında kaldı? Instagram'ı vitrin sayfanıza yönlendiren bir tabela gibi düşünün: insanlar sizi orada görsün, ayrıntıyı sayfanızda bulsun.

Ne kadar sürer?

Vixrex ile bir vitrin sayfası kurmak yaklaşık on dakika sürüyor. Bilgileri yazıyorsunuz, fotoğrafları yüklüyorsunuz, sayfa yayına giriyor. Kod bilmenize, tasarımcı tutmanıza gerek yok.`,
    yayinTarihi: "2026-09-01",
    guncellemeTarihi: "2026-09-01",
    okumaDakika: 4,
    yayinda: false,
  },
  {
    slug: "isletmemi-googleda-nasil-gosteririm",
    baslik: "İşletmemi Google'da nasıl gösteririm?",
    ozet:
      "Küçük bir işletmenin Google aramalarında çıkması için yapması " +
      "gereken üç şey var. Üçü de ücretsiz ve hiçbiri teknik bilgi " +
      "gerektirmiyor.",
    govde: `"İşletmemin adını yazıyorum, Google'da çıkmıyorum." Küçük işletmelerin en sık sorduğu soru bu. Sebebi genellikle tek: Google'ın bakabileceği bir yer yok.

Google bir işletmeyi rastgele bulmaz. Sizi ancak internette bıraktığınız izlerden tanır. Üç iz yeterlidir.

1. Google İşletme Profili açın

Ücretsizdir ve en önemlisidir. Haritalarda çıkmanızı, "yakınımdaki kuaför" gibi aramalarda görünmenizi, yorum toplamanızı sağlar.

google.com/business adresinden açabilirsiniz. İşletme adı, kategori, adres, telefon ve çalışma saatlerini girin. Google adresinize kod içeren bir kart gönderir; o kodu girince profiliniz onaylanır.

Burada en çok yapılan hata kategoriyi yanlış seçmek. "Güzellik salonu" ile "kuaför" farklı aramalara çıkar. Müşterinizin sizi ararken yazacağı kelimeyi seçin.

2. Kendi sayfanız olsun

İşletme profili tek başına eksik kalır. Google, işletmenizin gerçek olduğunu doğrulamak için başka bir kaynak arar. Kendi vitrin sayfanız bu kaynaktır.

Sayfada adınız, adresiniz ve telefonunuz Google İşletme Profili'ndeki ile birebir aynı şekilde yazmalı. "Cad." ile "Caddesi" farkı bile Google'ı tereddüde düşürür. Aynı bilgiyi aynı biçimde yazmak, bu işin en ucuz ve en etkili adımıdır.

3. İnsanların aradığı kelimeleri kullanın

Kimse "estetik saç tasarım merkezi" diye aramaz. "Ümraniye kuaför" diye arar.

Sayfanızdaki metinlerde müşterinin kullandığı kelimeleri kullanın: semt adı, iş kolu, sunduğunuz hizmet. Süslü ifadeler arama motorunda işe yaramaz.

Ne kadar sürede çıkarım?

Google İşletme Profili onayı birkaç gün sürer. Vitrin sayfanızın aramalarda görünmesi genellikle bir ila dört hafta alır. Bu süreyi kısaltmanın yolu yok, ama üç adımı da tamamlamak sonucu belirgin biçimde hızlandırır.

Sabırsızlanmayın: profilinizi açtıktan sonra bilgileri sürekli değiştirmek Google'ı yavaşlatır. Bir kere doğru girin, bırakın otursun.`,
    yayinTarihi: "2026-09-01",
    guncellemeTarihi: "2026-09-01",
    okumaDakika: 4,
    yayinda: false,
  },
];

/**
 * Yalnız yayına alınmış yazılar, yeniden eskiye sıralı.
 *
 * Sayfalar, site haritası ve altbilgi HER ZAMAN bu işlevden okur —
 * `BLOG_YAZILARI` dizisine doğrudan dokunan yer olmamalı, yoksa taslak
 * bir yazı yanlışlıkla yayına sızar.
 */
export function yayindakiYazilar(): BlogYazisi[] {
  return BLOG_YAZILARI.filter((yazi) => yazi.yayinda).sort((a, b) =>
    b.yayinTarihi.localeCompare(a.yayinTarihi)
  );
}

/** Yayındaki bir yazıyı adresinden bulur. Taslakları asla döndürmez. */
export function yaziyiBul(slug: string): BlogYazisi | undefined {
  return yayindakiYazilar().find((yazi) => yazi.slug === slug);
}

/** Blog yüzeyinin görünür olup olmadığı — altbilgi ve site haritası sorar. */
export function blogYayindaMi(): boolean {
  return yayindakiYazilar().length > 0;
}
