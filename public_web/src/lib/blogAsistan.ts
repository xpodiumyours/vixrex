import {
  BLOG_BASLIK_EN_AZ,
  BLOG_BASLIK_EN_FAZLA,
  BLOG_OZET_EN_AZ,
  BLOG_OZET_EN_FAZLA,
} from "./blogSeo";

export interface VitrinOzeti {
  slug: string;
  ad: string;
  kategori: string;
  il?: string;
  ilce?: string;
  adres?: string;
  calismaSaatleri?: string;
  whatsapp?: string;
  urunler: string[];
}

export interface BlogKonusu {
  konu: string;
  baslik: string;
  gerekce: string;
}

export interface BlogTaslagi {
  baslik: string;
  ozet: string;
  icerik: string;
  hedefKonu: string;
  hedefSehir: string;
  tur: string;
  notlar: string[];
}

export const BLOG_TAZELEME_GUN = 120;

function temiz(deger: string | undefined): string {
  return (deger ?? "").trim().replace(/\s+/g, " ");
}

function yer(vitrin: VitrinOzeti): string {
  return temiz(vitrin.ilce) || temiz(vitrin.il);
}

function olcuMetni(
  metin: string,
  enAz: number,
  enFazla: number,
  ekler: readonly string[]
): string {
  const kelimeler = temiz(metin).replace(/[:;,.\u2013-]+$/, "").split(" ");
  let sonuc = kelimeler.join(" ");
  while (sonuc.length > enFazla && kelimeler.length > 4) {
    kelimeler.pop();
    sonuc = kelimeler.join(" ").replace(/[:;,.\u2013-]+$/, "");
  }
  for (const ek of ekler) {
    if (sonuc.length >= enAz) break;
    if (sonuc.length + ek.length <= enFazla) sonuc = `${sonuc}${ek}`;
  }
  return sonuc;
}

/**
 * Konu listesi yalnız iki kaynaktan üretilir: işletmenin kategorisi ve kendi
 * ürün adları. Uydurma istatistik, fiyat veya iddia yok — yazı sahibin
 * kendi verisini anlattığı bir iskelet olarak kalır.
 */
export function blogKonulariUret(vitrin: VitrinOzeti): BlogKonusu[] {
  const kategori = temiz(vitrin.kategori) || "işletme";
  const konum = yer(vitrin);
  const konular: BlogKonusu[] = [];

  if (konum) {
    konular.push({
      konu: `${konum} ${kategori}`,
      baslik: `${konum} ${kategori}: nelere dikkat etmeli?`,
      gerekce: `Şehir ve kategori adı geçen aramalar yerel sıralamada çalışır: “${konum} ${kategori}”.`,
    });
  }

  konular.push({
    konu: `${kategori} randevusu`,
    baslik: `${kategori} randevusu nasıl alınır?`,
    gerekce: "Randevu ve iletişim soruları, satın almaya en yakın arama niyetidir.",
  });

  const urun = temiz(vitrin.urunler[0]);
  if (urun) {
    konular.push({
      konu: `${urun}`,
      baslik: `${urun} hakkında bilmeniz gerekenler`,
      gerekce: `Vitrininizde zaten sunduğunuz “${urun}” için arama hacmi olan bir konu.`,
    });
  }

  konular.push({
    konu: `${kategori} seçimi`,
    baslik: `${kategori} seçerken nelere bakılır?`,
    gerekce: "Karar aşamasındaki ziyaretçi için karşılaştırma içeriği; vitrine dönüş trafiği üretir.",
  });

  return konular;
}

function icerikMetni(vitrin: VitrinOzeti, konu: string): string {
  const kategori = temiz(vitrin.kategori) || "işletme";
  const konum = yer(vitrin);
  const ad = temiz(vitrin.ad) || "işletmemiz";
  const bolge = konum || "çevreniz";
  const saatler = temiz(vitrin.calismaSaatleri);
  const adres = temiz(vitrin.adres);
  const whatsapp = temiz(vitrin.whatsapp);
  const urunler = vitrin.urunler.map(temiz).filter(Boolean).slice(0, 8);

  const hizmetListesi = urunler.length
    ? `<ul>${urunler.map((urun) => `<li>${urun}</li>`).join("")}</ul>`
    : `<p>${kategori} kapsamındaki hizmet ve ürünlerimizin güncel listesi vitrinimizde yer alır.</p>`;

  const iletisimParcalari = [
    adres
      ? `Adresimiz: ${adres}. Tarif için vitrinimizdeki konum bölümünü kullanabilirsiniz.`
      : `Konum ve tarif bilgisi vitrinimizin iletişim bölümünde yer alır.`,
    saatler
      ? `Çalışma saatlerimiz: ${saatler}.`
      : "Çalışma saatlerimizi aramadan önce vitrinimizden kontrol edebilirsiniz.",
    whatsapp
      ? `WhatsApp üzerinden yazabilir, hizmet öncesi sorularınızı doğrudan iletebilirsiniz.`
      : "Sorularınız için vitrinimizdeki iletişim kanallarını kullanabilirsiniz.",
  ].join(" ");

  return [
    `<p>${bolge} çevresinde ${kategori} arıyorsanız, doğru işletmeyi seçmek ve süreci baştan bilmek işinizi kolaylaştırır. ${ad} olarak bu yazıda “${konu}” konusunu, hizmet almadan önce sorulması gereken sorularla birlikte topladık. Amaç net: görüşmeye hazır gitmeniz ve beklentinizi baştan netleştirmeniz.</p>`,
    `<h2>${kategori} hizmeti almadan önce neye bakılır?</h2>`,
    `<p>İlk bakılacak başlık kapsam: hangi hizmetlerin verildiği, çalışma saatleri ve işletmenin konumu. Aynı hizmet farklı işletmelerde farklı kapsamda sunulabilir; bu yüzden ihtiyacınızı önceden bir cümleyle yazmanız görüşmeyi kısaltır. İkinci başlık süreklilik: hizmet sonrası destek, garanti ve tekrar ihtiyaç hâlinde aynı ekibe ulaşabilme imkânı.</p>`,
    `<p>Üçüncü başlık şeffaflık: hizmetin kapsamı, süresi ve fiyatın neye göre belirlendiği önceden açıkça konuşulmalı. Bu üç başlığı netleştiren bir işletmeyle çalışmak, sonradan yaşanan anlaşmazlıkların çoğunu baştan engeller.</p>`,
    `<h2>Hizmetlerimiz</h2>`,
    hizmetListesi,
    `<p>Ürün ve hizmet listemizin tamamına, güncel görsellerle birlikte <a href="/v/${vitrin.slug}">vitrin sayfamızdan</a> ulaşabilirsiniz.</p>`,
    `<h2>Nasıl çalışıyoruz?</h2>`,
    `<p>Hizmet öncesinde ihtiyacınızı dinliyor, kapsamı ve süreyi birlikte netleştiriyoruz. ${iletisimParcalari}</p>`,
    `<h2>Görüşmeye gitmeden önce hazırlık listesi</h2>`,
    `<ul>`,
    `<li>İhtiyacınızı tek cümleyle yazın: hangi hizmet, hangi bölge ve hangi zaman aralığı.</li>`,
    `<li>Bütçe aralığınızı belirleyin; işletme size gerçekçi seçenekleri daha hızlı sunar.</li>`,
    `<li>Varsa önceki deneyiminizi, tercih ettiğiniz ürün veya yöntemi paylaşın.</li>`,
    `<li>Randevunun süresini ve olası değişiklik koşulunu önceden sorun.</li>`,
    `<li>Hizmet sonrası bakım ve garanti koşullarını net olarak öğrenin.</li>`,
    `</ul>`,
    `<p>Bu maddeleri konuşmak, hizmet sırasında sürpriz yaşama ihtimalini azaltır ve iki tarafın da zamanını korur. Aynı listeyi birden fazla işletmeyle konuşursanız karşılaştırmanız da kolaylaşır.</p>`,
    `<h2>Sık sorulan sorular</h2>`,
    `<h3>Randevu gerekiyor mu?</h3>`,
    `<p>Yoğunluğa göre değişir. Kesin bir saat için önceden haber vermeniz bekleme süresini azaltır; haber verirken hizmet adını da yazmanız hazırlığı hızlandırır.</p>`,
    `<h3>Hizmet ne kadar sürer?</h3>`,
    `<p>Süre, seçtiğiniz hizmetin kapsamına göre değişir. Görüşmeden önce süreyi sormanız, o güne dair planınızı ona göre kurmanızı sağlar.</p>`,
    `<h3>Fiyat neye göre belirlenir?</h3>`,
    `<p>Hizmetin kapsamı, süresi ve kullanılan ürünler fiyatı etkiler. Net bilgiyi, ihtiyacınızı paylaştıktan sonra doğrudan veriyoruz; bu yazı fiyat listesi yerine hazırlık rehberi olarak okunmalı.</p>`,
    `<h3>Hangi bölgeye hizmet veriyorsunuz?</h3>`,
    `<p>${bolge} çevresinde hizmet veriyoruz. Farklı bir bölgedeyseniz, önce bize yazıp uygunluk teyidi almanız en pratiği olur.</p>`,
    `<h2>Bize ulaşın</h2>`,
    `<p>${ad} hakkında daha fazlası ve diğer yazılarımız için <a href="/v/${vitrin.slug}/yazilar">yazılar sayfamıza</a> göz atabilirsiniz. Sorularınız için vitrinimizdeki iletişim kanallarından bize ulaşabilirsiniz.</p>`,
    `<p>Bu yazı genel bilgi amaçlıdır: hizmetin kapsamı, süresi ve koşulları görüşmede netleşir. Aklınıza takılan bir soru kalırsa çekinmeden sorun; doğru bilgiyi baştan almak, sonradan düzeltmekten her zaman kolaydır.</p>`,
  ].join("\n");
}

export function blogTaslagiUret(vitrin: VitrinOzeti, konu: string): BlogTaslagi {
  const kategori = temiz(vitrin.kategori) || "işletme";
  const konum = yer(vitrin);
  const ad = temiz(vitrin.ad) || "işletmemiz";
  const secilenKonu = temiz(konu) || `${kategori} hizmeti`;
  const secilenBaslik =
    blogKonulariUret(vitrin).find((aday) => aday.konu === secilenKonu)?.baslik ??
    `${secilenKonu}: ${kategori} rehberi`;

  const baslik = olcuMetni(secilenBaslik, BLOG_BASLIK_EN_AZ, BLOG_BASLIK_EN_FAZLA, [
    " için rehber",
    " hakkında bilmeniz gerekenler",
    " ve öneriler",
  ]);

  const ozet = olcuMetni(
    `${ad} olarak “${secilenKonu}” konusunu ${konum || "çevreniz"} için derledik; hizmet almadan önce sorulacak sorular ve bize ulaşma yolları bu rehberde.`,
    BLOG_OZET_EN_AZ,
    BLOG_OZET_EN_FAZLA,
    [" Kısa ve uygulanabilir bir rehber."]
  );

  const notlar = [
    "Metni kendi cümlelerinizle zenginleştirin; hazır iskelet yalnız başlangıç noktası.",
    "Kendi deneyiminizden somut bir örnek ekleyin; uydurma istatistik veya fiyat yazmayın.",
  ];
  if (!temiz(vitrin.adres)) {
    notlar.push("Adres ve konum bölümünü vitrin ayarlarından tamamlayın.");
  }
  if (!vitrin.urunler.length) {
    notlar.push("Hizmet listesi için vitrine ürün ekleyin; liste bölümü ondan beslenir.");
  }

  return {
    baslik,
    ozet,
    icerik: icerikMetni(vitrin, secilenKonu),
    hedefKonu: secilenKonu,
    hedefSehir: konum,
    tur: "standard",
    notlar,
  };
}

export interface TazelenecekYazi {
  slug: string;
  title: string;
  gun: number;
}

export function tazelemeGerektirenler(
  yazilar: readonly {
    slug: string;
    title: string;
    status: string;
    updated_at: string;
  }[],
  gunEsigi: number = BLOG_TAZELEME_GUN,
  simdi: number = Date.now()
): TazelenecekYazi[] {
  return yazilar
    .filter((yazi) => yazi.status === "published")
    .map((yazi) => {
      const guncelleme = Date.parse(yazi.updated_at);
      const gun = Number.isNaN(guncelleme)
        ? 0
        : Math.floor((simdi - guncelleme) / 86_400_000);
      return { slug: yazi.slug, title: yazi.title, gun };
    })
    .filter((yazi) => yazi.gun >= gunEsigi)
    .sort((a, b) => b.gun - a.gun);
}
