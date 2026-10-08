import {
  firmaAnahtariniCoz,
  firmaKataloguVarMi,
  satirdaHavuzMarkasiBul,
  ureticiAramasi,
} from "@/lib/ureticiKatalog";
import {
  dinamikUrunIzleriniBul,
  tedarikciDijitalIziBul,
  type DijitalIzAramaDurumu,
  type DijitalIzBagimliliklari,
  type DijitalIzHedefi,
  type TedarikciDijitalIzi,
} from "@/lib/faturaDijitalIz";
import { firmaSitesiniAra } from "@/lib/firmaArama";
import { firmaSiteDurumuKur } from "@/lib/firmaSiteDurumu";
import { siteFirmayaAitMi } from "@/lib/firmaDogrula";
import { kartaGirecekGorsel, sayfadanUrunAciklamasi } from "@/lib/faturaGorsel";

const LUNA_ADRES = "https://openrouter.ai/api/v1/responses";
const LUNA_MODEL = "openai/gpt-5.6-luna";

function lunaCiktiMetni(govde: { output_text?: unknown; output?: unknown }): string {
  if (typeof govde.output_text === "string" && govde.output_text.trim()) return govde.output_text;
  if (!Array.isArray(govde.output)) return "";
  const parcalar: string[] = [];
  for (const oge of govde.output) {
    const kayit = oge as { type?: unknown; content?: unknown };
    if (kayit.type !== "message" || !Array.isArray(kayit.content)) continue;
    for (const icerik of kayit.content) {
      const parca = icerik as { type?: unknown; text?: unknown };
      if (parca.type === "output_text" && typeof parca.text === "string") parcalar.push(parca.text);
    }
  }
  return parcalar.join("");
}

export interface LunaEslestirBagimliligi {
  fetcher?: (input: string, init?: RequestInit) => Promise<Response>;
  apiAnahtari?: string;
  model?: string;
}

function lunaAnahtari(bag?: LunaEslestirBagimliligi, dijital?: DijitalIzBagimliliklari): string {
  return (
    bag?.apiAnahtari ??
    (dijital?.firmaArama?.apiAnahtari as string | undefined) ??
    process.env.OPENROUTER_API_KEY ??
    ""
  ).trim();
}

async function lunaAyniUrunMu(
  satir: HamFaturaSatiri,
  aday: { ad: string; kod?: string; barkod?: string; marka?: string; aciklama?: string },
  bag: LunaEslestirBagimliligi = {},
): Promise<boolean | null> {
  const anahtar = (bag.apiAnahtari ?? process.env.OPENROUTER_API_KEY ?? "").trim();
  if (!anahtar) return null;
  const fetcher = bag.fetcher ?? fetch;
  const model = (bag.model ?? LUNA_MODEL).trim() || LUNA_MODEL;
  const satirMetni = `model:${satir.model} ad:${satir.ad} barkod:${satir.barkod} marka:${satir.marka ?? ""} varyant:${satir.varyant} beden:${satir.beden}`;
  const adayMetni = `ad:${aday.ad} kod:${aday.kod ?? ""} barkod:${aday.barkod ?? ""} marka:${aday.marka ?? ""} aciklama:${(aday.aciklama ?? "").slice(0, 300)}`;
  try {
    const yanit = await fetcher(LUNA_ADRES, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${anahtar}` },
      signal: AbortSignal.timeout(60000),
      body: JSON.stringify({
        model,
        max_output_tokens: 256,
        reasoning: { effort: "low" },
        text: {
          format: {
            type: "json_schema",
            name: "eslesme_karar",
            strict: true,
            schema: { type: "object", additionalProperties: false, required: ["ayni"], properties: { ayni: { type: "boolean" } } },
          },
        },
        input: [{ role: "user", content: [{ type: "input_text", text: `Fatura satırı ile katalog adayı aynı ürün mü? Yalnız JSON döndür.\nSATIR: ${satirMetni}\nADAY: ${adayMetni}` }] }],
      }),
    });
    if (!yanit.ok) return null;
    const govde = (await yanit.json().catch(() => null)) as { output_text?: unknown; output?: unknown } | null;
    if (!govde) return null;
    const ayni = (JSON.parse(lunaCiktiMetni(govde)) as { ayni?: unknown }).ayni;
    return typeof ayni === "boolean" ? ayni : null;
  } catch {
    return null;
  }
}
// Fatura satırını üretici kataloğuyla buluşturan TEK yer.
//
// Bilerek fotoğrafı KİM okursa okusun (telefon uygulaması, Başak, ileride
// tarayıcı) bu fonksiyona aynı şekilde girer. Katalog eşleştirme mantığı
// burada tek kopya durur; farklı okuyucular kendi eşleştirme kuralını
// yazmaz — ikinci bir "hangi ürün bu" kararı hiçbir yerde tekrarlanmaz.

export interface HamFaturaSatiri {
  hamSatir?: string;
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  marka?: string;
  adet: number | null;
  alisBirimFiyat: number | null;
  satirToplam: number | null;
  guven: number;
  siteAciklama?: string;
  siteGorsel?: string;
  siteSayfa?: string;
  sayfaDogrulandi?: boolean;
}

/**
 * Her satırın dört sonuçtan biri vardır:
 * kanitli · eksik · celiski · iz-yok.
 */
export type SatirSonucu = "kanitli" | "eksik" | "celiski" | "iz-yok";

export interface KatalogBilgisi {
  firma: string;
  kaynakFirma: string;
  dayanak: "kod" | "barkod" | "ad";
  izinDurumu: "yok" | "bekliyor" | "var";
  resmiAd: string;
  marka: string;
  aciklama: string;
  gorseller: string[];
  gorselAdaylari: string[];
  varyantlar?: Array<{ ad: string; barkod: string; gorseller: string[] }>;
  kaynak: string;
}

export interface CeliskiBilgisi {
  dayanak: "kod" | "barkod" | "ad";
  adaylar: Array<{
    ad: string;
    kaynak: string;
    aciklama?: string;
    gorseller?: string[];
    kod?: string;
    barkod?: string;
    marka?: string;
  }>;
}

export interface EslesmisFaturaSatiri extends HamFaturaSatiri {
  katalog: KatalogBilgisi | null;
  sonuc: SatirSonucu;
  celiski?: CeliskiBilgisi;
  /**
   * Esnafa gösterilecek şüphe notu. Eşleşme kuruldu ama kanıt zayıfsa
   * doldurulur; dolu olan satır toplu onaydan çıkar, tek tek bakılır.
   */
  uyari?: string;
}

export function eslesmeyenSatir(satir: HamFaturaSatiri): EslesmisFaturaSatiri {
  return { ...satir, katalog: null, sonuc: "eksik" };
}

export function siteKartiniUygula(satir: EslesmisFaturaSatiri): EslesmisFaturaSatiri {
  const aciklama = (satir.siteAciklama ?? "").trim();
  const gorsel = (satir.siteGorsel ?? "").trim();
  const sayfa = (satir.siteSayfa ?? "").trim();
  if (satir.sayfaDogrulandi === true && aciklama && gorsel.startsWith("https://") && sayfa.startsWith("https://")) {
    return {
      ...satir,
      sonuc: "kanitli",
      katalog: {
        firma: satir.katalog?.firma ?? "",
        kaynakFirma: satir.katalog?.kaynakFirma ?? "",
        dayanak: satir.katalog?.dayanak === "barkod" ? "barkod" : "kod",
        izinDurumu: satir.katalog?.izinDurumu ?? "yok",
        resmiAd: satir.katalog?.resmiAd || satir.ad,
        marka: satir.katalog?.marka || satir.marka || "",
        aciklama,
        gorseller: [gorsel],
        gorselAdaylari: [gorsel],
        kaynak: sayfa,
      },
    };
  }
  if (satir.sonuc !== "kanitli" || !satir.katalog) return satir;
  return {
    ...satir,
    sonuc: "eksik",
    katalog: { ...satir.katalog, aciklama: "", gorseller: [] },
  };
}

export function faturaSatiriniEslestir(
  satir: HamFaturaSatiri,
  firmaAnahtari: string | null = null,
): EslesmisFaturaSatiri {
  const arama = ureticiAramasi({
    model: satir.model || null,
    barkod: satir.barkod || null,
    marka: satir.marka || null,
    firmaAnahtari,
  });
  if (!arama) return eslesmeyenSatir(satir);
  if (arama.tur === "celiski") {
    return {
      ...satir,
      katalog: null,
      sonuc: "celiski",
      celiski: { dayanak: arama.dayanak, adaylar: arama.adaylar },
    };
  }
  const eslesme = arama.eslesme;
  return {
    ...satir,
    sonuc: "kanitli",
    katalog: {
      firma: eslesme.firma.ad,
      kaynakFirma: eslesme.firma.ad,
      dayanak: eslesme.dayanak,
      izinDurumu: eslesme.firma.izinDurumu,
      resmiAd: eslesme.urun.ad,
      marka: eslesme.urun.marka,
      aciklama: eslesme.urun.aciklama,
      gorseller: eslesme.urun.gorseller,
      gorselAdaylari: eslesme.gorselAdaylari,
      kaynak: eslesme.urun.kaynak,
    },
  };
}

/**
 * Fatura satırlarını kataloğa bağlar ve TEDARİKÇİ TUTARLILIĞINI gözetir.
 *
 * Bir fatura tek tedarikçiden gelir. Belgede tedarikçi yazıyorsa onun
 * kataloğu öncelikli aranır. Yazmıyorsa (ölçülen gerçek faturada yazmıyordu)
 * satırların hangi firmalara dağıldığına bakılır: çoğunluk bir firmadaysa,
 * tek tük başka firmadan gelen eşleşme şüphelidir — aynı ürün kodu iki
 * firmada olabilir. O satırlar yanlış ürünle eşleşmiş olabileceği için
 * işaretlenir ve güveni düşürülür; silinmez, esnafa sorulur.
 */
export function faturaSatirlariniEslestir(
  satirlar: HamFaturaSatiri[],
  tedarikciAdi = "",
): EslesmisFaturaSatiri[] {
  const firmaAnahtari = tedarikciAdi ? firmaAnahtariniCoz(tedarikciAdi) : null;
  const eslesenler = satirlar.map((satir) => faturaSatiriniEslestir(satir, firmaAnahtari));

  const sayim = new Map<string, number>();
  for (const satir of eslesenler) {
    if (!satir.katalog) continue;
    sayim.set(satir.katalog.firma, (sayim.get(satir.katalog.firma) ?? 0) + 1);
  }
  if (sayim.size < 2) return eslesenler;

  const [baskinFirma] = [...sayim.entries()].sort((a, b) => b[1] - a[1])[0];
  return eslesenler.map((satir) => {
    if (!satir.katalog || satir.katalog.firma === baskinFirma) return satir;
    return {
      ...satir,
      guven: Math.min(satir.guven, 0.5),
      uyari: `Bu satır ${satir.katalog.firma} ürünüyle eşleşti; faturadaki diğer ürünler ${baskinFirma} firmasından. Kontrol et.`,
    };
  });
}

function kodVeyaBarkodAranabilir(satir: HamFaturaSatiri): boolean {
  const barkod = satir.barkod.replace(/\D/g, "");
  if (barkod.length >= 8) return true;
  const model = satir.model.trim().toUpperCase().replace(/[\s._\-/]/g, "");
  return model.length >= 4;
}

function markaAyrimiNotu(marka: string, faturaFirmasi: string): string {
  const faturaKismi = faturaFirmasi ? `faturayı kesen firma (${faturaFirmasi}) ile` : "faturayı kesen firma ile";
  return `Bu satırda "${marka}" markası geçiyor; ${faturaKismi} marka ayrı. Ürün izi markanın kaynağından araştırılmalı.`;
}

export const KAYNAK_ERISILEMEDI_NOTU =
  "Kaynağa tam erişilemedi ya da arama süresi doldu; bu ürünün kaynakta olmadığı anlamına gelmez. Tekrar denenebilir.";

export const MARKA_KAYNAGINDA_YOK_NOTU =
  "Satırdaki markanın resmî kaynağında bu ürün bulunamadı. Tahmin yapılmadı.";

function sonuclandir(
  satirlar: EslesmisFaturaSatiri[],
  tedarikciIz: TedarikciDijitalIzi | null,
  aramaDurumu: DijitalIzAramaDurumu = { erisimHatasi: false, sinirDoldu: false },
  markaAranan: ReadonlySet<number> = new Set<number>(),
): EslesmisFaturaSatiri[] {
  const faturaFirmasi = tedarikciIz?.firma ?? "";
  const tedarikciAnahtari = tedarikciIz?.anahtar ?? null;

  return satirlar.map((satir, indeks) => {
    if (satir.katalog || satir.sonuc === "celiski") return satir;

    if (markaAranan.has(indeks)) {
      const yarimKaldi = aramaDurumu.erisimHatasi || aramaDurumu.sinirDoldu;
      return {
        ...satir,
        sonuc: "iz-yok",
        uyari: yarimKaldi ? KAYNAK_ERISILEMEDI_NOTU : MARKA_KAYNAGINDA_YOK_NOTU,
      };
    }

    const marka = satirdaHavuzMarkasiBul(
      `${satir.ad} ${satir.varyant}`,
      tedarikciAnahtari,
    );
    if (marka) {
      return {
        ...satir,
        sonuc: "eksik",
        uyari: markaAyrimiNotu(marka.ad, faturaFirmasi),
      };
    }

    if (tedarikciIz && kodVeyaBarkodAranabilir(satir)) {
      const yarimKaldi = aramaDurumu.erisimHatasi || aramaDurumu.sinirDoldu;
      return yarimKaldi
        ? { ...satir, sonuc: "iz-yok", uyari: KAYNAK_ERISILEMEDI_NOTU }
        : { ...satir, sonuc: "iz-yok" };
    }
    return satir.sonuc === "eksik" ? satir : { ...satir, sonuc: "eksik" };
  });
}

export interface FaturaDijitalIzSonucu {
  satirlar: EslesmisFaturaSatiri[];
  tedarikciIz: TedarikciDijitalIzi | null;
  aramaDurumu: DijitalIzAramaDurumu;
}

export async function faturaSatirlariniDijitalIzle(
  satirlar: HamFaturaSatiri[],
  tedarikciAdi = "",
  tedarikciSite = "",
  bagimliliklar: DijitalIzBagimliliklari = {},
): Promise<FaturaDijitalIzSonucu> {
  // Luna-tek-yol: site Luna'dan, aday Luna web_search'ten, açıklama+görsel
  // Luna'dan. Deterministik havuz/tarama bu hatta çalışmaz. Anahtar yoksa
  // satırlar eksik döner (tahmin yok).
  const { alanAdiTemizle } = await import("@/lib/ureticiKatalog");
  let alan = alanAdiTemizle(tedarikciSite);
  let aramaKapali = false;
  if (!alan && tedarikciAdi.trim().length >= 3) {
    const arama = await firmaSitesiniAra(tedarikciAdi, {
      ...(bagimliliklar.tedarikciKimligi ? { kimlik: bagimliliklar.tedarikciKimligi } : {}),
      dogrula: { fetcher: bagimliliklar.fetcher, resolveHost: bagimliliklar.resolveHost },
      ...(bagimliliklar.firmaArama ?? {}),
    });
    if (arama.durum === "bulundu") {
      alan = arama.alan;
    } else if (arama.durum === "kapali") {
      aramaKapali = true;
    }
  }
  const tedarikciIz: TedarikciDijitalIzi | null = alan
    ? {
      anahtar: null,
      firma: tedarikciAdi.trim() || alan,
      alan,
      platform: "",
      izinDurumu: "yok",
      kaynak: `https://${alan}`,
      havuzda: false,
    }
    : null;

  const aramaDurumu: DijitalIzAramaDurumu = bagimliliklar.durum ?? {
    erisimHatasi: false,
    sinirDoldu: false,
  };
  const nihai = satirlar.map((satir) => eslesmeyenSatir(satir));
  await lunaAdayBul(nihai, tedarikciIz, bagimliliklar);

  aramaDurumu.siteDurumu = firmaSiteDurumuKur({
    firmaAdi: tedarikciAdi,
    dogrulananAdres: tedarikciIz?.kaynak ?? null,
    aramaKapali,
  });

  return {
    satirlar: nihai,
    tedarikciIz,
    aramaDurumu,
  };
}

async function lunaAdayBul(
  satirlar: EslesmisFaturaSatiri[],
  tedarikciIz: TedarikciDijitalIzi | null,
  bagimliliklar: DijitalIzBagimliliklari = {},
): Promise<void> {
  const anahtar = lunaAnahtari(undefined, bagimliliklar);
  if (!anahtar || !tedarikciIz?.alan) return;
  const alan = tedarikciIz.alan;
  const fetcher = bagimliliklar.fetcher ?? fetch;
  for (const satir of satirlar) {
    if (satir.katalog || satir.sonuc === "celiski") continue;
    if (!satir.model && !satir.ad && !satir.barkod) continue;
    try {
      const arama = await lunaSatirArama(alan, satir, fetcher, anahtar);
      if (!arama) continue;
      const aciklama = await sayfadanUrunAciklamasi(arama.sayfa, { model: satir.model, ad: satir.ad }, { fetcher, apiAnahtari: anahtar });
      if (!aciklama) continue;
      const gorsel = await kartaGirecekGorsel(arama.gorsel, { model: satir.model, ad: satir.ad }, { fetcher, apiAnahtari: anahtar });
      if (!gorsel) continue;
      const karar = siteKartiniUygula(eslesmeyenSatir({
        ...satir,
        siteAciklama: aciklama,
        siteGorsel: gorsel,
        siteSayfa: arama.sayfa,
        sayfaDogrulandi: true,
      }));
      if (karar.sonuc === "kanitli" && karar.katalog) {
        satir.katalog = karar.katalog;
        satir.sonuc = "kanitli";
        satir.siteAciklama = aciklama;
        satir.siteGorsel = gorsel;
        satir.siteSayfa = arama.sayfa;
        satir.sayfaDogrulandi = true;
        satir.uyari = undefined;
      }
    } catch {
      continue;
    }
  }
}

async function lunaSatirArama(
  alan: string,
  satir: HamFaturaSatiri,
  fetcher: (input: string, init?: RequestInit) => Promise<Response>,
  anahtar: string,
): Promise<{ gorsel: string; sayfa: string } | null> {
  const { satirSitesindeAra } = await import("@/lib/faturaGoru");
  try {
    const arama = await satirSitesindeAra(
      { alan, model: satir.model, ad: satir.ad, barkod: satir.barkod },
      { fetcher, apiAnahtari: anahtar },
    );
    if (!arama.gorsel || !arama.sayfa) return null;
    return { gorsel: arama.gorsel, sayfa: arama.sayfa };
  } catch {
    return null;
  }
}

async function lunaVetoUygula(
  satirlar: EslesmisFaturaSatiri[],
  bagimliliklar: DijitalIzBagimliliklari = {},
): Promise<void> {
  const anahtar = lunaAnahtari(undefined, bagimliliklar);
  if (!anahtar) return;
  const fetcher = bagimliliklar.fetcher ?? fetch;
  for (const satir of satirlar) {
    if (satir.sonuc !== "kanitli" || !satir.katalog) continue;
    const karar = await lunaAyniUrunMu(
      satir,
      { ad: satir.katalog.resmiAd, marka: satir.katalog.marka, aciklama: satir.katalog.aciklama },
      { fetcher, apiAnahtari: anahtar },
    );
    if (karar === false) {
      satir.sonuc = "eksik";
      satir.uyari = "Luna bu satırla kataloğu aynı ürün saymadı; kontrol et.";
      satir.katalog = null;
    }
  }
}

function hedefiSatiraYaz(
  sonuc: EslesmisFaturaSatiri[],
  indeks: number,
  hedef: DijitalIzHedefi | null,
  iz: TedarikciDijitalIzi,
): void {
  if (!hedef) return;

  if ("celiski" in hedef) {
    sonuc[indeks] = {
      ...sonuc[indeks],
      katalog: null,
      sonuc: "celiski",
      celiski: { dayanak: hedef.dayanak, adaylar: hedef.adaylar },
    };
    return;
  }

  sonuc[indeks] = {
    ...sonuc[indeks],
    sonuc: "kanitli",
    katalog: {
      firma: iz.firma,
      kaynakFirma: iz.firma,
      dayanak: hedef.dayanak,
      izinDurumu: iz.izinDurumu,
      resmiAd: hedef.urun.ad,
      marka: hedef.urun.marka,
      aciklama: hedef.urun.aciklama,
      gorseller: hedef.urun.gorseller,
      gorselAdaylari: hedef.gorselAdaylari,
      varyantlar: hedef.varyantlar,
      kaynak: hedef.urun.kaynak || iz.kaynak,
    },
  };
}

function markaAdiSade(ham: string): string {
  return ham
    .toLocaleLowerCase("tr-TR")
    .replace(/[^a-z0-9çğıöşü]/g, "");
}

async function markaKaynaginda(
  sonuc: EslesmisFaturaSatiri[],
  tedarikciIz: TedarikciDijitalIzi | null,
  tedarikciAdi: string,
  bagimliliklar: DijitalIzBagimliliklari,
  aramaDurumu: DijitalIzAramaDurumu,
): Promise<Set<number>> {
  const aranan = new Set<number>();
  const faturaFirmalari = [tedarikciAdi, tedarikciIz?.firma ?? ""].map(markaAdiSade).filter(Boolean);
  const gruplar = new Map<string, number[]>();

  sonuc.forEach((satir, indeks) => {
    if (satir.katalog || satir.sonuc === "celiski" || !kodVeyaBarkodAranabilir(satir)) return;

    const havuzMarkasi = satirdaHavuzMarkasiBul(
      `${satir.ad} ${satir.varyant}`,
      tedarikciIz?.anahtar ?? null,
    );
    const markaAdi = (satir.marka ?? "").trim() || havuzMarkasi?.ad || "";
    const sade = markaAdiSade(markaAdi);
    if (!sade || faturaFirmalari.some((firma) => firma === sade || firma.includes(sade) || sade.includes(firma))) {
      return;
    }
    gruplar.set(markaAdi, [...(gruplar.get(markaAdi) ?? []), indeks]);
  });

  for (const [markaAdi, indeksler] of gruplar) {
    let markaIz = tedarikciDijitalIziBul(markaAdi, "");
    let dogrulama: NonNullable<TedarikciDijitalIzi["dogrulama"]> | undefined;
    if (!markaIz) {
      const arama = await firmaSitesiniAra(markaAdi, {
        kimlik: { vergiNo: "", adres: "" },
        dogrula: { fetcher: bagimliliklar.fetcher, resolveHost: bagimliliklar.resolveHost },
        ...(bagimliliklar.firmaArama ?? {}),
      });
      if (arama.durum !== "bulundu") continue;
      dogrulama = arama.dogrulama;
      markaIz = {
        anahtar: null,
        firma: markaAdi,
        alan: arama.alan,
        platform: "",
        izinDurumu: "yok",
        kaynak: arama.kaynak,
        havuzda: false,
        ...(dogrulama ? { dogrulama } : {}),
      };
    }

    const dinamik = await dinamikUrunIzleriniBul(
      indeksler.map((indeks) => ({ ...sonuc[indeks] })),
      markaIz,
      { ...bagimliliklar, durum: aramaDurumu },
    );
    indeksler.forEach((indeks, sira) => {
      aranan.add(indeks);
      hedefiSatiraYaz(sonuc, indeks, dinamik[sira], markaIz as TedarikciDijitalIzi);
    });
  }

  return aranan;
}

export function sonucOzeti(
  satirlar: EslesmisFaturaSatiri[],
): Record<"kanitli" | "eksik" | "celiski" | "izYok", number> {
  const ozet = { kanitli: 0, eksik: 0, celiski: 0, izYok: 0 };
  for (const satir of satirlar) {
    if (satir.sonuc === "iz-yok") ozet.izYok += 1;
    else ozet[satir.sonuc] += 1;
  }
  return ozet;
}
