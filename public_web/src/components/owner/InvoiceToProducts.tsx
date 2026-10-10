"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import FirmaIzniPaneli from "@/components/owner/FirmaIzniPaneli";
import { kategoriSec, otomatikOzellikler, faturaVaryantlari } from "@/lib/faturaOtomatikDoldur";
import { otomatikTaslakAdayi } from "@/lib/faturaTaslakAdayi";
import {
  KART_DURUM_ETIKETI,
  durumBilgisi,
  kartDegerlendir,
  type KartDurumu,
} from "@/lib/faturaKartDurumu";
import {
  belgedeYazi,
  firmaSiteCumlesi,
  type FirmaSiteDurumu,
} from "@/lib/firmaSiteDurumu";
// Faturadan ürün kartına.
// Esnaf satış fiyatını ve satışa açacağı tam-adet stoku kontrol eder; fatura miktarı öneridir.
// Alış fiyatı satış fiyatı olmaz. Sunucu fiyatı ve fotoğrafı ayrıca kontrol eder.

export interface CeliskiBilgisi {
  dayanak: "kod" | "barkod" | "ad";
  adaylar: Array<{ ad: string; kaynak: string; gorseller?: string[] }>;
}

export interface FaturaSatiri {
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  marka?: string;
  adet: number | null;
  birim?: string;
  alisBirimFiyat: number | null;
  satirToplam: number | null;
  guven: number;
  sonuc: KartDurumu;
  uyari?: string;
  celiski?: CeliskiBilgisi;
  katalog: KatalogBilgisi | null;
}

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

interface AyniAlisverisAdayi {
  islemKimligi: string;
  iliski: "ayni" | "olasi";
  sebep: string;
  belgeTuru: string;
  belgeNo: string;
  belgeTarihi: string | null;
  satirSayisi: number;
  satirlar: Array<{ kod: string; adet: number | null }>;
}

interface KayitliSahipDurumu {
  satisFiyati?: string;
  stok?: string;
  stokOnaylandi?: boolean;
  kategoriId?: string;
  onayli?: boolean;
  esnafGorselleri?: string[];
}

interface FaturaOkumaSatiri extends FaturaSatiri {
  sahipDurumu?: KayitliSahipDurumu | null;
  urunId?: string | null;
}

interface OncekiIslem {
  islemKimligi: string;
  durum: string;
  tedarikci: string;
  olusturma: string;
  satirSayisi: number;
}

interface FaturaOkumaSonucu {
  maliyetOzeti?: {
    kayitSayisi: number;
    gercekUsd: number;
    tahminiUsd: number;
    tahminiKayitSayisi: number;
    ayrilanButceUsd: number;
  };
  satirlar: FaturaOkumaSatiri[];
  belgeToplami: number | null;
  belgeAdedi: number | null;
  belge?: { malBedeli?: number | null; kdvTutari?: number | null; indirimTutari?: number | null; odenecekToplam?: number | null };
  /** Eski kayıtlarda kalabilir. Tutmayan yeni okuma buraya gelmez. */
  belgeUyarisi?: string;
  tedarikci: string;
  tedarikciVergiNo?: string;
  tedarikciAdres?: string;
  tedarikciSite?: string;
  siteDurumu?: FirmaSiteDurumu | null;
  katalogEslesmesi?: number;
  sonucOzeti?: Record<string, number>;
  islemKimligi?: string | null;
  ayniAlisveris?: AyniAlisverisAdayi[];
  aramaSuruyor?: boolean;
}

interface SatirDurumu extends FaturaSatiri {
  satisFiyati: string;
  onayli: boolean;
  kategoriId: string;
  stok: string;
  stokOnaylandi: boolean;
  esnafGorselleri: string[];
  ayniAlisverisTekrari?: boolean;
  urunId?: string | null;
}

interface YazmaSonucu {
  tuketiciDogrulandi?: boolean;
  toplam: number;
  yayinda: number;
  taslak: number;
  hatali: number;
  satirlar: Array<{ sira: number; ad: string; durum: string; sebep?: string; id?: string }>;
}

interface InvoiceToProductsProps {
  storeSlug: string;
  categories?: Array<{ id: string; name: string; product_template_key?: string | null }>;
  onUploaded: () => Promise<void>;
  onClose?: () => void;
  baslangicIslemKimligi?: string;
  okuyucuHazir?: boolean;
}

/** Bu eşiğin altındaki satır toplu onaya girmez; esnaf ona tek tek bakar. */
const GUVEN_ESIGI = 0.7;
const MAKS_BAYT = 4 * 1024 * 1024; // Vercel 4.5 MB request body, multipart payi.
const MAKS_SAYFA = 3;

function paraYaz(n: number | null): string {
  if (n === null) return "—";
  return `${n.toLocaleString("tr-TR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })} TL`;
}

function fiyatSayisi(ham: string): number | null {
  const giris = ham.trim().replace(/\s/g, "");
  const temiz = giris.includes(",") ? giris.replace(/\./g, "").replace(",", ".") : giris;
  if (!temiz) return null;
  const n = Number(temiz);
  return Number.isFinite(n) && n > 0 ? n : null;
}

function stokSayisi(ham: string): number | null {
  const temiz = ham.trim();
  if (!temiz) return null;
  const n = Number(temiz);
  return Number.isFinite(n) && n >= 0 ? Math.round(n) : null;
}

export function faturaSatiriDurumunuHazirla(
  satir: FaturaOkumaSatiri,
  kategoriId: string,
): SatirDurumu {
  const kayitli = satir.sahipDurumu;
  return {
    ...satir,
    satisFiyati: kayitli?.satisFiyati ?? "",
    onayli: kayitli?.onayli === true,
    kategoriId: kayitli?.kategoriId || kategoriId,
    stok: kayitli?.stok ?? (satir.adet === null ? "" : String(satir.adet)),
    stokOnaylandi: kayitli?.stokOnaylandi === true,
    esnafGorselleri: kayitli?.esnafGorselleri ?? [],
    urunId: satir.urunId ?? null,
  };
}


/** Tek hazırlama yolu: otomatik taslak ve esnaf onayında aynı ürün alanları. */
function faturaUrunIstekGirdisi(
 satir: SatirDurumu,
 sira: number,
 degerlendirme: ReturnType<typeof kartDegerlendir>,
 kaynakBelge: FaturaOkumaSonucu | null,
 categories: Array<{ id: string; name: string; product_template_key?: string | null }>,
 yayinIstegi = false,
) {
            const satisFiyati = fiyatSayisi(satir.satisFiyati);
            const katalog = satir.katalog;
            return {
              name: katalog?.resmiAd || satir.ad || satir.model || satir.barkod,
              description: katalog?.aciklama ?? "",
              priceText: satisFiyati === null ? "" : `${satisFiyati} TL`,
              categoryId: satir.kategoriId,
              imageUrls: degerlendirme.gorseller,
              gorselKaynagi: katalog?.kaynak || undefined,
              brand: katalog?.marka || undefined,
              barcode: satir.barkod || undefined,
              stockQuantity: stokSayisi(satir.stok),
              sourceType: "invoice",
              kartDurumu: satir.sonuc,
              stokOnaylandi: satir.stokOnaylandi,
              externalProductId:
                satir.barkod || satir.model
                  ? [kaynakBelge?.tedarikciVergiNo || kaynakBelge?.tedarikci || "", satir.barkod || satir.model]
                      .filter(Boolean)
                      .join(":")
                  : undefined,
              islemKimligi: kaynakBelge?.islemKimligi || undefined,
              satirSirasi: sira,
              ownerApproved: satir.onayli,
              yayinIstegi,
              purchasePriceAmount: satir.alisBirimFiyat ?? undefined,
              metadata: (() => {
                const sablon = categories.find((kategori) => kategori.id === satir.kategoriId)
                  ?.product_template_key;
                const nitelikler = otomatikOzellikler(
                  { ad: satir.ad, resmiAd: katalog?.resmiAd, varyant: satir.varyant, beden: satir.beden },
                  sablon || "generic",
                );
                if (!satir.model && nitelikler.length === 0) return undefined;
                return {
                  ...(satir.model ? { identifiers: { sku: satir.model } } : {}),
                  ...(nitelikler.length > 0 ? { attributes: nitelikler } : {}),
                };
              })(),
              variants: faturaVaryantlari({
                model: satir.model || String(sira), barkod: satir.barkod,
                varyant: satir.varyant, beden: satir.beden,
                stok: stokSayisi(satir.stok), kaynakVaryantlar: katalog?.varyantlar,
              }),
              sortOrder: sira,
            };
}

export default function InvoiceToProducts({
  storeSlug,
  categories = [],
  onUploaded,
  onClose,
  baslangicIslemKimligi,
  okuyucuHazir = true,
}: InvoiceToProductsProps) {
  const [adim, setAdim] = useState<"sec" | "okunuyor" | "urunler" | "yaziliyor" | "bitti">(
    "sec",
  );
  const [onizleme, setOnizleme] = useState<string | null>(null);
  const [belge, setBelge] = useState<FaturaOkumaSonucu | null>(null);
  const [satirlar, setSatirlar] = useState<SatirDurumu[]>([]);
  const [kar, setKar] = useState("30");
  const [hata, setHata] = useState<string | null>(null);
  const [yukleniyor, setYukleniyor] = useState(false);
  const [sonuc, setSonuc] = useState<YazmaSonucu | null>(null);
  const [otomatikTaslakRaporu, setOtomatikTaslakRaporu] = useState<{ kaydedildi: number; atlandi: number } | null>(null);
  const [alisverisCevaplari, setAlisverisCevaplari] = useState<Record<string, boolean>>({});
  const [oncekiIslemler, setOncekiIslemler] = useState<OncekiIslem[]>([]);
  const [duzeltmeler, setDuzeltmeler] = useState<
    Record<number, { model: string; barkod: string; marka: string }>
  >({});
  const [duzeltilen, setDuzeltilen] = useState<number | null>(null);
  const [baglantiKopyalandi, setBaglantiKopyalandi] = useState(false);
  const dosyaRef = useRef<HTMLInputElement>(null);
  const sonFaturaDosyasi = useRef<File[] | null>(null);
  const kayitSirasi = useRef<Promise<void>>(Promise.resolve());

  const sahipSecimleriniKaydet = useCallback((kaydedilecek: SatirDurumu[]) => {
    if (!belge?.islemKimligi || kaydedilecek.length === 0) return Promise.resolve();
    const islemKimligi = belge.islemKimligi;
    const istek = kayitSirasi.current.catch(() => undefined).then(async () => {
      const cevap = await fetch("/api/fatura-islem", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug, islemKimligi,
          satirlar: kaydedilecek.map((satir, sira) => ({
            satirSirasi: sira,
            sahipDurumu: {
              satisFiyati: satir.satisFiyati, stok: satir.stok,
              stokOnaylandi: satir.stokOnaylandi, kategoriId: satir.kategoriId,
              onayli: satir.onayli, esnafGorselleri: satir.esnafGorselleri,
            },
          })),
        }),
      });
      if (!cevap.ok) throw new Error("Değişikliklerin kaydedilemedi. Tekrar dene.");
    });
    kayitSirasi.current = istek;
    return istek;
  }, [belge, storeSlug]);

  const kapat = async () => {
    if (yukleniyor || adim === "okunuyor" || adim === "yaziliyor") return;
    try {
      await sahipSecimleriniKaydet(satirlar);
      onClose?.();
    } catch (err) {
      setHata(err instanceof Error ? err.message : "Değişikliklerin kaydedilemedi.");
    }
  };

  const degerlendirmeler = useMemo(
    () =>
      satirlar.map((satir) =>
        kartDegerlendir({
          satir,
          satisFiyati: fiyatSayisi(satir.satisFiyati),
          stok: stokSayisi(satir.stok),
          esnafGorselleri: satir.esnafGorselleri,
          onaylandi: satir.onayli,
          templateKey: categories.find((kategori) => kategori.id === satir.kategoriId)?.product_template_key,
        }),
      ),
    [satirlar, categories],
  );

  const hazirSayisi = degerlendirmeler.filter(
    (d, i) => d.onaylanabilir && !satirlar[i].ayniAlisverisTekrari,
  ).length;

  /** Faturanın üç beklenen sayısı satırlardan yeniden hesaplanır ve belgedeki
   * değerle karşılaştırılır: tutmayan fark esnafın gözünden saklanmaz. */
  const kontrol = useMemo(() => {
    // Sunucu gibi, miktarlar yalnız aynı ölçüdeyse karşılaştırılabilir.
    const normalizeBirim = (ham: string | undefined) => {
      const birim = (ham ?? "").trim().toLocaleLowerCase("tr-TR").replace(/[.]$/, "");
      return ["ad", "adet", "pcs", "piece"].includes(birim) ? "adet" : birim || "belirtilmedi";
    };
    const miktarGruplari = new Map<string, number>();
    for (const satir of satirlar) {
      const birim = normalizeBirim(satir.birim);
      miktarGruplari.set(birim, (miktarGruplari.get(birim) ?? 0) + (satir.adet ?? 0));
    }
    const karisikBirim = miktarGruplari.size > 1;
    const miktarOzeti = [...miktarGruplari.entries()]
      .map(([birim, miktar]) => `${miktar.toLocaleString("tr-TR")} ${birim}`).join(" + ");
    const adetToplam = satirlar.reduce((toplam, satir) => toplam + (satir.adet ?? 0), 0);
    const tutarToplam = satirlar.reduce((toplam, satir) => toplam + (satir.satirToplam ?? 0), 0);
    const araToplam = belge?.belge?.malBedeli ??
      (belge?.belge?.kdvTutari == null && belge?.belge?.indirimTutari == null
        ? belge?.belgeToplami : null);
    return {
      satirSayisi: satirlar.length,
      adetToplam, miktarOzeti, karisikBirim,
      tutarToplam, araToplam,
      adetTutuyor: belge?.belgeAdedi == null || karisikBirim ? null
        : Math.abs(adetToplam - belge.belgeAdedi) < 0.00001,
      tutarTutuyor: araToplam == null ? null : Math.abs(tutarToplam - araToplam) <= 0.05,
    };
  }, [satirlar, belge]);

  const satirlariHazirla = useCallback(
    (okunan: FaturaOkumaSonucu): SatirDurumu[] =>
      okunan.satirlar.map((satir) =>
        faturaSatiriDurumunuHazirla(satir,
            kategoriSec(
              { ad: satir.ad, marka: satir.marka, resmiAd: satir.katalog?.resmiAd },
              categories,
            )),
      ),
    [categories],
  );

  useEffect(() => {
    let iptal = false;
    void (async () => {
      try {
        const cevap = await fetch(`/api/fatura-islem?slug=${encodeURIComponent(storeSlug)}`);
        if (!cevap.ok) return;
        const govde = await cevap.json().catch(() => null);
        if (!iptal && govde && Array.isArray(govde.islemler)) {
          setOncekiIslemler(govde.islemler as OncekiIslem[]);
        }
      } catch {
        return;
      }
    })();
    return () => {
      iptal = true;
    };
  }, [storeSlug]);

  useEffect(() => {
    if (adim !== "urunler" || !belge?.islemKimligi || satirlar.length === 0) return;
    const zamanlayici = setTimeout(() => {
      void sahipSecimleriniKaydet(satirlar).catch((err) =>
        setHata(err instanceof Error ? err.message : "Değişikliklerin kaydedilemedi."),
      );
    }, 800);
    return () => clearTimeout(zamanlayici);
  }, [adim, belge?.islemKimligi, satirlar, sahipSecimleriniKaydet]);


  // Faturanın tanımlanabilir HER satırını kalıcı görünmez taslağa kaydeder.
  // Resmî kaynak/fotoğraf bulunmaması veya çelişki, yayın izni değildir.
  // Aynı satır tekrar açılınca güncel kaynak bilgisiyle tekrar kaydedilebilir.
  // Bu akış otomatik satış/yayın onayı VERMEZ.
  const otomatikTaslaklariKaydet = useCallback(async (okunan: FaturaOkumaSonucu, hazir: SatirDurumu[]) => {
    if (!okunan.islemKimligi) return;
    const adaylar = hazir.map((satir, sira) => ({ satir, sira }))
      .filter(({ satir }) => !satir.ayniAlisverisTekrari && otomatikTaslakAdayi(satir));
    if (adaylar.length === 0) return;
    const sahipCevabi = await fetch("/api/fatura-islem", {
      method: "PUT", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ slug: storeSlug, islemKimligi: okunan.islemKimligi,
        satirlar: hazir.map((satir, sira) => ({
          satirSirasi: sira,
          sahipDurumu: { satisFiyati: satir.satisFiyati, stok: satir.stok,
            stokOnaylandi: satir.stokOnaylandi, kategoriId: satir.kategoriId,
            onayli: satir.onayli, esnafGorselleri: satir.esnafGorselleri },
        })),
      }),
    });
    if (!sahipCevabi.ok) throw new Error("Taslak kayıt için fatura seçimleri saklanamadı.");
    const cevap = await fetch("/api/products/batch", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ slug: storeSlug, products: adaylar.map(({ satir, sira }) => ({
        ...faturaUrunIstekGirdisi(satir, sira, kartDegerlendir({
          satir, satisFiyati: fiyatSayisi(satir.satisFiyati),
          stok: stokSayisi(satir.stok), esnafGorselleri: satir.esnafGorselleri,
          onaylandi: satir.onayli,
          templateKey: categories.find((kategori) => kategori.id === satir.kategoriId)?.product_template_key,
        }), okunan, categories),
        yayinIstegi: false,
      })) }),
    });
    const yanit = await cevap.json().catch(() => null);
    if (!cevap.ok || !yanit || !Array.isArray(yanit.satirlar)) {
      throw new Error(yanit?.hata || "Ürün taslaklarının kalıcı kaydı doğrulanamadı.");
    }
    const baglanan = new Map<number, string>();
    let atlandi = 0;
    for (const kayit of yanit.satirlar as Array<{ sira: number; id?: string; durum: string }>) {
      const aday = adaylar[kayit.sira];
      if (!aday) throw new Error("Ürün taslağı ile fatura satırı uyuşmuyor.");
      if (kayit.durum === "taslak" && typeof kayit.id === "string" && kayit.id) {
        baglanan.set(aday.sira, kayit.id);
      } else atlandi++;
    }
    if (baglanan.size + atlandi !== adaylar.length) throw new Error("Ürün taslağı kayıt sayısı uyuşmuyor.");
    setSatirlar((eskiler) => eskiler.map((satir, sira) =>
      baglanan.has(sira) ? { ...satir, urunId: baglanan.get(sira) } : satir));
    setOtomatikTaslakRaporu({ kaydedildi: baglanan.size, atlandi });
    if (atlandi > 0) setHata(`${atlandi} fatura satırı kalıcı ürün taslağına kaydedilemedi.`);
    if (baglanan.size > 0) await onUploaded();
  }, [categories, onUploaded, storeSlug]);

  async function islemiAc(islemKimligi: string) {
    setHata(null);
    setYukleniyor(true);
    try {
      const cevap = await fetch(
        `/api/fatura-islem?slug=${encodeURIComponent(storeSlug)}&islemKimligi=${encodeURIComponent(islemKimligi)}`,
      );
      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        throw new Error(
          govde && typeof govde.hata === "string" ? govde.hata : "İşlem açılamadı. Tekrar dene.",
        );
      }
      const acilan = govde as FaturaOkumaSonucu;
      const hazir = satirlariHazirla(acilan);
      setBelge(acilan);
      setSatirlar(hazir);
      try { await otomatikTaslaklariKaydet(acilan, hazir); }
      catch (hata) { setHata(hata instanceof Error ? hata.message : "Otomatik taslak kaydı başarısız."); }
      setAdim("urunler");
    } catch (err) {
      setHata(err instanceof Error ? err.message : "İşlem açılamadı.");
    }
    setYukleniyor(false);
  }

  useEffect(() => {
    if (!baslangicIslemKimligi) return;
    const zamanlayici = setTimeout(() => void islemiAc(baslangicIslemKimligi), 0);
    return () => clearTimeout(zamanlayici);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [baslangicIslemKimligi]);

  async function adaySec(index: number, kaynak: string) {
    if (!belge?.islemKimligi || !kaynak) return;
    setHata(null);
    setDuzeltilen(index);
    try {
      await sahipSecimleriniKaydet(satirlar);
      const cevap = await fetch("/api/fatura-satir-duzelt", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          islemKimligi: belge.islemKimligi,
          satirSirasi: index,
          secilenKaynak: kaynak,
        }),
      });
      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        throw new Error(govde && typeof govde.hata === "string" ? govde.hata : "Seçim kaydedilemedi. Tekrar dene.");
      }
      const yeni = govde.satir as FaturaSatiri;
      setSatirlar((oncekiler) =>
        oncekiler.map((satir, i) =>
          i === index ? {
            ...satir, ...yeni,
            onayli: govde.onaySifirlandi ? false : satir.onayli,
            stokOnaylandi: govde.onaySifirlandi ? false : satir.stokOnaylandi,
            ayniAlisverisTekrari: false,
          } : satir,
        ),
      );
    } catch (err) {
      setHata(err instanceof Error ? err.message : "Seçim kaydedilemedi.");
    }
    setDuzeltilen(null);
  }

  async function satiriDuzelt(index: number) {
    const giris = duzeltmeler[index] ?? satirlar[index];
    if (!giris || !belge?.islemKimligi) return;
    setHata(null);
    setDuzeltilen(index);
    try {
      await sahipSecimleriniKaydet(satirlar);
      const cevap = await fetch("/api/fatura-satir-duzelt", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          islemKimligi: belge.islemKimligi,
          satirSirasi: index,
          model: giris.model,
          barkod: giris.barkod,
          marka: giris.marka,
        }),
      });
      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        throw new Error(
          govde && typeof govde.hata === "string" ? govde.hata : "Satır düzeltilemedi. Tekrar dene.",
        );
      }
      const yeni = govde.satir as FaturaSatiri;
      setSatirlar((oncekiler) =>
        oncekiler.map((satir, i) =>
          i === index ? {
            ...satir, ...yeni,
            onayli: govde.onaySifirlandi ? false : satir.onayli,
            stokOnaylandi: govde.onaySifirlandi ? false : satir.stokOnaylandi,
            ayniAlisverisTekrari: false,
          } : satir,
        ),
      );
    } catch (err) {
      setHata(err instanceof Error ? err.message : "Satır düzeltilemedi.");
    }
    setDuzeltilen(null);
  }

  const dosyaSecildi = useCallback(
    async (dosyalar: File[]) => {
      setHata(null);
      setOtomatikTaslakRaporu(null);
      if (!dosyalar.length || dosyalar.length > MAKS_SAYFA) {
        setHata("Bir faturaya ait en fazla 3 sayfa fotoğrafı seç.");
        return;
      }
      if (dosyalar.reduce((toplam, dosya) => toplam + dosya.size, 0) > MAKS_BAYT) {
        setHata("Sayfa fotoğraflarının toplamı en fazla 4 MB olabilir.");
        return;
      }
      // Esnaf yalnız faturasını seçer. PDF ile fotoğraflar karıştırılmaz.
      const pdfMi = dosyalar[0]?.type === "application/pdf"
        || dosyalar[0]?.name.toLocaleLowerCase("tr-TR").endsWith(".pdf");
      if (pdfMi && dosyalar.length !== 1) {
        setHata("PDF faturayı tek dosya olarak seç.");
        return;
      }
      sonFaturaDosyasi.current = dosyalar;
      if (pdfMi) {
        setOnizleme(null);
      } else {
        const okuyucu = new FileReader();
        okuyucu.onload = () => setOnizleme(String(okuyucu.result));
        okuyucu.readAsDataURL(dosyalar[0]);
      }

      setAdim("okunuyor");

      try {
        const form = new FormData();
        form.append("slug", storeSlug);
        for (const dosya of dosyalar) form.append("dosya", dosya);

        const cevap = await fetch("/api/fatura-oku", { method: "POST", body: form });
        const govde = await cevap.json().catch(() => null);

        if (!cevap.ok) {
          throw new Error(
            govde && typeof govde.hata === "string"
              ? govde.hata
              : "Fatura okunamadı. Tekrar dene.",
          );
        }

        const okunan = govde as FaturaOkumaSonucu;
        const hazir = satirlariHazirla(okunan);
        setBelge(okunan);
        setSatirlar(hazir);
        try { await otomatikTaslaklariKaydet(okunan, hazir); }
        catch (hata) { setHata(hata instanceof Error ? hata.message : "Otomatik taslak kaydı başarısız."); }
        setAdim("urunler");
      } catch (err) {
        setHata(err instanceof Error ? err.message : "Fatura okunamadı.");
        setAdim("sec");
      }
    },
    [otomatikTaslaklariKaydet, satirlariHazirla, storeSlug],
  );

  function satirGuncelle(index: number, degisiklik: Partial<SatirDurumu>) {
    setSatirlar((oncekiler) =>
      oncekiler.map((satir, i) => (i === index ? {
        ...satir,
        ...degisiklik,
        onayli: degisiklik.onayli ?? false,
        stokOnaylandi: degisiklik.stokOnaylandi ?? satir.stokOnaylandi,
      } : satir)),
    );
  }

  function karUygula() {
    const oran = Math.max(0, Number(kar) || 0);
    setSatirlar((oncekiler) =>
      oncekiler.map((satir) => {
        if (satir.alisBirimFiyat === null) return satir;
        const hesap = Math.round(satir.alisBirimFiyat * (1 + oran / 100) * 100) / 100;
        return { ...satir, satisFiyati: String(hesap), onayli: false };
      }),
    );
  }

  async function vitriniPaylas() {
    const baglanti = `${window.location.origin}/v/${storeSlug}`;
    try {
      await navigator.clipboard.writeText(baglanti);
      setBaglantiKopyalandi(true);
    } catch {
      setBaglantiKopyalandi(false);
    }
  }

  function kodTemiz(ham: string): string {
    return ham.toUpperCase().replace(/[^A-Z0-9]/g, "");
  }

  async function alisverisCevapla(aday: AyniAlisverisAdayi, ayni: boolean) {
    if (!belge?.islemKimligi) return;
    setHata(null);
    try {
      const cevap = await fetch("/api/fatura-alisveris-teyit", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          islemKimligi: belge.islemKimligi,
          digerIslemKimligi: aday.islemKimligi,
          ayni,
        }),
      });
      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        throw new Error(
          govde && typeof govde.hata === "string" ? govde.hata : "Cevabın kaydedilemedi.",
        );
      }
    } catch (err) {
      setHata(err instanceof Error ? err.message : "Cevabın kaydedilemedi.");
      return;
    }

    setAlisverisCevaplari((onceki) => ({ ...onceki, [aday.islemKimligi]: ayni }));
    const ilkKodlar = new Set(aday.satirlar.map((satir) => kodTemiz(satir.kod)).filter(Boolean));
    setSatirlar((oncekiler) =>
      oncekiler.map((satir) => {
        const kod = kodTemiz(satir.model || satir.barkod);
        if (!kod || !ilkKodlar.has(kod)) return satir;
        return ayni
          ? { ...satir, ayniAlisverisTekrari: true, onayli: false, stokOnaylandi: false, stok: "" }
          : { ...satir, ayniAlisverisTekrari: false, stok: satir.adet === null ? "" : String(satir.adet) };
      }),
    );
  }

  /**
   * Esnafın BU düğmeye basması satır bilgilerine açık onaydır.
   * Önce sunucudaki invoice_job_lines.owner_state güncellenir, sonra
   * yalnız kalıcı TASLAK kaydı istenir. Yayınlama ayrı bir eylemdir.
   */
  async function vitrineYaz() {
    const gonderilecek = satirlar
      .map((satir, sira) => ({ satir, sira, degerlendirme: degerlendirmeler[sira] }))
      .filter(({ satir, degerlendirme }) =>
        !satir.ayniAlisverisTekrari && (degerlendirme.onaylanabilir || otomatikTaslakAdayi(satir)),
      );

    if (gonderilecek.length === 0) return;

    // Önceki satırlarda kaydedilmiş gerçek kararlar korunur.
    // Yalnız esnafın bu düğmeyle onayladığı, yayına uygun satırlar onaylanır.
    const secili = new Set(gonderilecek.map((girdi) => girdi.sira));
    const onaylanan = satirlar.map((satir, index) =>
      secili.has(index) && degerlendirmeler[index].onaylanabilir
        ? { ...satir, onayli: true, stokOnaylandi: stokSayisi(satir.stok) !== null }
        : satir,
    );
    const onayliGonderilecek = gonderilecek.map((girdi) => ({
      ...girdi,
      satir: onaylanan[girdi.sira],
    }));

    setAdim("yaziliyor");
    setHata(null);

    try {
      // DB'de gerçek onay saklanmadan kart yazma isteği gönderilmez.
      await sahipSecimleriniKaydet(onaylanan);
      setSatirlar(onaylanan);
      const cevap = await fetch("/api/products/batch", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          products: onayliGonderilecek.map(({ satir, sira, degerlendirme }) =>
            faturaUrunIstekGirdisi(satir, sira, degerlendirme, belge, categories, true),
          ),
        }),
      });

      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        throw new Error(
          govde && typeof govde.hata === "string" ? govde.hata : "Ürünler kaydedilemedi.",
        );
      }

      // HTTP 200 veya tamam:true, tek başına ürün yazıldığını ispatlamaz.
      if (!govde || typeof govde.eklenen !== "number" || govde.eklenen < 1) {
        const hata = Array.isArray(govde?.satirlar)
          ? govde.satirlar.map((item: { sebep?: string }) => item.sebep).filter(Boolean).join(" · ")
          : "";
        throw new Error(hata || "Hiçbir ürün kartı kaydedilemedi. Değişiklikler faturada saklandı.");
      }
      setSonuc(govde as YazmaSonucu);
      setAdim("bitti");
      await onUploaded();
    } catch (err) {
      setHata(err instanceof Error ? err.message : "Ürünler kaydedilemedi.");
      setAdim("urunler");
    }
  }

  /** Sonuç ekranındaki ayrı Yayınla: taslak kalan ürünler sunucuda tekrar
   * okunup görünür yapılır. Kapı kapalıysa ürün taslak kalır, sebep yazar. */
  async function taslaklariYayinla() {
    const taslakIdler = (sonuc?.satirlar ?? [])
      .filter((satir) => satir.durum === "taslak" && satir.id)
      .map((satir) => satir.id as string);
    if (taslakIdler.length === 0 || yukleniyor) return;

    setYukleniyor(true);
    setHata(null);
    try {
      const cevap = await fetch("/api/fatura-yayinla", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ slug: storeSlug, productIds: taslakIdler }),
      });
      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        throw new Error(
          govde && typeof govde.hata === "string" ? govde.hata : "Ürünler yayınlanamadı.",
        );
      }
      const yayinlananIdler = new Set<string>(
        ((govde?.satirlar ?? []) as Array<{ id: string; durum: string }>)
          .filter((satir) => satir.durum === "yayinda")
          .map((satir) => satir.id),
      );
      const sebepler = new Map<string, string>(
        ((govde?.satirlar ?? []) as Array<{ id: string; durum: string; sebep?: string }>)
          .filter((satir) => satir.durum !== "yayinda" && satir.sebep)
          .map((satir) => [satir.id, satir.sebep as string]),
      );
      setSonuc((onceki) => {
        if (!onceki) return onceki;
        const satirlar = onceki.satirlar.map((satir) => {
          if (satir.durum !== "taslak" || !satir.id || !yayinlananIdler.has(satir.id)) {
            const yeniSebep = satir.id ? sebepler.get(satir.id) : undefined;
            return yeniSebep ? { ...satir, sebep: yeniSebep } : satir;
          }
          return { ...satir, durum: "yayinda", sebep: undefined };
        });
        const yayinda = satirlar.filter((satir) => satir.durum === "yayinda").length;
        return {
          ...onceki,
          tuketiciDogrulandi: govde?.tuketiciDogrulamasi === "tamam",
          yayinda,
          taslak: satirlar.filter((satir) => satir.durum === "taslak").length,
          satirlar,
        };
      });
      await onUploaded();
    } catch (err) {
      setHata(err instanceof Error ? err.message : "Ürünler yayınlanamadı.");
    } finally {
      setYukleniyor(false);
    }
  }

  function bastanBasla() {
    setAdim("sec");
    setOnizleme(null);
    setBelge(null);
    setSatirlar([]);
    setSonuc(null);
    setOtomatikTaslakRaporu(null);
    setHata(null);
    if (dosyaRef.current) dosyaRef.current.value = "";
  }

  // ─── 1. Fatura seç ─────────────────────────────────────────────

  if (adim === "sec") {
    return (
      <div className="fatura-akis">
        <h3>Faturadan ürün ekle</h3>
        <p className="fatura-aciklama">
          Faturanın fotoğrafını yükle. Ürün kartları hazırlanır. Satış fiyatını yazıp yayınlarsın.
          Sen yayınlamadan hiçbir ürün vitrinde görünmez.
        </p>

        {hata && <p className="fatura-hata">{hata}</p>}

        {oncekiIslemler.length > 0 && (
          <div className="fatura-onceki">
            <h4>Devam edebileceğin faturalar</h4>
            <ul>
              {oncekiIslemler.map((islem) => (
                <li key={islem.islemKimligi}>
                  <span>
                    {islem.tedarikci || "Firma okunamadı"} • {islem.satirSayisi} satır •{" "}
                    {new Date(islem.olusturma).toLocaleDateString("tr-TR")}
                  </span>
                  <button
                    type="button"
                    onClick={() => void islemiAc(islem.islemKimligi)}
                    disabled={yukleniyor}
                  >
                    Devam et
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}

        {!okuyucuHazir && <p className="fatura-aciklama">Fotoğraf okuyucu şu an hazır değil.</p>}
        <input
          disabled={!okuyucuHazir}
          ref={dosyaRef}
          type="file"
          accept="image/jpeg,image/png,image/webp,application/pdf"
          multiple
          onChange={(e) => {
            const dosyalar = Array.from(e.target.files ?? []);
            if (dosyalar.length) void dosyaSecildi(dosyalar);
          }}
        />
        <p className="fatura-aciklama">Fatura fotoğrafını (1–3 sayfa) veya PDF dosyasını seç. Toplam en fazla 4 MB. Başka belge gerekmiyor.</p>
        {onClose && (
          <button type="button" className="fatura-ikincil" onClick={() => void kapat()}>
            Vazgeç
          </button>
        )}
      </div>
    );
  }

  // ─── 2. Hazırlanıyor ───────────────────────────────────────────

  if (adim === "okunuyor") {
    return (
      <div className="fatura-akis">
        <h3>Faturan hazırlanıyor</h3>
        {onizleme && <img className="fatura-onizleme" src={onizleme} alt="Fatura" />}
        <ol className="fatura-adimlar">
          <li>Belge okunuyor: satırlar, miktar ve belge toplamı çıkarılıyor.</li>
          <li>Faturayı kesen firmanın kimliği ve resmî sitesi araştırılıyor.</li>
          <li>Ürünlerin resmî kaynağı ve kaynak çelişkisi kontrol ediliyor.</li>
          <li>Kanıtlı satırlardan kart taslakları hazırlanıyor.</li>
        </ol>
      </div>
    );
  }

  // ─── 4. Sonuç ──────────────────────────────────────────────────

  if (adim === "bitti" && sonuc) {
    const yayinlanabilirTaslak = sonuc.satirlar.filter(
      (satir) => satir.durum === "taslak" && satir.id,
    ).length;

    type YayindakiKart = { sira: number; ad: string; fiyat: string; gorsel: string | null };
    const yayindakiKartlar: YayindakiKart[] = [];
    for (const satir of sonuc.satirlar) {
      if (satir.durum !== "yayinda") continue;
      const yerel = satirlar[satir.sira];
      if (!yerel) continue;
      yayindakiKartlar.push({
        sira: satir.sira,
        ad: yerel.katalog?.resmiAd || yerel.ad,
        fiyat: yerel.satisFiyati,
        gorsel: degerlendirmeler[satir.sira]?.gorseller[0] ?? yerel.esnafGorselleri[0] ?? null,
      });
    }

    return (
      <div className="fatura-akis">
        {yayindakiKartlar.length > 0 && (
          <section className="fatura-vitrin-hazir">
            <h3>Vitrin hazır</h3>
            <p className="fatura-aciklama">
              {yayindakiKartlar.length} ürün satış fiyatıyla vitrine yerleşti. Aşağıda
              müşterilerin göreceği hâli var; paylaşabilir veya ürünleri düzenleyebilirsin.
            </p>
            <ul className="fatura-vitrin-izgara">
              {yayindakiKartlar.map((kart) => (
                <li key={kart.sira}>
                  {kart.gorsel ? (
                    <img src={kart.gorsel} alt={kart.ad} loading="lazy" />
                  ) : (
                    <div className="fatura-kart-gorselsiz">Fotoğraf yok</div>
                  )}
                  <span>{kart.ad}</span>
                  {kart.fiyat && <strong>{kart.fiyat} TL</strong>}
                </li>
              ))}
            </ul>
            <div className="fatura-araclar">
              <button type="button" onClick={() => void vitriniPaylas()}>
                {baglantiKopyalandi ? "Bağlantı kopyalandı" : "Vitrini paylaş"}
              </button>
              {onClose && (
                <button type="button" onClick={() => void kapat()}>
                  Ürünleri düzenle
                </button>
              )}
              <button
                type="button"
                className="fatura-ikincil"
                onClick={() => setAdim("urunler")}
              >
                Ürünlere dön
              </button>
            </div>
          </section>
        )}

        <h3>{yayindakiKartlar.length > 0 ? "Kayıt özeti" : "Ürünler kaydedildi"}</h3>
        <ul className="fatura-ozet">
          <li>
            <strong>{sonuc.yayinda}</strong> ürün {sonuc.tuketiciDogrulandi ? "vitrinde görünüyor" : "için yayın kaydı alındı; tüketici görünümü doğrulanamadı"}
          </li>
          <li>
            <strong>{sonuc.taslak}</strong> ürün taslak — yayınlamadan görünmez
          </li>
          {sonuc.hatali > 0 && (
            <li>
              <strong>{sonuc.hatali}</strong> satır eklenemedi
            </li>
          )}
        </ul>

        <ul className="fatura-satir-ozet">
          {sonuc.satirlar
            .filter((satir) => satir.durum !== "yayinda")
            .map((satir) => (
              <li key={satir.sira}>
                {satir.ad} — {satir.sebep ?? satir.durum}
              </li>
            ))}
        </ul>

        {hata && <p className="fatura-hata">{hata}</p>}

        {belge?.islemKimligi && (
          <FirmaIzniPaneli storeSlug={storeSlug} islemKimligi={belge.islemKimligi} />
        )}

        {yayinlanabilirTaslak > 0 && (
          <button type="button" onClick={taslaklariYayinla} disabled={yukleniyor}>
            {yukleniyor ? "Yayınlanıyor…" : `${yayinlanabilirTaslak} taslağı yayınla`}
          </button>
        )}

        <button type="button" onClick={bastanBasla}>
          Başka fatura ekle
        </button>
        {onClose && (
          <button type="button" className="fatura-ikincil" onClick={() => void kapat()}>
            Kapat
          </button>
        )}
      </div>
    );
  }

  // ─── 3. Ürünler (yazma sırasında kilitli hâliyle aynı ekran) ───

  const yaziliyor = adim === "yaziliyor";
  const kanitliSayisi = satirlar.filter((satir) => satir.sonuc === "kanitli").length;
  const bekleyenSatir = satirlar.length - hazirSayisi;
  const ozet = belge?.sonucOzeti;

  return (
    <div className="fatura-akis">
      <div className="fatura-baslik">
        <h3>{satirlar.length} satır okundu</h3>
        {belge?.maliyetOzeti && (
          <p role="status" className="fatura-aciklama">
            OpenRouter bildirilen gerçek tutar: ${belge.maliyetOzeti.gercekUsd.toFixed(4)} USD.
            ${belge.maliyetOzeti.tahminiKayitSayisi > 0
              ? ` ${belge.maliyetOzeti.tahminiKayitSayisi} kullanımın maliyeti henüz doğrulanamadı; ${belge.maliyetOzeti.tahminiUsd.toFixed(4)} USD tahmin.`
              : ""}
            {" "}Bütçe payı ${belge.maliyetOzeti.ayrilanButceUsd.toFixed(4)} USD gerçek ödeme değildir.
          </p>
        )}
        {otomatikTaslakRaporu && <p role="status" className="fatura-aciklama">
          {otomatikTaslakRaporu.kaydedildi} ürün görünmez taslak olarak kaydedildi.
          {otomatikTaslakRaporu.atlandi > 0 ? ` ${otomatikTaslakRaporu.atlandi} satır kaydedilemedi.` : ""}
        </p>}
        {belge && (
          <p className="fatura-aciklama">
            Firma: {belgedeYazi(belge.tedarikci)}
            {" · "}
            Vergi no: {belgedeYazi(belge.tedarikciVergiNo)}
            {" · "}
            Adres: {belgedeYazi(belge.tedarikciAdres)}
            {" · "}
            Resmi site: {firmaSiteCumlesi(belge.siteDurumu)}
            {belge.belgeAdedi !== null ? ` · Belgede toplam miktar: ${belge.belgeAdedi}` : ""}
            {belge.belgeToplami !== null ? ` · ${paraYaz(belge.belgeToplami)} alış toplamı` : ""}
          </p>
        )}
      </div>

      {belge?.belgeUyarisi && (
        <p className="fatura-hata" role="status">
          Belge kontrolü: {belge.belgeUyarisi}
        </p>
      )}

      <ul className="fatura-kontrol" role="status">
        <li>
          <strong>{kontrol.satirSayisi}</strong> ürün satırı bulundu
        </li>
        <li className={kontrol.adetTutuyor === false ? "fatura-kontrol-farkli" : undefined}>
          <strong>{kontrol.miktarOzeti || "—"}</strong> fatura miktarı
          {kontrol.karisikBirim && <> — farklı ölçü birimleri toplanmadı</>}
          {kontrol.adetTutuyor === false && <> — belgede toplam {belge?.belgeAdedi} yazıyor</>}
        </li>
        <li className={kontrol.tutarTutuyor === false ? "fatura-kontrol-farkli" : undefined}>
          <strong>{paraYaz(kontrol.tutarToplam)}</strong> ürün satırları toplamı (KDV hariç)
          {kontrol.tutarTutuyor === false && (
            <> — belgede KDV hariç ara toplam {paraYaz(kontrol.araToplam ?? null)}</>
          )}
          {kontrol.tutarTutuyor === null && <> — belge ara toplamıyla karşılaştırılamadı</>}
        </li>
      </ul>

      {(belge?.ayniAlisveris ?? []).map((aday) => (
        <div key={aday.islemKimligi} className="fatura-hata" role="status">
          <p>
            Bu belge, daha önce yüklediğin{aday.belgeNo ? ` ${aday.belgeNo} numaralı` : ""}
            {aday.belgeTarihi ? ` ${aday.belgeTarihi} tarihli` : ""} belgeyle aynı alışveriş olabilir.{" "}
            {aday.sebep} Aynı alışverişse adetler ikinci kez eklenmez.
          </p>
          {alisverisCevaplari[aday.islemKimligi] === undefined ? (
            <>
              <button type="button" onClick={() => alisverisCevapla(aday, true)}>
                Evet, aynı alışveriş
              </button>
              <button type="button" onClick={() => alisverisCevapla(aday, false)}>
                Hayır, ayrı alışveriş
              </button>
            </>
          ) : (
            <p>
              {alisverisCevaplari[aday.islemKimligi]
                ? "Aynı alışveriş olarak kaydedildi."
                : "Ayrı alışveriş olarak kaydedildi."}
            </p>
          )}
        </div>
      ))}

      {ozet && (
        <ul className="fatura-ozet-satirlari">
          <li>
            <strong>{ozet.kanitli ?? 0}</strong> kanıtlı
          </li>
          <li>
            <strong>{ozet.eksik ?? 0}</strong> eksik bilgi
          </li>
          <li>
            <strong>{ozet.celiski ?? 0}</strong> çelişki
          </li>
          <li>
            <strong>{ozet.izYok ?? 0}</strong> iz bulunamadı
          </li>
        </ul>
      )}

      <p className="fatura-aciklama">
        Faturadaki tutar <strong>alış fiyatıdır</strong>; satış fiyatı yerine geçmez.
        Stok, faturadaki adettir. Yalnız fotoğrafı üreticinin sayfasından gelen satırlar kart olur.
        <strong>Satış fiyatını</strong> yazıp yayınla.
      </p>

      {hata && <p className="fatura-hata">{hata}</p>}

      <div className="fatura-araclar">
        <label>
          Alış fiyatının üzerine
          <input
            type="number"
            min={0}
            max={500}
            value={kar}
            onChange={(e) => setKar(e.target.value)}
            disabled={yaziliyor}
          />
          %
        </label>
        <button type="button" onClick={karUygula} disabled={yaziliyor}>
          Kâr koy
        </button>
      </div>

      {belge?.islemKimligi && satirlar.some((satir) => satir.katalog !== null) && (
        <FirmaIzniPaneli storeSlug={storeSlug} islemKimligi={belge.islemKimligi} />
      )}

      <div className="fatura-izgara">
        {satirlar.map((satir, index) => {
          const degerlendirme = degerlendirmeler[index];
          const bilgi = durumBilgisi(satir);
          const katalog = satir.katalog;
          const dusukGuven = satir.guven < GUVEN_ESIGI;
          return (
            <article
              key={`${satir.model}-${satir.barkod}-${index}`}
              className={`fatura-kart fatura-kart-${satir.sonuc}`}
            >
              <span className="fatura-rozet">{KART_DURUM_ETIKETI[satir.sonuc]}</span>
              {dusukGuven && <span className="fatura-rozet fatura-rozet-suphe">Kontrol et</span>}

              {degerlendirme.gorseller.length > 0 ? (
                <img
                  className="fatura-kart-gorsel"
                  src={degerlendirme.gorseller[0]}
                  alt={katalog?.resmiAd || satir.ad}
                  loading="lazy"
                />
              ) : (
                <div className="fatura-kart-gorselsiz">Fotoğraf yok</div>
              )}

              {satir.model && <div className="fatura-model">{satir.model}</div>}
              <div className="fatura-ad">{katalog?.resmiAd || satir.ad}</div>

              <div className="fatura-durum">{bilgi.detay}</div>

              {satir.sonuc !== "kanitli" && belge?.islemKimligi && (
                <details className="fatura-duzelt">
                  <summary>Kodu ya da markayı düzelt</summary>
                  <label>
                    Ürün kodu
                    <input
                      type="text"
                      value={duzeltmeler[index]?.model ?? satir.model}
                      onChange={(e) =>
                        setDuzeltmeler((onceki) => ({
                          ...onceki,
                          [index]: {
                            model: e.target.value,
                            barkod: onceki[index]?.barkod ?? satir.barkod,
                            marka: onceki[index]?.marka ?? satir.marka ?? "",
                          },
                        }))
                      }
                    />
                  </label>
                  <label>
                    Barkod
                    <input
                      type="text"
                      inputMode="numeric"
                      value={duzeltmeler[index]?.barkod ?? satir.barkod}
                      onChange={(e) =>
                        setDuzeltmeler((onceki) => ({
                          ...onceki,
                          [index]: {
                            model: onceki[index]?.model ?? satir.model,
                            barkod: e.target.value,
                            marka: onceki[index]?.marka ?? satir.marka ?? "",
                          },
                        }))
                      }
                    />
                  </label>
                  <label>
                    Marka
                    <input
                      type="text"
                      value={duzeltmeler[index]?.marka ?? satir.marka ?? ""}
                      onChange={(e) =>
                        setDuzeltmeler((onceki) => ({
                          ...onceki,
                          [index]: {
                            model: onceki[index]?.model ?? satir.model,
                            barkod: onceki[index]?.barkod ?? satir.barkod,
                            marka: e.target.value,
                          },
                        }))
                      }
                    />
                  </label>
                  <button
                    type="button"
                    onClick={() => void satiriDuzelt(index)}
                    disabled={yaziliyor || duzeltilen !== null}
                  >
                    {duzeltilen === index ? "Aranıyor…" : "Yeniden eşleştir"}
                  </button>
                </details>
              )}

              {(satir.celiski?.adaylar.length ?? 0) > 0 && (
                <ul className="fatura-adaylar">
                  {satir.celiski?.adaylar.map((aday) => (
                    <li key={aday.kaynak}>
                      {aday.kaynak ? (
                        <a href={aday.kaynak} target="_blank" rel="noreferrer">
                          {aday.ad}
                        </a>
                      ) : (
                        aday.ad
                      )}
                      {aday.kaynak && Array.isArray(aday.gorseller) && (
                        <button
                          type="button"
                          onClick={() => void adaySec(index, aday.kaynak)}
                          disabled={yaziliyor || duzeltilen !== null}
                        >
                          Bunu seç
                        </button>
                      )}
                    </li>
                  ))}
                </ul>
              )}

              {katalog ? (
                <div className="fatura-eslesme">
                  <a href={katalog.kaynak} target="_blank" rel="noreferrer">
                    Kaynak
                  </a>
                  {" · "}
                  {katalog.kaynakFirma}
                  {" · "}
                  {katalog.dayanak === "barkod" ? "barkod" : katalog.dayanak === "ad" ? "ürün adı" : "ürün kodu"}
                  {" · "}
                  {degerlendirme.gorseller.length} fotoğraf
                  {" · "}
                  {katalog.izinDurumu === "var"
                    ? "üretici izni var"
                    : "üretici fotoğrafı — kullanım izni sonra istenecek"}
                </div>
              ) : (
                <div className="fatura-eslesme fatura-eslesme-yok">
                  Kanıtlı eşleşme yok — bu satırdan kart üretilmez
                </div>
              )}

              {katalog && katalog.gorselAdaylari.length > 0 && (
                <ul className="fatura-adaylar">
                  {katalog.gorselAdaylari.slice(0, 3).map((aday) => (
                    <li key={aday}>
                      <a href={aday} target="_blank" rel="noreferrer">
                        Fotoğraf adayı
                      </a>
                    </li>
                  ))}
                </ul>
              )}

              <div className="fatura-cipler">
                {satir.beden && <span>{satir.beden}</span>}
                {satir.varyant && <span>{satir.varyant}</span>}
                {satir.adet !== null && (
                  <span>Faturada {satir.adet}{satir.birim?.trim() ? ` ${satir.birim.trim()}` : ""}</span>
                )}
              </div>

              <div className="fatura-alis">
                Alış: {paraYaz(satir.alisBirimFiyat)}
                {satir.barkod && ` • Barkod: ${satir.barkod}`}
              </div>

              {katalog?.aciklama ? (
                <p className="fatura-aciklama">{katalog.aciklama}</p>
              ) : katalog ? (
                <div className="fatura-durum">Kaynaktan açıklama gelmedi.</div>
              ) : null}

              <label className="fatura-fiyat">
                Satış fiyatı
                <input
                  inputMode="decimal"
                  placeholder="0,00"
                  value={satir.satisFiyati}
                  onChange={(e) => satirGuncelle(index, { satisFiyati: e.target.value })}
                  disabled={yaziliyor}
                />
              </label>

              {degerlendirme.bilgiEksikleri.length > 0 && (
                <ul className="fatura-eksikler">
                  {degerlendirme.bilgiEksikleri.map((eksik) => (
                    <li key={eksik}>{eksik}</li>
                  ))}
                </ul>
              )}

              {satir.ayniAlisverisTekrari && (
                <p className="fatura-hata" role="status">
                  Bu ürün aynı alışverişin ilk belgesinde zaten var; stok ikinci kez eklenmez.
                </p>
              )}
            </article>
          );
        })}
      </div>

      {belge?.aramaSuruyor && (
        <button
          type="button"
          className="fatura-ikincil"
          disabled={yaziliyor || yukleniyor}
          onClick={() => {
            const dosya = sonFaturaDosyasi.current;
            if (dosya) void dosyaSecildi(dosya);
          }}
        >
          Kalan satırların araştırmasına devam et
        </button>
      )}
      <div className="fatura-alt-cubuk">
        {onClose && <button type="button" className="fatura-ikincil"
          onClick={() => void kapat()} disabled={yaziliyor || yukleniyor}>İşlemi kapat</button>}
        <span>
          {hazirSayisi} / {satirlar.length} hazır
        </span>
        <button
          type="button"
          onClick={() => void vitrineYaz()}
          disabled={hazirSayisi === 0 || yaziliyor}
        >
          {yaziliyor ? "Yayınlanıyor…" : `${hazirSayisi} kartı onayla ve yayınla`}
        </button>
      </div>

      {bekleyenSatir > 0 && (
        <p className="fatura-aciklama">
          <strong>{bekleyenSatir}</strong> satır yayına hazır değil; onlar inceleme kaydında
          kalır, yayına girmez.
          {kanitliSayisi < satirlar.length && (
            <> Kanıtsız satırlar için tahmin yapılmaz.</>
          )}
        </p>
      )}
    </div>
  );
}
