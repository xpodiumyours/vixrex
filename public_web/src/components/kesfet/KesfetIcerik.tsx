"use client";

import { useEffect, useMemo, useState } from "react";
import { VitrinKarti } from "./VitrinKarti";
import { KategoriSeridi } from "./KategoriSeridi";
import type { KesfetVitrini } from "@/lib/explore";

const TEMPLATE_GROUPS = ["Tümü", "Perakende", "Hizmet", "Gıda", "Diğer"] as const;
type TemplateGroup = (typeof TEMPLATE_GROUPS)[number];

// Flutter lib/config/business_category_config.dart: templateGroup mapping (19 kategori)
const KATEGORI_GRUP: Record<string, TemplateGroup> = {
  giyim: "Perakende",
  butik: "Perakende",
  gida: "Gıda",
  firin: "Gıda",
  kozmetik: "Perakende",
  dekorasyon: "Perakende",
  elektronik: "Perakende",
  kirtasiye: "Perakende",
  kafe_lokanta: "Gıda",
  kuafor: "Hizmet",
  teknik_servis: "Hizmet",
  hizmet_danismanlik: "Hizmet",
  egitim_ders: "Hizmet",
  ev_temizlik: "Hizmet",
  spor_fitness: "Hizmet",
  pet_shop_veteriner: "Perakende",
  saglik_yasam: "Hizmet",
  oto_arac: "Hizmet",
  diger: "Diğer",
};

function normalizeTR(value: string): string {
  return value
    .toLocaleLowerCase("tr-TR")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c");
}

export function KesfetIcerik({ vitrinler }: { vitrinler: KesfetVitrini[] }) {
  const [sorgu, setSorgu] = useState("");
  const [seciliGrup, setSeciliGrup] = useState<TemplateGroup>("Tümü");
  const [sadeceFavori, setSadeceFavori] = useState(false);
  const [favoriler, setFavoriler] = useState<string[]>([]);
  const [ownSlug, setOwnSlug] = useState<string | null>(null);

  useEffect(() => {
    try {
      const raw = localStorage.getItem("favorite_stores");
      if (raw) setFavoriler(JSON.parse(raw) as string[]);
      const slug = localStorage.getItem("last_published_slug");
      if (slug) setOwnSlug(slug.trim());
    } catch {}
  }, []);

  function toggleFavori(ad: string) {
    setFavoriler((prev) => {
      const varMi = prev.includes(ad);
      const yeni = varMi ? prev.filter((x) => x !== ad) : [...prev, ad];
      try {
        localStorage.setItem("favorite_stores", JSON.stringify(yeni));
      } catch {}
      return yeni;
    });
  }

  const filtreli = useMemo(() => {
    const q = normalizeTR(sorgu.trim());
    const base = vitrinler.filter((v) => {
      if (seciliGrup !== "Tümü") {
        const g = v.kategoriKimligi ? (KATEGORI_GRUP[v.kategoriKimligi] ?? "Diğer") : "Diğer";
        if (g !== seciliGrup) return false;
      }
      if (sadeceFavori && !favoriler.includes(v.ad)) return false;
      if (q) {
        const ad = normalizeTR(v.ad);
        const kat = normalizeTR(v.kategoriEtiketi);
        const konum = normalizeTR(v.konum);
        if (!ad.includes(q) && !kat.includes(q) && !konum.includes(q)) return false;
      }
      return true;
    });
    if (ownSlug) {
      const idx = base.findIndex((v) => v.slug === ownSlug);
      if (idx > 0) {
        const [own] = base.splice(idx, 1);
        base.unshift(own);
      }
    }
    return base;
  }, [vitrinler, sorgu, seciliGrup, sadeceFavori, favoriler, ownSlug]);

  const aramaBos = filtreli.length === 0 && (sorgu.trim().length > 0 || seciliGrup !== "Tümü" || sadeceFavori);
  const listeBos = vitrinler.length === 0;

  return (
    <>
      <div className="mt-8 flex flex-col gap-4">
        <KategoriSeridi />
        <div className="flex gap-2 overflow-x-auto pb-1">
          {TEMPLATE_GROUPS.map((grup) => {
            const secili = seciliGrup === grup;
            return (
              <button
                key={grup}
                type="button"
                onClick={() => setSeciliGrup(grup)}
                className={`whitespace-nowrap rounded-full border px-3.5 py-2 text-[12px] font-black transition-colors ${secili ? "border-lp-primary bg-lp-primary text-lp-on-primary" : "border-lp-border bg-lp-surface text-lp-text-alt hover:bg-lp-surface-soft"}`}
              >
                {grup}
              </button>
            );
          })}
          <button
            type="button"
            onClick={() => setSadeceFavori((v) => !v)}
            className={`flex items-center gap-1.5 whitespace-nowrap rounded-full border px-3.5 py-2 text-[12px] font-black transition-colors ${sadeceFavori ? "border-pink-500 bg-pink-500 text-white" : "border-lp-border bg-lp-surface text-lp-text-alt hover:bg-lp-surface-soft"}`}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill={sadeceFavori ? "currentColor" : "none"} stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="M12 21s-6.5-4.2-8.2-8.2A5.2 5.2 0 0 1 12 5.2a5.2 5.2 0 0 1 8.2 7.6C18.5 16.8 12 21 12 21z"/></svg>
            Favorilerim
          </button>
        </div>
        <div className="relative">
          <span className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-lp-muted">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20L15.5 15.5"/></svg>
          </span>
          <input
            type="search"
            value={sorgu}
            onChange={(e) => setSorgu(e.target.value)}
            placeholder="Vitrin, ürün veya il/ilçe ara"
            aria-label="Vitrin ara"
            className="h-[44px] w-full rounded-2xl border border-lp-border bg-lp-surface py-2.5 pl-10 pr-10 text-[14px] font-semibold text-lp-text placeholder:text-lp-muted focus:border-lp-primary focus:outline-none focus:ring-2 focus:ring-lp-primary/20"
          />
          {sorgu ? (
            <button
              type="button"
              onClick={() => setSorgu("")}
              aria-label="Aramayı temizle"
              className="absolute right-2 top-1/2 -translate-y-1/2 rounded-full p-1.5 text-lp-muted hover:bg-lp-surface-soft hover:text-lp-text"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true"><path d="M18 6L6 18"/><path d="M6 6l12 12"/></svg>
            </button>
          ) : null}
        </div>
      </div>

      {listeBos ? (
        <p className="mt-12 rounded-2xl border border-lp-border bg-lp-surface px-5 py-8 text-center text-[14px] font-semibold text-lp-muted">
          Şu anda yayında vitrin yok.
        </p>
      ) : aramaBos ? (
        <div className="mt-12 rounded-2xl border border-lp-border bg-lp-surface px-5 py-8 text-center">
          <p className="text-[15px] font-black text-lp-text">Aramanızla eşleşen vitrin yok</p>
          <p className="mt-2 text-[13px] font-semibold text-lp-muted">Farklı bir kelime deneyin veya filtreleri temizleyin.</p>
          <button
            type="button"
            onClick={() => { setSorgu(""); setSeciliGrup("Tümü"); setSadeceFavori(false); }}
            className="mt-4 rounded-xl border border-lp-border bg-lp-surface-soft px-4 py-2 text-[12px] font-black text-lp-text-alt hover:bg-lp-surface"
          >
            Filtreleri temizle
          </button>
        </div>
      ) : sadeceFavori && filtreli.length === 0 && favoriler.length === 0 ? (
        <div className="mt-12 rounded-2xl border border-lp-border bg-lp-surface px-5 py-8 text-center">
          <p className="text-[15px] font-black text-lp-text">Favorilere ekli vitrin yok</p>
          <p className="mt-2 text-[13px] font-semibold text-lp-muted">Beğendiğiniz vitrinleri kalp simgesiyle kaydedin.</p>
          <button type="button" onClick={() => setSadeceFavori(false)} className="mt-4 rounded-xl border border-lp-border bg-lp-surface-soft px-4 py-2 text-[12px] font-black text-lp-text-alt hover:bg-lp-surface">Tüm vitrinleri gör</button>
        </div>
      ) : (
        <ul className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {filtreli.map((vitrin) => (
            <li key={vitrin.slug}>
              <VitrinKarti vitrin={vitrin} isFavorited={favoriler.includes(vitrin.ad)} onToggleFavorite={() => toggleFavori(vitrin.ad)} isOwnStore={ownSlug === vitrin.slug} />
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
