"use client";

import { useState } from "react";
import { xmlAyristir } from "@/lib/xmlUrunAyristir";

interface OwnerXmlYukleProps {
  storeSlug: string;
  kategoriler: Array<{ id: string; name: string }>;
  onKapat: () => void;
  onYukuldu: () => Promise<void>;
}

interface Sonuc {
  basarili: boolean;
  mesaj: string;
}

const AZAMI_URUN = 100;

export function OwnerXmlYukle({ storeSlug, kategoriler, onKapat, onYukuldu }: OwnerXmlYukleProps) {
  const [url, setUrl] = useState("");
  const [yukleniyor, setYukleniyor] = useState(false);
  const [sonuc, setSonuc] = useState<Sonuc | null>(null);

  function kategoriIdBul(ad: string): string {
    const temiz = ad.trim().toLowerCase();
    if (!temiz) return "";
    return kategoriler.find((kategori) => kategori.name.trim().toLowerCase() === temiz)?.id ?? "";
  }

  async function yukle() {
    const temizUrl = url.trim();
    if (!temizUrl) {
      setSonuc({ basarili: false, mesaj: "XML linki girin." });
      return;
    }
    setYukleniyor(true);
    setSonuc(null);
    try {
      const cekCevap = await fetch(
        `/api/xml-urun?slug=${encodeURIComponent(storeSlug)}&url=${encodeURIComponent(temizUrl)}`,
        { cache: "no-store" },
      );
      const cekGovde = await cekCevap.json().catch(() => null);
      if (!cekCevap.ok || typeof cekGovde?.xml !== "string") {
        throw new Error(
          typeof cekGovde?.hata === "string" && cekGovde.hata ? cekGovde.hata : "XML yüklenemedi.",
        );
      }
      const ayrilan = xmlAyristir(cekGovde.xml);
      if (!ayrilan.ok) throw new Error(ayrilan.hata || "XML okunamadı.");
      if (ayrilan.urunler.length === 0) throw new Error("XML dosyasında ürün bulunamadı.");

      const ilkYuz = ayrilan.urunler.slice(0, AZAMI_URUN);
      const partiCevap = await fetch("/api/products/batch", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug: storeSlug,
          products: ilkYuz.map((urun, indeks) => ({
            name: urun.name,
            description: urun.description,
            price_text: urun.priceText,
            category_id: kategoriIdBul(urun.category),
            image_urls: urun.imageUrls,
            source_type: "xml_import",
            sort_order: indeks,
            stockStatus: urun.stockStatus,
            brand: urun.brand ?? undefined,
          })),
        }),
      });
      const partiGovde = await partiCevap.json().catch(() => null);
      if (!partiCevap.ok) {
        throw new Error(
          typeof partiGovde?.hata === "string" && partiGovde.hata ? partiGovde.hata : "Kaydetme hatası.",
        );
      }
      const eklenen = Number(partiGovde?.eklenen) || 0;
      const hatali = Number(partiGovde?.hatali) || 0;
      let mesaj = `${eklenen} ürün eklendi.`;
      if (hatali > 0) mesaj += ` ${hatali} hata.`;
      if (ayrilan.urunler.length > AZAMI_URUN) mesaj += " XML'deki ilk 100 ürün yüklendi.";
      setSonuc({ basarili: true, mesaj });
      if (eklenen > 0) await onYukuldu();
    } catch (xmlHata) {
      setSonuc({
        basarili: false,
        mesaj: xmlHata instanceof Error && xmlHata.message ? xmlHata.message : "İşlem hatası.",
      });
    } finally {
      setYukleniyor(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/70 p-4 sm:items-center" role="presentation">
      <div
        className="owner-card w-full max-w-lg p-5 sm:p-6"
        role="dialog"
        aria-modal="true"
        aria-labelledby="xml-yukle-baslik"
        aria-busy={yukleniyor}
      >
        <h2 id="xml-yukle-baslik" className="text-xl font-bold text-[var(--owner-text)]">
          XML ile Ürün Yükle
        </h2>
        <p className="mt-2 text-sm leading-6 text-[var(--owner-muted)]">
          Tedarikçinizin XML linkini yapıştırın. Sistem otomatik olarak ürünleri vitrine ekleyecek.
        </p>

        <label className="mt-4 block space-y-2">
          <span className="owner-label">XML linki</span>
          <input
            className="owner-input"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="https://tedarikci.com/feed.xml"
            disabled={yukleniyor}
            onKeyDown={(e) => { if (e.key === "Enter") void yukle(); }}
          />
        </label>

        {sonuc ? (
          <p
            className={`mt-3 rounded-xl border p-3 text-sm ${
              sonuc.basarili
                ? "border-[var(--owner-success)]/40 bg-[var(--owner-success)]/10 text-[var(--owner-success)]"
                : "owner-error"
            }`}
            role={sonuc.basarili ? "status" : "alert"}
          >
            {sonuc.mesaj}
          </p>
        ) : null}

        <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button type="button" className="owner-button-secondary" onClick={onKapat} disabled={yukleniyor}>
            İptal
          </button>
          <button type="button" className="owner-button-primary" onClick={() => void yukle()} disabled={yukleniyor}>
            {yukleniyor ? "Yükleniyor…" : "Yükle"}
          </button>
        </div>
      </div>
    </div>
  );
}
