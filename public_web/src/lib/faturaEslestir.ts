import {
  firmaAnahtariniCoz,
  firmaKataloguVarMi,
  satirdaHavuzMarkasiBul,
  ureticiUrunuBul,
} from "@/lib/ureticiKatalog";
import {
  dinamikUrunIzleriniBul,
  tedarikciDijitalIziBul,
  type DijitalIzBagimliliklari,
  type DijitalIzHedefi,
  type TedarikciDijitalIzi,
} from "@/lib/faturaDijitalIz";
import { firmaSitesiniAra } from "@/lib/firmaArama";
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
  kaynak: string;
}

export interface CeliskiBilgisi {
  dayanak: "kod" | "barkod";
  adaylar: Array<{ ad: string; kaynak: string }>;
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

export function faturaSatiriniEslestir(
  satir: HamFaturaSatiri,
  firmaAnahtari: string | null = null,
): EslesmisFaturaSatiri {
  const eslesme = ureticiUrunuBul({
    model: satir.model || null,
    barkod: satir.barkod || null,
    firmaAnahtari,
  });
  if (!eslesme) return eslesmeyenSatir(satir);
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

function sonuclandir(
  satirlar: EslesmisFaturaSatiri[],
  tedarikciIz: TedarikciDijitalIzi | null,
): EslesmisFaturaSatiri[] {
  const faturaFirmasi = tedarikciIz?.firma ?? "";
  const tedarikciAnahtari = tedarikciIz?.anahtar ?? null;

  return satirlar.map((satir) => {
    if (satir.katalog || satir.sonuc === "celiski") return satir;

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
      return { ...satir, sonuc: "iz-yok" };
    }
    return satir.sonuc === "eksik" ? satir : { ...satir, sonuc: "eksik" };
  });
}

export interface FaturaDijitalIzSonucu {
  satirlar: EslesmisFaturaSatiri[];
  tedarikciIz: TedarikciDijitalIzi | null;
}

export async function faturaSatirlariniDijitalIzle(
  satirlar: HamFaturaSatiri[],
  tedarikciAdi = "",
  tedarikciSite = "",
  bagimliliklar: DijitalIzBagimliliklari = {},
): Promise<FaturaDijitalIzSonucu> {
  // Havuz SADECE hızlı yoldur (jeton tasarrufu). Listede yoksa firmanın adı
  // internette aratılır; resmi sitesi bulunursa aynı keşif oradan yürür.
  // Bulunamazsa akış durmaz — satırlar dürüstçe iz-yok/eksik döner.
  let tedarikciIz = tedarikciDijitalIziBul(tedarikciAdi, tedarikciSite);
  if (!tedarikciIz && tedarikciAdi.trim().length >= 3) {
    const arama = await firmaSitesiniAra(tedarikciAdi, bagimliliklar.firmaArama ?? {});
    if (arama.durum === "bulundu") {
      tedarikciIz = {
        anahtar: null,
        firma: tedarikciAdi.trim(),
        alan: arama.alan,
        platform: "",
        izinDurumu: "yok",
        kaynak: arama.kaynak,
        havuzda: false,
      };
    }
  }
  const tedarikciBelirtilmisAmaCozulememis = Boolean(tedarikciAdi.trim()) && !tedarikciIz;
  const yerelAramaGuvenli =
    !tedarikciBelirtilmisAmaCozulememis &&
    (!tedarikciIz ||
      (tedarikciIz.havuzda &&
        Boolean(tedarikciIz.anahtar) &&
        firmaKataloguVarMi(tedarikciIz.anahtar as string)));

  const yerel = yerelAramaGuvenli
    ? faturaSatirlariniEslestir(satirlar, tedarikciAdi)
    : satirlar.map((satir) => eslesmeyenSatir(satir));

  if (!tedarikciIz) return { satirlar: sonuclandir(yerel, null), tedarikciIz };

  const eksikIndeksler = yerel
    .map((satir, indeks) => (satir.katalog === null && satir.sonuc !== "celiski" ? indeks : -1))
    .filter((indeks) => indeks >= 0);
  if (eksikIndeksler.length === 0) {
    return { satirlar: sonuclandir(yerel, tedarikciIz), tedarikciIz };
  }

  const dinamik: Array<DijitalIzHedefi | null> = await dinamikUrunIzleriniBul(
    eksikIndeksler.map((indeks) => ({
      model: yerel[indeks].model,
      barkod: yerel[indeks].barkod,
    })),
    tedarikciIz,
    bagimliliklar,
  );

  const sonuc = yerel.map((satir) => ({ ...satir }));
  eksikIndeksler.forEach((indeks, sira) => {
    const hedef = dinamik[sira];
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
        firma: tedarikciIz.firma,
        kaynakFirma: tedarikciIz.firma,
        dayanak: hedef.dayanak,
        izinDurumu: tedarikciIz.izinDurumu,
        resmiAd: hedef.urun.ad,
        marka: hedef.urun.marka,
        aciklama: hedef.urun.aciklama,
        gorseller: hedef.urun.gorseller,
        gorselAdaylari: hedef.gorselAdaylari,
        kaynak: hedef.urun.kaynak || tedarikciIz.kaynak,
      },
    };
  });

  return { satirlar: sonuclandir(sonuc, tedarikciIz), tedarikciIz };
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
