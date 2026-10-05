import {
  dinamikUrunIzleriniBul,
  tedarikciDijitalIziBul,
  type DijitalIzAramaDurumu,
  type DijitalIzBagimliliklari,
  type DijitalIzHedefi,
  type TedarikciDijitalIzi,
} from "@/lib/faturaDijitalIz";
import { firmaSitesiniAra } from "@/lib/firmaArama";
import { siteFirmayaAitMi } from "@/lib/firmaDogrula";
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

export interface CeliskiBilgisi {
  dayanak: "kod" | "barkod";
  adaylar: Array<{ ad: string; kaynak: string; firma?: string }>;
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

function kodVeyaBarkodAranabilir(satir: HamFaturaSatiri): boolean {
  const barkod = satir.barkod.replace(/\D/g, "");
  if (barkod.length >= 8) return true;
  const model = satir.model.trim().toUpperCase().replace(/[\s._\-/]/g, "");
  return model.length >= 4;
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

    if (tedarikciIz && kodVeyaBarkodAranabilir(satir)) {
      const yarimKaldi = aramaDurumu.erisimHatasi || aramaDurumu.sinirDoldu;
      return yarimKaldi
        ? { ...satir, sonuc: "iz-yok", uyari: KAYNAK_ERISILEMEDI_NOTU }
        : { ...satir, sonuc: "iz-yok" };
    }
    return satir.sonuc === "eksik" ? satir : { ...satir, sonuc: "eksik" };
  });
}

export async function faturaSatirlariniDijitalIzle(
  satirlar: HamFaturaSatiri[],
  tedarikciAdi = "",
  tedarikciSite = "",
  bagimliliklar: DijitalIzBagimliliklari = {},
): Promise<FaturaDijitalIzSonucu> {
  let tedarikciIz = tedarikciDijitalIziBul(tedarikciAdi, tedarikciSite);
  if (tedarikciIz) {
    const dogrulama = await siteFirmayaAitMi(
      tedarikciIz.alan,
      { ad: tedarikciAdi, vergiNo: bagimliliklar.tedarikciKimligi?.vergiNo ?? "", adres: bagimliliklar.tedarikciKimligi?.adres ?? "" },
      { fetcher: bagimliliklar.fetcher, resolveHost: bagimliliklar.resolveHost },
    );
    tedarikciIz = dogrulama.guc === "guclu" || dogrulama.guc === "orta"
      ? { ...tedarikciIz, dogrulama }
      : null;
  }
  if (!tedarikciIz && tedarikciAdi.trim().length >= 3) {
    const arama = await firmaSitesiniAra(tedarikciAdi, {
      ...(bagimliliklar.tedarikciKimligi ? { kimlik: bagimliliklar.tedarikciKimligi } : {}),
      dogrula: { fetcher: bagimliliklar.fetcher, resolveHost: bagimliliklar.resolveHost },
      ...(bagimliliklar.firmaArama ?? {}),
    });
    if (arama.durum === "bulundu") {
      tedarikciIz = {
        firma: tedarikciAdi.trim(),
        alan: arama.alan,
        platform: "",
        izinDurumu: "yok",
        kaynak: arama.kaynak,
        ...(arama.dogrulama ? { dogrulama: arama.dogrulama } : {}),
      };
    }
  }

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
        hedefiSatiraYaz(sonuc, indeks, dinamik[sira], tedarikciIz as TedarikciDijitalIzi);
      });
    }
  }

  const markaAranan = await markaKaynaginda(sonuc, tedarikciIz, tedarikciAdi, bagimliliklar, aramaDurumu);

  return {
    satirlar: sonuclandir(sonuc, tedarikciIz, aramaDurumu, markaAranan),
    tedarikciIz,
    aramaDurumu,
  };
}

export interface FaturaDijitalIzSonucu {
  satirlar: EslesmisFaturaSatiri[];
  tedarikciIz: TedarikciDijitalIzi | null;
  aramaDurumu: DijitalIzAramaDurumu;
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

    const markaAdi = (satir.marka ?? "").trim();
    const sade = markaAdiSade(markaAdi);
    if (!sade || faturaFirmalari.some((firma) => firma === sade || firma.includes(sade) || sade.includes(firma))) {
      return;
    }
    gruplar.set(markaAdi, [...(gruplar.get(markaAdi) ?? []), indeks]);
  });

  for (const [markaAdi, indeksler] of gruplar) {
    const arama = await firmaSitesiniAra(markaAdi, {
      kimlik: { vergiNo: "", adres: "" },
      dogrula: { fetcher: bagimliliklar.fetcher, resolveHost: bagimliliklar.resolveHost },
      ...(bagimliliklar.firmaArama ?? {}),
    });
    if (arama.durum !== "bulundu") continue;
    const markaIz: TedarikciDijitalIzi = {
      firma: markaAdi,
      alan: arama.alan,
      platform: "",
      izinDurumu: "yok",
      kaynak: arama.kaynak,
      ...(arama.dogrulama ? { dogrulama: arama.dogrulama } : {}),
    };

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
