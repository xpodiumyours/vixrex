"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState, type MouseEvent } from "react";
import {
  BUSINESS_CATEGORIES,
  kategoriUrlParcasi,
  type BusinessTemplateGroup,
} from "@/lib/businessCategories";
import type { KesfetVitrini } from "@/lib/explore";
import { kesfetVitrinleriniFiltrele } from "@/lib/kesfetFiltreleme";
import { supabase } from "@/lib/supabase";
import { VitrinKarti, type PremiumBilgisi } from "./VitrinKarti";
import { StatusBar } from "./StatusBar";
import { MascotFab } from "@/components/landing/MascotFab";

const FAVORI_ANAHTARI = "favorite_stores";
const KATEGORI_GRUPLARI = new Map(
  BUSINESS_CATEGORIES.map((kategori) => [kategori.id, kategori.templateGroup])
);
const GRUPLAR: Array<{
  deger: BusinessTemplateGroup;
  etiket: string;
}> = [
  { deger: "perakende", etiket: "Perakende" },
  { deger: "hizmet", etiket: "Hizmet" },
  { deger: "gida", etiket: "Gıda" },
  { deger: "diger", etiket: "Diğer" },
];

type PanoOzeti = {
  slug?: string;
  premiumAktif?: boolean;
  premiumBitis?: string | null;
};

export function KesfetIcerik({
  vitrinler,
  ilkSahipSlug = null,
  sadeceKiralik = false,
  ilkKategoriKimligi = null,
  baslik,
  aciklama,
}: {
  vitrinler: KesfetVitrini[];
  ilkSahipSlug?: string | null;
  sadeceKiralik?: boolean;
  ilkKategoriKimligi?: string | null;
  baslik: string;
  aciklama: string;
}) {
  const router = useRouter();
  const [sorgu, setSorgu] = useState("");
  const [grup, setGrup] = useState<BusinessTemplateGroup | undefined>(undefined);
  const [kategoriKimligi, setKategoriKimligi] = useState<string | null>(ilkKategoriKimligi);
  const [sadeceFavoriler, setSadeceFavoriler] = useState(false);
  const [favoriAdlari, setFavoriAdlari] = useState<string[]>([]);
  const [sahipSlug, setSahipSlug] = useState<string | null>(ilkSahipSlug);
  const [premium, setPremium] = useState<PremiumBilgisi | null>(null);

  useEffect(() => {
    const vixrexIstenmis = new URLSearchParams(window.location.search).get("vixrex") === "1";
    if (vixrexIstenmis) router.replace("/app/vixrex");
  }, [router]);

  useEffect(() => {
    let iptal = false;
    async function tarayiciDurumunuGetir() {
      await Promise.resolve();
      let kayitliFavoriler: string[] = [];
      try {
        const kayitli = localStorage.getItem(FAVORI_ANAHTARI);
        if (kayitli) {
          const cozulmus = JSON.parse(kayitli);
          if (Array.isArray(cozulmus)) {
            kayitliFavoriler = cozulmus.filter(
              (ad): ad is string => typeof ad === "string"
            );
          }
        }
      } catch {
        kayitliFavoriler = [];
      }
      if (!iptal) setFavoriAdlari(kayitliFavoriler);

      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (!session || session.user.is_anonymous || iptal) return;

      const yanit = await fetch("/api/owner-dashboard/summary", {
        headers: { authorization: `Bearer ${session.access_token}` },
      });
      if (!yanit.ok || iptal) return;

      const ozet = (await yanit.json()) as PanoOzeti;
      if (ozet.slug) setSahipSlug(ozet.slug);
      setPremium({
        aktif: ozet.premiumAktif === true,
        bitis: ozet.premiumBitis ?? null,
      });
    }
    void tarayiciDurumunuGetir();
    return () => {
      iptal = true;
    };
  }, []);

  const kategoriler = useMemo(
    () =>
      grup
        ? BUSINESS_CATEGORIES.filter((kategori) => kategori.templateGroup === grup)
        : BUSINESS_CATEGORIES,
    [grup]
  );

  const filtreliVitrinler = useMemo(() => {
    const sonuc = kesfetVitrinleriniFiltrele(
      vitrinler,
      {
        sorgu,
        grup,
        kategoriKimligi,
        sadeceFavoriler,
        favoriAdlari,
        sadeceKiralik,
      },
      KATEGORI_GRUPLARI
    );
    const sahipIndex = sahipSlug
      ? sonuc.findIndex((vitrin) => vitrin.slug === sahipSlug)
      : -1;
    if (sahipIndex <= 0) return sonuc;
    return [sonuc[sahipIndex], ...sonuc.slice(0, sahipIndex), ...sonuc.slice(sahipIndex + 1)];
  }, [vitrinler, sorgu, grup, kategoriKimligi, sadeceFavoriler, favoriAdlari, sadeceKiralik, sahipSlug]);

  function grubuSec(yeniGrup: BusinessTemplateGroup | undefined) {
    setGrup(yeniGrup);
    setKategoriKimligi(null);
  }

  function favoriyiDegistir(ad: string) {
    setFavoriAdlari((onceki) => {
      const sonraki = onceki.includes(ad)
        ? onceki.filter((kayitliAd) => kayitliAd !== ad)
        : [...onceki, ad];
      try {
        localStorage.setItem(FAVORI_ANAHTARI, JSON.stringify(sonraki));
      } catch {
        // Tarayıcı depolaması kapalıysa ekran durumu yine çalışmaya devam eder.
      }
      return sonraki;
    });
  }

  function filtreleriTemizle() {
    setSorgu("");
    setGrup(undefined);
    setKategoriKimligi(null);
    setSadeceFavoriler(false);
  }

  function kategoriBaglantisiniFiltreyeCevir(
    event: MouseEvent<HTMLAnchorElement>,
    kimlik: string | null
  ) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    event.preventDefault();
    setKategoriKimligi(kimlik);
  }

  const filtreVar = Boolean(
    sorgu.trim() || grup !== undefined || kategoriKimligi || sadeceFavoriler
  );

  return (
    <main className="min-h-full min-w-0 bg-lp-bg-editor text-lp-text">
      <MascotFab mesajGoster={false} onToggle={() => router.push("/app/vixrex")} />
      <StatusBar sahipSlug={sahipSlug} premium={premium} />

      <header className="flex h-14 items-center px-4">
        <h1 id="kesfet-baslik" className="text-[20px] font-black leading-tight text-lp-text">
          {baslik}
        </h1>
      </header>

      <section className="pb-[80px] min-[901px]:pb-0" aria-labelledby="kesfet-baslik">
        <p className="px-6 pb-3 text-[12px] font-semibold leading-[1.5] text-lp-muted">
          {aciklama}
        </p>

        <div className="px-6 pb-3">
          <label htmlFor="kesfet-arama" className="sr-only">
            Vitrin, ürün veya il/ilçe ara
          </label>
          <div className="relative">
            <span
              aria-hidden="true"
              className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-lp-muted"
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="11" cy="11" r="7" />
                <path d="m20 20-4.5-4.5" />
              </svg>
            </span>
            <input
              id="kesfet-arama"
              type="search"
              value={sorgu}
              onChange={(event) => setSorgu(event.target.value)}
              placeholder="Vitrin, ürün veya il/ilçe ara"
              className="h-12 w-full rounded-2xl border border-lp-border bg-lp-surface py-3 pl-11 pr-12 text-[14px] font-semibold text-lp-text placeholder:text-lp-muted focus:border-lp-primary focus:outline-none focus:ring-2 focus:ring-lp-primary/30"
            />
            {sorgu ? (
              <button
                type="button"
                onClick={() => setSorgu("")}
                aria-label="Aramayı temizle"
                className="absolute right-1 top-1/2 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-full text-lp-muted transition-colors hover:bg-lp-surface-soft hover:text-lp-text focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" aria-hidden="true">
                  <path d="M18 6 6 18M6 6l12 12" />
                </svg>
              </button>
            ) : null}
          </div>
        </div>

        <div className="flex h-[52px] gap-2 overflow-x-auto px-5 py-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" aria-label="Vitrin grupları">
          <button
            type="button"
            aria-pressed={grup === undefined}
            onClick={() => grubuSec(undefined)}
            className={`my-auto min-h-8 shrink-0 rounded-full border px-4 text-[12px] font-black transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              grup === undefined
                ? "border-lp-primary bg-lp-primary text-lp-on-primary"
                : "border-lp-border bg-lp-surface text-lp-text-alt hover:bg-lp-surface-soft"
            }`}
          >
            Tümü
          </button>
          {GRUPLAR.map((secenek) => (
            <button
              key={secenek.deger}
              type="button"
              aria-pressed={grup === secenek.deger}
              onClick={() => grubuSec(secenek.deger)}
              className={`my-auto min-h-8 shrink-0 rounded-full border px-4 text-[12px] font-black transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
                grup === secenek.deger
                  ? "border-lp-primary bg-lp-primary text-lp-on-primary"
                  : "border-lp-border bg-lp-surface text-lp-text-alt hover:bg-lp-surface-soft"
              }`}
            >
              {secenek.etiket}
            </button>
          ))}
        </div>

        <nav className="flex h-[52px] gap-2 overflow-x-auto px-5 py-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden" aria-label="Vitrin kategorileri">
          <button
            type="button"
            aria-pressed={sadeceFavoriler}
            onClick={() => setSadeceFavoriler((deger) => !deger)}
            className={`my-auto flex min-h-8 shrink-0 items-center gap-2 rounded-full border px-4 text-[12px] font-black transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
              sadeceFavoriler
                ? "border-lp-primary bg-lp-primary text-lp-on-primary"
                : "border-lp-border bg-lp-surface text-lp-text-alt hover:bg-lp-surface-soft"
            }`}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill={sadeceFavoriler ? "currentColor" : "none"} stroke="currentColor" strokeWidth="2" aria-hidden="true">
              <path d="M12 21s-6.5-4.2-8.2-8.2A5.2 5.2 0 0 1 12 5.2a5.2 5.2 0 0 1 8.2 7.6C18.5 16.8 12 21 12 21z" />
            </svg>
            Favorilerim
          </button>
          {kategoriler.map((kategori) => (
            <Link
              key={kategori.id}
              href={`/kesfet/${kategoriUrlParcasi(kategori.id)}`}
              onClick={(event) => kategoriBaglantisiniFiltreyeCevir(event, kategori.id)}
              aria-current={kategoriKimligi === kategori.id ? "page" : undefined}
              className={`my-auto flex min-h-8 shrink-0 items-center rounded-full border px-4 text-[12px] font-black transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary ${
                kategoriKimligi === kategori.id
                  ? "border-lp-primary bg-lp-primary text-lp-on-primary"
                  : "border-lp-border bg-lp-surface text-lp-text-alt hover:bg-lp-surface-soft"
              }`}
            >
              {kategori.label}
            </Link>
          ))}
        </nav>

        {filtreliVitrinler.length === 0 ? (
          <div className="m-3 rounded-2xl border border-lp-border bg-lp-surface px-5 py-8 text-center">
            <svg className="mx-auto text-lp-primary" width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" aria-hidden="true">
              <path d="M3 10.5 12 4l9 6.5V20H3z" />
              <path d="M8 20v-6h8v6" />
            </svg>
            <p className="mt-3 text-[15px] font-black text-lp-text">
              {sadeceFavoriler ? "Favorilere ekli vitrin yok" : "Aramanızla eşleşen vitrin yok"}
            </p>
            <p className="mt-2 text-[13px] font-semibold text-lp-muted">
              {sadeceFavoriler
                ? "Beğendiğiniz vitrinleri kalp simgesiyle kaydedin."
                : "Farklı bir kelime deneyin veya filtreleri temizleyin."}
            </p>
            <button
              type="button"
              onClick={sadeceFavoriler ? () => setSadeceFavoriler(false) : filtreleriTemizle}
              className="mt-4 min-h-11 rounded-xl border border-lp-border bg-lp-surface-soft px-4 text-[12px] font-black text-lp-text-alt hover:bg-lp-surface focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary"
            >
              {sadeceFavoriler ? "Tüm vitrinleri gör" : "Filtreleri temizle"}
            </button>
          </div>
        ) : (
          <ul
            className="grid grid-cols-2 gap-3 p-3 min-[700px]:grid-cols-3 min-[1000px]:grid-cols-4"
            aria-label="Vitrinler"
          >
            {filtreliVitrinler.map((vitrin, index) => (
              <li
                key={vitrin.slug}
                className="h-[280px] animate-fade-in motion-reduce:animate-none [&>article]:min-h-[280px] min-[700px]:h-[305px] min-[700px]:[&>article]:min-h-[305px] min-[1000px]:h-[320px] min-[1000px]:[&>article]:min-h-[320px]"
                style={{ animationDelay: `${Math.min(index, 6) * 30}ms` }}
              >
                <VitrinKarti
                  vitrin={vitrin}
                  favoriMi={favoriAdlari.includes(vitrin.ad)}
                  favoriyiDegistir={() => favoriyiDegistir(vitrin.ad)}
                  sahipMi={sahipSlug === vitrin.slug}
                  premium={sahipSlug === vitrin.slug ? premium : null}
                />
              </li>
            ))}
          </ul>
        )}

        {sadeceKiralik ? (
          <div className="px-6 pb-3 pt-2">
            <Link
              href="/"
              className="flex min-h-11 w-full items-center justify-center rounded-xl border border-lp-border bg-lp-surface px-5 text-[13px] font-black text-lp-text-alt hover:bg-lp-surface-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-lp-primary"
            >
              Uygun olan yok, sıfırdan oluştur
            </Link>
          </div>
        ) : null}

        {!filtreVar && vitrinler.length > 0 ? (
          <p className="sr-only" aria-live="polite">{vitrinler.length} vitrin gösteriliyor.</p>
        ) : null}
      </section>
    </main>
  );
}
