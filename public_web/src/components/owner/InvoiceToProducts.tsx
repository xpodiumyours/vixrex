"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import FirmaIzniPaneli from "@/components/owner/FirmaIzniPaneli";
import { kategoriSec, otomatikOzellikler } from "@/lib/faturaOtomatikDoldur";
import {
  KART_DURUM_ETIKETI,
  durumBilgisi,
  kartDegerlendir,
  type KartDurumu,
} from "@/lib/faturaKartDurumu";
import {
  MAX_PRODUCT_IMAGES,
  MAX_PRODUCT_IMAGE_SOURCE_BYTES,
  MAX_PRODUCT_IMAGE_SOURCE_MEGABYTES,
} from "@/lib/productImagePolicy";

// Faturadan ürün kartına — 4 adımlı esnaf akışı.
//
// Kilitli kural: buradan çıkan hiçbir ürün kendiliğinden yayına girmez.
// İKİ AYRI eylem var: "Bilgileri onayla" yalnız taslak kaydeder,
// "Yayınla" görünür yapar. Esnaf satış fiyatını girer, stoğu onaylar ve
// kartı açıkça onaylar; sunucu (products/batch + fatura-yayinla +
// veritabanı tetiği) bunu ayrıca, arayüze güvenmeden kontrol eder.
// Fatura alış fiyatı satış fiyatı olmaz; faturadaki miktar stok yerine geçmez.

export interface CeliskiBilgisi {
  dayanak: "kod" | "barkod";
  adaylar: Array<{ ad: string; kaynak: string }>;
}

export interface FaturaSatiri {
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
  sonuc: KartDurumu;
  uyari?: string;
  celiski?: CeliskiBilgisi;
  katalog: KatalogBilgisi | null;
}

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
  satirlar: FaturaOkumaSatiri[];
  belgeToplami: number | null;
  belgeAdedi: number | null;
  /** Toplam tutmadıysa akış durmaz; bu uyarı esnafa gösterilir. */
  belgeUyarisi?: string;
  tedarikci: string;
  tedarikciVergiNo?: string;
  tedarikciSite?: string;
  katalogEslesmesi?: number;
  sonucOzeti?: Record<string, number>;
  islemKimligi?: string | null;
  ayniAlisveris?: AyniAlisverisAdayi[];
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
}

/** Bu eşiğin altındaki satır toplu onaya girmez; esnaf ona tek tek bakar. */
const GUVEN_ESIGI = 0.7;
const MAKS_BAYT = 5 * 1024 * 1024;

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
  return Number.isInteger(n) && n >= 0 ? n : null;
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

export default function InvoiceToProducts({
  storeSlug,
  categories = [],
  onUploaded,
  onClose,
  baslangicIslemKimligi,
}: InvoiceToProductsProps) {
  const [adim, setAdim] = useState<"sec" | "okunuyor" | "urunler" | "yaziliyor" | "bitti">(
    "sec",
  );
  const [onizleme, setOnizleme] = useState<string | null>(null);
  const [belge, setBelge] = useState<FaturaOkumaSonucu | null>(null);
  const [satirlar, setSatirlar] = useState<SatirDurumu[]>([]);
  const [kar, setKar] = useState("40");
  // Firmanın sitesi faturada okunamazsa esnaf yazar (zorunlu değil):
  // havuzda olmayan firmanın keşfi buradan yürür.
  const [firmaSitesi, setFirmaSitesi] = useState("");
  const [hata, setHata] = useState<string | null>(null);
  const [yukleniyor, setYukleniyor] = useState(false);
  const [sonuc, setSonuc] = useState<YazmaSonucu | null>(null);
  const [alisverisCevaplari, setAlisverisCevaplari] = useState<Record<string, boolean>>({});
  const [oncekiIslemler, setOncekiIslemler] = useState<OncekiIslem[]>([]);
  const [duzeltmeler, setDuzeltmeler] = useState<
    Record<number, { model: string; barkod: string; marka: string }>
  >({});
  const [duzeltilen, setDuzeltilen] = useState<number | null>(null);
  const dosyaRef = useRef<HTMLInputElement>(null);
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
          stokOnaylandi: satir.stokOnaylandi,
          esnafGorselleri: satir.esnafGorselleri,
          onaylandi: satir.onayli,
        }),
      ),
    [satirlar],
  );

  const hazirSayisi = degerlendirmeler.filter((d) => d.yayinaHazir).length;
  const onayliSayisi = degerlendirmeler.filter((d, i) => d.onaylanabilir && satirlar[i].onayli).length;

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
      setBelge(acilan);
      setSatirlar(satirlariHazirla(acilan));
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
    async (dosya: File) => {
      setHata(null);

      if (dosya.size > MAKS_BAYT) {
        setHata("Fotoğraf çok büyük. En fazla 5 MB.");
        return;
      }

      const okuyucu = new FileReader();
      okuyucu.onload = () => setOnizleme(String(okuyucu.result));
      okuyucu.readAsDataURL(dosya);

      setAdim("okunuyor");

      try {
        const form = new FormData();
        form.append("slug", storeSlug);
        form.append("dosya", dosya);
        if (firmaSitesi.trim()) form.append("firmaSitesi", firmaSitesi.trim());

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
        setBelge(okunan);
        setSatirlar(satirlariHazirla(okunan));
        setAdim("urunler");
      } catch (err) {
        setHata(err instanceof Error ? err.message : "Fatura okunamadı.");
        setAdim("sec");
      }
    },
    [firmaSitesi, satirlariHazirla, storeSlug],
  );

  function satirGuncelle(index: number, degisiklik: Partial<SatirDurumu>) {
    setSatirlar((oncekiler) =>
      oncekiler.map((satir, i) => (i === index ? {
        ...satir,
        ...degisiklik,
        onayli: degisiklik.onayli ?? false,
        stokOnaylandi: degisiklik.stok !== undefined ? false : (degisiklik.stokOnaylandi ?? satir.stokOnaylandi),
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

  async function gorselYukle(index: number, dosyalar: FileList | null) {
    const secilenler = Array.from(dosyalar ?? []);
    if (secilenler.length === 0) return;

    setYukleniyor(true);
    setHata(null);
    const yeni: string[] = [];

    for (const dosya of secilenler) {
      if (dosya.size > MAX_PRODUCT_IMAGE_SOURCE_BYTES) {
        setHata(`${dosya.name} çok büyük. En fazla ${MAX_PRODUCT_IMAGE_SOURCE_MEGABYTES} MB.`);
        continue;
      }
      const form = new FormData();
      form.append("slug", storeSlug);
      form.append("productId", "new");
      form.append("dosya", dosya);
      try {
        const cevap = await fetch("/api/product-image-upload", { method: "POST", body: form });
        const govde = await cevap.json().catch(() => null);
        if (!cevap.ok) {
          setHata(govde?.hata ?? "Görsel yüklenemedi.");
          continue;
        }
        if (govde?.url) yeni.push(String(govde.url));
      } catch {
        setHata("Görsel yüklenemedi.");
      }
    }

    if (yeni.length > 0) {
      setSatirlar((oncekiler) =>
        oncekiler.map((satir, i) =>
          i === index
            ? {
                ...satir,
                esnafGorselleri: [...satir.esnafGorselleri, ...yeni].slice(0, MAX_PRODUCT_IMAGES),
              }
            : satir,
        ),
      );
    }
    setYukleniyor(false);
  }

  /**
   * İKİ AYRI eylem, tek yazma yolu:
   * - yayinIstegi=false → "Bilgileri onayla": onaylı satırlar TASLAK kaydedilir.
   * - yayinIstegi=true → "Yayınla": onaylı VE yayına hazır satırlar için
   *   sunucudan görünürlük istenir; sunucu kapıları yeniden okur.
   */
  async function vitrineYaz(yayinIstegi: boolean) {
    const gonderilecek = satirlar
      .map((satir, sira) => ({ satir, sira, degerlendirme: degerlendirmeler[sira] }))
      .filter(({ satir, degerlendirme }) =>
        satir.onayli && !satir.ayniAlisverisTekrari &&
        (yayinIstegi ? degerlendirme.yayinaHazir : degerlendirme.onaylanabilir),
      );

    if (gonderilecek.length === 0) return;

    setAdim("yaziliyor");
    setHata(null);

    try {
      await sahipSecimleriniKaydet(satirlar);
      const cevap = await fetch("/api/products/batch", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          products: gonderilecek.map(({ satir, sira, degerlendirme }) => {
            const satisFiyati = fiyatSayisi(satir.satisFiyati);
            const katalog = satir.katalog;
            return {
              name: katalog?.resmiAd || satir.ad,
              description: katalog?.aciklama ?? "",
              priceText: `${satisFiyati} TL`,
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
                  ? [belge?.tedarikciVergiNo || belge?.tedarikci || "", satir.barkod || satir.model]
                      .filter(Boolean)
                      .join(":")
                  : undefined,
              islemKimligi: belge?.islemKimligi || undefined,
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
              variants:
                satir.varyant || satir.beden
                  ? [
                      {
                        id: `v-${(satir.model || satir.barkod || String(sira)).toLowerCase()}`,
                        options: {
                          ...(satir.varyant ? { color: satir.varyant } : {}),
                          ...(satir.beden ? { size: satir.beden } : {}),
                        },
                        stockQuantity: stokSayisi(satir.stok) ?? undefined,
                      },
                    ]
                  : undefined,
              sortOrder: sira,
            };
          }),
        }),
      });

      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok) {
        throw new Error(
          govde && typeof govde.hata === "string" ? govde.hata : "Ürünler kaydedilemedi.",
        );
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
    setHata(null);
    if (dosyaRef.current) dosyaRef.current.value = "";
  }

  // ─── 1. Fatura seç ─────────────────────────────────────────────

  if (adim === "sec") {
    return (
      <div className="fatura-akis">
        <h3>Faturadan ürün ekle</h3>
        <p className="fatura-aciklama">
          Faturanın fotoğrafını yükle. Vixrex ürünleri hazırlar; satış fiyatlarını ve stoğu sen
          onaylarsın. <strong>Sen yayınlamadan hiçbir ürün vitrinde görünmez. Bilgileri onaylamak yalnız taslak kaydeder.</strong>
        </p>

        {hata && <p className="fatura-hata">{hata}</p>}

        <label className="fatura-fiyat">
          Firmanın internet sitesini biliyorsan yaz (zorunlu değil)
          <input
            type="text"
            inputMode="url"
            placeholder="ornekfirma.com"
            value={firmaSitesi}
            onChange={(e) => setFirmaSitesi(e.target.value)}
          />
        </label>

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

        <input
          ref={dosyaRef}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          onChange={(e) => {
            const dosya = e.target.files?.[0];
            if (dosya) void dosyaSecildi(dosya);
          }}
        />

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
    return (
      <div className="fatura-akis">
        <h3>Ürünler kaydedildi</h3>
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
        {belge && (
          <p className="fatura-aciklama">
            {belge.tedarikci ? `${belge.tedarikci} • ` : ""}
            {belge.tedarikciSite ? `${belge.tedarikciSite} • ` : ""}
            {belge.belgeAdedi !== null ? `${belge.belgeAdedi} adet • ` : ""}
            {belge.belgeToplami !== null ? `${paraYaz(belge.belgeToplami)} alış toplamı` : ""}
          </p>
        )}
      </div>

      {belge?.belgeUyarisi && (
        <p className="fatura-hata" role="status">
          Fatura toplamı satırlarla tutmadı; okunan satırlar kaybolmadı, her satır kendi
          kanıtıyla değerlendiriliyor. Detay: {belge.belgeUyarisi}
        </p>
      )}

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
        Faturadaki rakamlar <strong>alış fiyatı</strong> ve <strong>alış adedidir</strong>;
        satış fiyatı ve stok yerine geçmez. Yalnız <strong>kanıtlı</strong> satırlardan kart
        çıkar. <strong>Satış fiyatını</strong> belirle, mevcut stoğunu kontrol edip kartı onayla.
        Kart önce taslak kaydedilir, <strong>Yayınla</strong> demeden görünmez.
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
          Fiyatları ayarla
        </button>
      </div>

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

              {bilgi.adaylar.length > 0 && (
                <ul className="fatura-adaylar">
                  {bilgi.adaylar.map((aday) => (
                    <li key={aday.kaynak}>
                      {aday.kaynak ? (
                        <a href={aday.kaynak} target="_blank" rel="noreferrer">
                          {aday.ad}
                        </a>
                      ) : (
                        aday.ad
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
                  {katalog.dayanak === "barkod" ? "barkod" : "ürün kodu"}
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
                {satir.adet !== null && <span>Faturada {satir.adet} adet</span>}
              </div>

              <div className="fatura-alis">
                Alış: {paraYaz(satir.alisBirimFiyat)}
                {satir.barkod && ` • Barkod: ${satir.barkod}`}
              </div>

              {katalog && !katalog.aciklama && (
                <div className="fatura-durum">Kaynaktan açıklama gelmedi.</div>
              )}

              {satir.sonuc === "kanitli" && (
                <>
                   <label className="fatura-fiyat">
                     Mevcut stok
                     <input inputMode="numeric" value={satir.stok}
                       onChange={(e) => satirGuncelle(index, { stok: e.target.value })}
                       disabled={yaziliyor} />
                   </label>
                   <label>
                     <input type="checkbox" checked={satir.stokOnaylandi}
                       onChange={(e) => satirGuncelle(index, { stokOnaylandi: e.target.checked })}
                       disabled={yaziliyor || stokSayisi(satir.stok) === null} />
                     Mevcut stok miktarını kontrol ettim
                   </label>

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

                  {degerlendirme.gorseller.length === 0 && (
                  <label className="fatura-gorsel-ekle">
                    Kendi fotoğrafını ekle ({degerlendirme.gorseller.length}/{MAX_PRODUCT_IMAGES})
                    <input
                      type="file"
                      accept="image/jpeg,image/png,image/webp"
                      multiple
                      onChange={(e) => {
                        void gorselYukle(index, e.target.files);
                        e.target.value = "";
                      }}
                      disabled={yaziliyor || yukleniyor}
                    />
                  </label>
                  )}

                  {degerlendirme.bilgiEksikleri.length > 0 && (
                    <ul className="fatura-eksikler">
                      {degerlendirme.bilgiEksikleri.map((eksik) => (
                        <li key={eksik}>{eksik}</li>
                      ))}
                    </ul>
                  )}

                  <button type="button"
                    onClick={() => satirGuncelle(index, { onayli: !satir.onayli })}
                    disabled={yaziliyor || !degerlendirme.onaylanabilir || satir.ayniAlisverisTekrari}>
                    {satir.onayli ? "Kart onaylandı — onayı kaldır" : "Kartı onayla"}
                  </button>

                  {satir.ayniAlisverisTekrari && (
                    <p className="fatura-hata" role="status">
                      Bu ürün aynı alışverişin ilk belgesinde zaten var; stok ikinci kez eklenmez.
                    </p>
                  )}

                </>
              )}
            </article>
          );
        })}
      </div>

      <div className="fatura-alt-cubuk">
        <span>
          {hazirSayisi} / {satirlar.length} hazır
        </span>
        <button
          type="button"
          onClick={() => void vitrineYaz(false)}
          disabled={onayliSayisi === 0 || yaziliyor}
        >
          {yaziliyor ? "Kaydediliyor…" : `${onayliSayisi} ürünü taslak kaydet`}
        </button>
        <button
          type="button"
          onClick={() => void vitrineYaz(true)}
          disabled={hazirSayisi === 0 || yaziliyor}
        >
          {yaziliyor ? "Yayınlanıyor…" : `${hazirSayisi} ürünü yayınla`}
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
