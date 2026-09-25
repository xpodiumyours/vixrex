"use client";

import { useCallback, useMemo, useRef, useState } from "react";

// Faturadan ürün kartına — 4 adımlı esnaf akışı.
//
// Kilitli kural: buradan çıkan hiçbir ürün kendiliğinden yayına girmez.
// Esnaf satış fiyatını girer ve kartı açıkça onaylar; sunucu (products/batch)
// bunu ayrıca bir daha kontrol eder. Fatura alış fiyatı satış fiyatı olmaz.

export interface FaturaSatiri {
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  adet: number | null;
  alisBirimFiyat: number | null;
  satirToplam: number | null;
  guven: number;
  /** Üretici kataloğundan gelen resmî bilgi. Eşleşme yoksa null. */
  katalog: KatalogBilgisi | null;
}

export interface KatalogBilgisi {
  firma: string;
  dayanak: "kod" | "barkod";
  izinDurumu: "yok" | "bekliyor" | "var";
  resmiAd: string;
  marka: string;
  aciklama: string;
  gorseller: string[];
  kaynak: string;
}

interface FaturaOkumaSonucu {
  satirlar: FaturaSatiri[];
  belgeToplami: number | null;
  belgeAdedi: number | null;
  tedarikci: string;
  katalogEslesmesi?: number;
}

interface SatirDurumu extends FaturaSatiri {
  satisFiyati: string;
  onayli: boolean;
  kategoriId: string;
}

interface YazmaSonucu {
  toplam: number;
  yayinda: number;
  taslak: number;
  hatali: number;
  satirlar: Array<{ sira: number; ad: string; durum: string; sebep?: string }>;
}

interface InvoiceToProductsProps {
  storeSlug: string;
  categories?: Array<{ id: string; name: string }>;
  onUploaded: () => Promise<void>;
  onClose?: () => void;
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
  const temiz = ham.trim().replace(/\s/g, "").replace(",", ".");
  if (!temiz) return null;
  const n = Number(temiz);
  return Number.isFinite(n) && n > 0 ? n : null;
}

/** Açıklama yalnız faturada gerçekten yazan bilgiden kurulur; uydurma yok. */
function faturaAciklamasi(satir: SatirDurumu): string {
  const parcalar: string[] = [];
  if (satir.varyant) parcalar.push(`Renk: ${satir.varyant}`);
  if (satir.beden) parcalar.push(`Beden: ${satir.beden}`);
  if (satir.adet !== null) parcalar.push(`Faturadaki miktar: ${satir.adet} adet`);
  const kuyruk = parcalar.length > 0 ? ` ${parcalar.join(", ")}.` : "";
  return `${satir.ad}.${kuyruk}`;
}

export default function InvoiceToProducts({
  storeSlug,
  categories = [],
  onUploaded,
  onClose,
}: InvoiceToProductsProps) {
  const [adim, setAdim] = useState<"sec" | "okunuyor" | "urunler" | "yaziliyor" | "bitti">(
    "sec",
  );
  const [onizleme, setOnizleme] = useState<string | null>(null);
  const [belge, setBelge] = useState<FaturaOkumaSonucu | null>(null);
  const [satirlar, setSatirlar] = useState<SatirDurumu[]>([]);
  const [toplamKategori, setToplamKategori] = useState<string>(categories[0]?.id ?? "");
  const [kar, setKar] = useState("40");
  const [hata, setHata] = useState<string | null>(null);
  const [sonuc, setSonuc] = useState<YazmaSonucu | null>(null);
  const dosyaRef = useRef<HTMLInputElement>(null);

  const hazirSayisi = useMemo(
    () => satirlar.filter((s) => s.onayli && fiyatSayisi(s.satisFiyati) !== null).length,
    [satirlar],
  );

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
        setSatirlar(
          okunan.satirlar.map((satir) => ({
            ...satir,
            satisFiyati: "",
            onayli: false,
            kategoriId: categories[0]?.id ?? "",
          })),
        );
        setAdim("urunler");
      } catch (err) {
        setHata(err instanceof Error ? err.message : "Fatura okunamadı.");
        setAdim("sec");
      }
    },
    [categories, storeSlug],
  );

  function satirGuncelle(index: number, degisiklik: Partial<SatirDurumu>) {
    setSatirlar((oncekiler) =>
      oncekiler.map((satir, i) => (i === index ? { ...satir, ...degisiklik } : satir)),
    );
  }

  function karUygula() {
    const oran = Math.max(0, Number(kar) || 0);
    setSatirlar((oncekiler) =>
      oncekiler.map((satir) => {
        if (satir.alisBirimFiyat === null) return satir;
        const hesap = Math.round(satir.alisBirimFiyat * (1 + oran / 100) * 100) / 100;
        return { ...satir, satisFiyati: String(hesap) };
      }),
    );
  }

  /** Güveni düşük satır toplu onaya girmez — esnaf ona tek tek bakar. */
  function tumunuOnayla() {
    setSatirlar((oncekiler) =>
      oncekiler.map((satir) => ({ ...satir, onayli: satir.guven >= GUVEN_ESIGI })),
    );
  }

  function onaylariKaldir() {
    setSatirlar((oncekiler) => oncekiler.map((satir) => ({ ...satir, onayli: false })));
  }

  function kategoriHepsineUygula(kategoriId: string) {
    setToplamKategori(kategoriId);
    setSatirlar((oncekiler) => oncekiler.map((satir) => ({ ...satir, kategoriId })));
  }

  async function vitrineYaz() {
    const gonderilecek = satirlar
      .map((satir, sira) => ({ satir, sira }))
      .filter(({ satir }) => satir.onayli && fiyatSayisi(satir.satisFiyati) !== null);

    if (gonderilecek.length === 0) return;

    setAdim("yaziliyor");
    setHata(null);

    try {
      const cevap = await fetch("/api/products/batch", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          products: gonderilecek.map(({ satir, sira }) => {
            const satisFiyati = fiyatSayisi(satir.satisFiyati);
            const katalog = satir.katalog;
            return {
              name: katalog?.resmiAd || satir.ad,
              description: katalog?.aciklama || faturaAciklamasi(satir),
              priceText: `${satisFiyati} TL`,
              categoryId: satir.kategoriId,
              // Üreticinin kendi yayınladığı fotoğraflar. Eşleşme yoksa boş
              // kalır ve ürün taslak olarak kaydedilir.
              imageUrls: katalog?.gorseller ?? [],
              brand: katalog?.marka || undefined,
              barcode: satir.barkod || undefined,
              stockQuantity: satir.adet ?? undefined,
              sourceType: "invoice",
              // Aynı fatura ikinci kez okunursa aynı satır aynı kimliğe düşer.
              externalProductId: satir.barkod || satir.model || undefined,
              ownerApproved: true,
              purchasePriceAmount: satir.alisBirimFiyat ?? undefined,
              metadata: satir.model ? { identifiers: { sku: satir.model } } : undefined,
              variants:
                satir.varyant || satir.beden
                  ? [
                      {
                        id: `v-${(satir.model || satir.barkod || String(sira)).toLowerCase()}`,
                        options: {
                          ...(satir.varyant ? { color: satir.varyant } : {}),
                          ...(satir.beden ? { size: satir.beden } : {}),
                        },
                        stockQuantity: satir.adet ?? undefined,
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
          Faturanın fotoğrafını yükle. Vixrex ürünleri hazırlar; satış fiyatlarını sen
          belirlersin. <strong>Sen onaylamadan hiçbir ürün vitrinde görünmez.</strong>
        </p>

        {hata && <p className="fatura-hata">{hata}</p>}

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
          <button type="button" className="fatura-ikincil" onClick={onClose}>
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
        <p className="fatura-aciklama">
          Ürün satırları ayrılıyor. Bu işlem birkaç saniye sürebilir.
        </p>
      </div>
    );
  }

  // ─── 4. Sonuç ──────────────────────────────────────────────────

  if (adim === "bitti" && sonuc) {
    return (
      <div className="fatura-akis">
        <h3>Ürünler kaydedildi</h3>
        <ul className="fatura-ozet">
          <li>
            <strong>{sonuc.yayinda}</strong> ürün vitrinde görünüyor
          </li>
          <li>
            <strong>{sonuc.taslak}</strong> ürün taslak — fotoğrafı eklenince görünecek
          </li>
          {sonuc.hatali > 0 && (
            <li>
              <strong>{sonuc.hatali}</strong> satır eklenemedi
            </li>
          )}
        </ul>

        {sonuc.taslak > 0 && (
          <p className="fatura-aciklama">
            Taslak ürünler kaydedildi ama müşteriye gösterilmiyor. Ürün fotoğrafları
            eklendiğinde kendiliğinden vitrine çıkarlar.
          </p>
        )}

        <ul className="fatura-satir-ozet">
          {sonuc.satirlar
            .filter((satir) => satir.durum !== "yayinda")
            .map((satir) => (
              <li key={satir.sira}>
                {satir.ad} — {satir.sebep ?? satir.durum}
              </li>
            ))}
        </ul>

        <button type="button" onClick={bastanBasla}>
          Başka fatura ekle
        </button>
        {onClose && (
          <button type="button" className="fatura-ikincil" onClick={onClose}>
            Kapat
          </button>
        )}
      </div>
    );
  }

  // ─── 3. Ürünler (yazma sırasında kilitli hâliyle aynı ekran) ───

  const yaziliyor = adim === "yaziliyor";
  const eslesenSayisi = satirlar.filter((satir) => satir.katalog !== null).length;
  const izinBekleyen = satirlar.some((satir) => satir.katalog?.izinDurumu !== "var");

  return (
    <div className="fatura-akis">
      <div className="fatura-baslik">
        <h3>{satirlar.length} ürün hazırlandı</h3>
        {belge && (
          <p className="fatura-aciklama">
            {belge.tedarikci ? `${belge.tedarikci} • ` : ""}
            {belge.belgeAdedi !== null ? `${belge.belgeAdedi} adet • ` : ""}
            {belge.belgeToplami !== null ? `${paraYaz(belge.belgeToplami)} alış toplamı` : ""}
          </p>
        )}
      </div>

      <p className="fatura-aciklama">
        Faturadaki rakamlar <strong>alış fiyatıdır</strong>. Satış fiyatını sen belirle,
        kartı onayla.
      </p>

      {eslesenSayisi > 0 && (
        <p className="fatura-aciklama">
          <strong>
            {eslesenSayisi} / {satirlar.length}
          </strong>{" "}
          ürün üretici kataloğunda bulundu; resmî ad, açıklama ve fotoğrafları hazır.
          {izinBekleyen && (
            <>
              {" "}
              <strong>Üretici izni henüz alınmadı</strong> — yayına almadan önce izin
              gerekir.
            </>
          )}
        </p>
      )}

      {hata && <p className="fatura-hata">{hata}</p>}

      {categories.length > 0 && (
        <label className="fatura-kategori">
          Kategori
          <select
            value={toplamKategori}
            onChange={(e) => kategoriHepsineUygula(e.target.value)}
            disabled={yaziliyor}
          >
            {categories.map((kategori) => (
              <option key={kategori.id} value={kategori.id}>
                {kategori.name}
              </option>
            ))}
          </select>
        </label>
      )}

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
          {satirlar.length} ürüne uygula
        </button>
        <button type="button" onClick={tumunuOnayla} disabled={yaziliyor}>
          Tümünü onayla
        </button>
        <button type="button" onClick={onaylariKaldir} disabled={yaziliyor}>
          Onayları kaldır
        </button>
      </div>

      <div className="fatura-izgara">
        {satirlar.map((satir, index) => {
          const dusukGuven = satir.guven < GUVEN_ESIGI;
          return (
            <article
              key={`${satir.model}-${satir.barkod}-${index}`}
              className={dusukGuven ? "fatura-kart fatura-kart-suphe" : "fatura-kart"}
            >
              {dusukGuven && <span className="fatura-rozet">Kontrol et</span>}

              {satir.katalog && satir.katalog.gorseller.length > 0 ? (
                <img
                  className="fatura-kart-gorsel"
                  src={satir.katalog.gorseller[0]}
                  alt={satir.katalog.resmiAd}
                  loading="lazy"
                />
              ) : (
                <div className="fatura-kart-gorselsiz">Fotoğraf yok</div>
              )}

              {satir.model && <div className="fatura-model">{satir.model}</div>}
              <div className="fatura-ad">{satir.katalog?.resmiAd || satir.ad}</div>

              {satir.katalog ? (
                <div className="fatura-eslesme">
                  {satir.katalog.firma} · {satir.katalog.gorseller.length} fotoğraf
                  {satir.katalog.dayanak === "barkod" ? " · barkod" : " · ürün kodu"}
                </div>
              ) : (
                <div className="fatura-eslesme fatura-eslesme-yok">
                  Üretici kataloğunda bulunamadı — taslak kalacak
                </div>
              )}

              <div className="fatura-cipler">
                {satir.beden && <span>{satir.beden}</span>}
                {satir.varyant && <span>{satir.varyant}</span>}
                {satir.adet !== null && <span>{satir.adet} adet</span>}
              </div>

              <div className="fatura-alis">
                Alış: {paraYaz(satir.alisBirimFiyat)}
                {satir.barkod && ` • Barkod: ${satir.barkod}`}
              </div>

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

              <button
                type="button"
                className={satir.onayli ? "fatura-onay fatura-onay-acik" : "fatura-onay"}
                onClick={() => satirGuncelle(index, { onayli: !satir.onayli })}
                disabled={yaziliyor}
              >
                {satir.onayli ? "✓ Onaylandı" : "Onayla"}
              </button>
            </article>
          );
        })}
      </div>

      <div className="fatura-alt-cubuk">
        <span>
          {hazirSayisi} / {satirlar.length} hazır
        </span>
        <button type="button" onClick={vitrineYaz} disabled={hazirSayisi === 0 || yaziliyor}>
          {yaziliyor ? "Kaydediliyor…" : `${hazirSayisi} ürünü kaydet`}
        </button>
      </div>
    </div>
  );
}
