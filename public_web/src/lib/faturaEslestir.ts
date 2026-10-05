import {
  alanAdiTemizle,
  firmaAnahtariniCoz,
  ureticiUrunAdaylariniBul,
  type KatalogEslesmesi,
  type UreticiUrunu,
} from "@/lib/ureticiKatalog";
import {
  dinamikUrunIzleriniBul,
  type DijitalIzAramaDurumu,
  type DijitalIzBagimliliklari,
  type DijitalIzHedefi,
  type TedarikciDijitalIzi,
} from "@/lib/faturaDijitalIz";
import { firmaSitesiniAra } from "@/lib/firmaArama";
import { siteFirmayaAitMi } from "@/lib/firmaDogrula";
import { firmaSitesiniModeldenBul, satirlariModeldenEslestir } from "@/lib/faturaKesif";
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
}

/**
 * Her satırın dört sonuçtan biri vardır:
 * kanitli · eksik · celiski · iz-yok.
 */
export type SatirSonucu = "kanitli" | "eksik" | "celiski" | "iz-yok";

export interface KatalogBilgisi {
  firma: string;
  kaynakFirma: string;
  dayanak: "kod" | "barkod";
  izinDurumu: "yok" | "bekliyor" | "var";
  resmiAd: string;
  marka: string;
  aciklama: string;
  gorseller: string[];
  gorselAdaylari: string[];
  varyantlar?: Array<{ ad: string; barkod: string; gorseller: string[] }>;
  kaynak: string;
}

export interface CeliskiAdayi {
  ad: string;
  kaynak: string;
  firma?: string;
  marka?: string;
  aciklama?: string;
  gorseller?: string[];
  izinDurumu?: "yok" | "bekliyor" | "var";
}

export interface CeliskiBilgisi {
  dayanak: "kod" | "barkod";
  adaylar: CeliskiAdayi[];
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

function katalogaCevir(eslesme: KatalogEslesmesi): KatalogBilgisi {
  return {
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
  };
}

function adayaCevir(eslesme: KatalogEslesmesi): CeliskiAdayi {
  return {
    ad: eslesme.urun.ad,
    kaynak: eslesme.urun.kaynak,
    firma: eslesme.firma.ad,
    marka: eslesme.urun.marka,
    aciklama: eslesme.urun.aciklama,
    gorseller: eslesme.urun.gorseller,
    izinDurumu: eslesme.firma.izinDurumu,
  };
}

export function faturaSatiriniEslestir(
  satir: HamFaturaSatiri,
  firmaAnahtari: string | null = null,
): EslesmisFaturaSatiri {
  const adaylar = ureticiUrunAdaylariniBul({
    model: satir.model || null,
    barkod: satir.barkod || null,
    marka: satir.marka || null,
    firmaAnahtari,
  });
  if (adaylar.length === 1) {
    return { ...satir, sonuc: "kanitli", katalog: katalogaCevir(adaylar[0]) };
  }
  if (adaylar.length > 1) {
    return {
      ...satir,
      katalog: null,
      sonuc: "celiski",
      celiski: {
        dayanak: adaylar[0].dayanak,
        adaylar: adaylar.map(adayaCevir),
      },
    };
  }
  return eslesmeyenSatir(satir);
}

export function satiriAdayaKilitle(
  satir: EslesmisFaturaSatiri,
  kaynak: string,
): EslesmisFaturaSatiri | null {
  const hedef = kaynak.trim();
  if (!hedef) return null;
  const aday = (satir.celiski?.adaylar ?? []).find((secenek) => secenek.kaynak === hedef);
  if (!aday) return null;
  const gorseller = (aday.gorseller ?? []).filter(Boolean);
  return {
    ...satir,
    sonuc: "kanitli",
    uyari: undefined,
    celiski: undefined,
    katalog: {
      firma: aday.firma ?? "",
      kaynakFirma: aday.firma ?? "",
      dayanak: satir.celiski?.dayanak ?? "kod",
      izinDurumu: aday.izinDurumu ?? "yok",
      resmiAd: aday.ad,
      marka: aday.marka ?? "",
      aciklama: aday.aciklama ?? "",
      gorseller,
      gorselAdaylari: gorseller,
      kaynak: aday.kaynak,
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

    const marka = (satir.marka ?? "").trim();
    if (marka && faturaFirmasi && markaAdiSade(marka) !== markaAdiSade(faturaFirmasi)) {
      return {
        ...satir,
        sonuc: "eksik",
        uyari: markaAyrimiNotu(marka, faturaFirmasi),
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

function siteIzindenKur(firma: string, site: string): TedarikciDijitalIzi | null {
  const alan = alanAdiTemizle(site);
  if (!alan) return null;
  return {
    anahtar: null,
    firma: firma.trim() || alan,
    alan,
    platform: "",
    izinDurumu: "yok",
    kaynak: `https://${alan}`,
    havuzda: false,
  };
}

function toplananUrunler(durum: DijitalIzAramaDurumu): UreticiUrunu[] {
  const devam = durum.devam;
  if (!devam) return [];
  const gorulen = new Set<string>();
  const liste: UreticiUrunu[] = [];
  for (const kayit of Object.values(devam)) {
    for (const urun of kayit.urunler) {
      const kimlik = `${urun.kaynak}|${urun.kod}|${urun.barkod}`;
      if (gorulen.has(kimlik)) continue;
      gorulen.add(kimlik);
      liste.push(urun);
    }
  }
  return liste;
}

async function siteyiDogrula(
  iz: TedarikciDijitalIzi,
  tedarikciAdi: string,
  bagimliliklar: DijitalIzBagimliliklari,
): Promise<TedarikciDijitalIzi | null> {
  const dogrulama = await siteFirmayaAitMi(
    iz.alan,
    {
      ad: tedarikciAdi || iz.firma,
      vergiNo: bagimliliklar.tedarikciKimligi?.vergiNo ?? "",
      adres: bagimliliklar.tedarikciKimligi?.adres ?? "",
    },
    { fetcher: bagimliliklar.fetcher, resolveHost: bagimliliklar.resolveHost },
  );
  if (dogrulama.guc === "guclu" || dogrulama.guc === "orta" || dogrulama.guc === "dogrulanamadi") {
    return { ...iz, dogrulama };
  }
  return null;
}

async function firmaIziniBul(
  tedarikciAdi: string,
  tedarikciSite: string,
  satirlar: HamFaturaSatiri[],
  bagimliliklar: DijitalIzBagimliliklari,
): Promise<TedarikciDijitalIzi | null> {
  const ipucu = siteIzindenKur(tedarikciAdi, tedarikciSite);
  if (ipucu) {
    const dogrulanan = await siteyiDogrula(ipucu, tedarikciAdi, bagimliliklar);
    if (dogrulanan) return dogrulanan;
  }

  if (tedarikciAdi.trim().length >= 3) {
    const arama = await firmaSitesiniAra(tedarikciAdi, {
      ...(bagimliliklar.tedarikciKimligi ? { kimlik: bagimliliklar.tedarikciKimligi } : {}),
      dogrula: { fetcher: bagimliliklar.fetcher, resolveHost: bagimliliklar.resolveHost },
      ...(bagimliliklar.firmaArama ?? {}),
    });
    if (arama.durum === "bulundu") {
      return {
        anahtar: null,
        firma: tedarikciAdi.trim(),
        alan: arama.alan,
        platform: "",
        izinDurumu: "yok",
        kaynak: arama.kaynak,
        havuzda: false,
        ...(arama.dogrulama ? { dogrulama: arama.dogrulama } : {}),
      };
    }
  }

  const kesfet = bagimliliklar.firmaKesfet ?? firmaSitesiniModeldenBul;
  const model = await kesfet({
    tedarikci: tedarikciAdi,
    vergiNo: bagimliliklar.tedarikciKimligi?.vergiNo ?? "",
    adres: bagimliliklar.tedarikciKimligi?.adres ?? "",
    markalar: [...new Set(satirlar.map((satir) => (satir.marka ?? "").trim()).filter(Boolean))],
    urunAdlari: satirlar.map((satir) => satir.ad).filter(Boolean),
  });
  if (!model?.site) return null;
  const aday = siteIzindenKur(model.firma || tedarikciAdi, model.site);
  if (!aday) return null;
  return siteyiDogrula(aday, tedarikciAdi || model.firma, bagimliliklar);
}

export async function faturaSatirlariniDijitalIzle(
  satirlar: HamFaturaSatiri[],
  tedarikciAdi = "",
  tedarikciSite = "",
  bagimliliklar: DijitalIzBagimliliklari = {},
): Promise<FaturaDijitalIzSonucu> {
  const tedarikciIz = await firmaIziniBul(tedarikciAdi, tedarikciSite, satirlar, bagimliliklar);
  const yerel = satirlar.map((satir) => eslesmeyenSatir(satir));

  const aramaDurumu: DijitalIzAramaDurumu = bagimliliklar.durum ?? {
    erisimHatasi: false,
    sinirDoldu: false,
  };
  const sonuc = yerel.map((satir) => ({ ...satir }));
  aramaDurumu.erisimHatasi = false;
  aramaDurumu.sinirDoldu = false;

  if (tedarikciIz) {
    const eksikIndeksler = yerel
      .map((satir, indeks) => (satir.katalog === null && satir.sonuc !== "celiski" ? indeks : -1))
      .filter((indeks) => indeks >= 0);
    if (eksikIndeksler.length > 0) {
      const dinamik = await dinamikUrunIzleriniBul(
        eksikIndeksler.map((indeks) => ({ ...yerel[indeks] })),
        tedarikciIz,
        { ...bagimliliklar, durum: aramaDurumu },
      );
      eksikIndeksler.forEach((indeks, sira) => {
        hedefiSatiraYaz(sonuc, indeks, dinamik[sira], tedarikciIz);
      });

      const kalan = eksikIndeksler.filter((indeks) => !sonuc[indeks].katalog && sonuc[indeks].sonuc !== "celiski");
      const siteUrunleri = toplananUrunler(aramaDurumu);
      if (kalan.length > 0 && siteUrunleri.length > 0) {
        const eslestir = bagimliliklar.urunEslestir ?? satirlariModeldenEslestir;
        const baglar = await eslestir(
          kalan.map((indeks) => sonuc[indeks]),
          siteUrunleri,
        );
        kalan.forEach((indeks, sira) => {
          const adaylar = (baglar[sira] ?? [])
            .map((urunNo) => siteUrunleri[urunNo])
            .filter(Boolean);
          if (adaylar.length === 1) {
            hedefiSatiraYaz(
              sonuc,
              indeks,
              { urun: adaylar[0], dayanak: "kod", gorselAdaylari: adaylar[0].gorseller ?? [] },
              tedarikciIz,
            );
          } else if (adaylar.length > 1) {
            hedefiSatiraYaz(
              sonuc,
              indeks,
              {
                celiski: true,
                dayanak: "kod",
                adaylar: adaylar.map((urun) => ({
                  ad: urun.ad,
                  kaynak: urun.kaynak,
                  marka: urun.marka,
                  aciklama: urun.aciklama,
                  gorseller: urun.gorseller,
                  izinDurumu: tedarikciIz.izinDurumu,
                })),
              },
              tedarikciIz,
            );
          }
        });
      }
    }
  }

  const markaAranan = await markaKaynaginda(sonuc, tedarikciIz, tedarikciAdi, bagimliliklar, aramaDurumu);

  return {
    satirlar: sonuclandir(sonuc, tedarikciIz, aramaDurumu, markaAranan),
    tedarikciIz,
    aramaDurumu,
  };
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
      celiski: {
        dayanak: hedef.dayanak,
        adaylar: hedef.adaylar.map((aday) => ({
          ...aday,
          firma: aday.firma || iz.firma,
          izinDurumu: aday.izinDurumu ?? iz.izinDurumu,
        })),
      },
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
    const markaAdi = (satir.marka ?? "").trim();
    const sade = markaAdiSade(markaAdi);
    if (!sade || faturaFirmalari.some((firma) => firma === sade || firma.includes(sade) || sade.includes(firma))) {
      return;
    }
    gruplar.set(markaAdi, [...(gruplar.get(markaAdi) ?? []), indeks]);
  });

  for (const [markaAdi, indeksler] of gruplar) {
    const markaIz = await firmaIziniBul(markaAdi, "", indeksler.map((indeks) => sonuc[indeks]), bagimliliklar);
    if (!markaIz) continue;

    const dinamik = await dinamikUrunIzleriniBul(
      indeksler.map((indeks) => ({ ...sonuc[indeks] })),
      markaIz,
      { ...bagimliliklar, durum: aramaDurumu },
    );
    indeksler.forEach((indeks, sira) => {
      aranan.add(indeks);
      hedefiSatiraYaz(sonuc, indeks, dinamik[sira], markaIz);
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
