"use client";

import Image from "next/image";
import { useCallback, useEffect, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { buildWhatsappOrderUrl } from "@/lib/vitrinCart";
import {
  getProductImages,
  getProductUrlSlug,
  isLunaInvoiceProduct,
  isLikelyUiScreenshotUrl,
  resolveCatalogImage,
} from "@/lib/products";
import {
  birimFiyatBilgisi,
  buildProductCardFacts,
  eskiFiyatYazisi,
  indirimOrani,
  kartRozeti,
  productVariantLabel,
  tutarYazisi,
} from "@/lib/productCardPresentation";
import { normalizeProductMetadata } from "@/lib/productRichData";
import type { RichProductItem } from "@/lib/richProductItem";

export interface PrototipKart {
  anahtar: string;
  ad: string;
  marka: string;
  rozet: string | null;
  fiyat: string;
  fiyatTutar: number | null;
  eskiFiyat: string | null;
  indirimYuzdesi: number | null;
  miktar: string | null;
  birimFiyat: string | null;
  ozellikler: string;
  aciklama: string;
  stokMetni: string;
  stokTuru: "iyi" | "az" | "tukendi" | null;
  maksAdet: number | null;
  varyantEtiketi: string | null;
  gorsel: string | null;
  gorseller: string[];
  fotoSayisi: number;
  urunUrl: string;
  urunSlug: string;
  hizmetMi: boolean;
}

export { tutarYazisi };

function gorselBul(product: RichProductItem): string | null {
  const resolved = resolveCatalogImage(product, null);
  return resolved === "/images/vixrex_v_crystal_mascot.webp" ? null : resolved;
}

function stokTonu(stokMetni: string): "iyi" | "az" | "tukendi" | null {
  const value = stokMetni.toLocaleLowerCase("tr-TR");
  if (!value) return null;
  if (value.includes("tükendi")) return "tukendi";
  if (value.includes("son") || value.includes("az") || value.includes("sınırl")) return "az";
  return "iyi";
}

export function prototipKartlari(products: RichProductItem[], storeSlug: string): PrototipKart[] {
  return products.map((product, index) => {
    const metadata = normalizeProductMetadata(product.metadata);
    const hizmetMi = metadata.itemKind === "service";
    const marka = hizmetMi ? "" : String(product.brand || "").trim();
    const stokMetni = hizmetMi
      ? ""
      : product.stockQuantity === 0
        ? "Tükendi"
        : String(product.stockStatus || "").trim();
    const gorsel = gorselBul(product);
    const gorseller = gorsel
      ? Array.from(
          new Set([
            gorsel,
            ...getProductImages(product).filter(
              (url) => isLunaInvoiceProduct(product) || !isLikelyUiScreenshotUrl(url),
            ),
          ]),
        )
      : [];
    const urunSlug = getProductUrlSlug(product, index);
    const facts = buildProductCardFacts({
      brand: product.brand,
      metadata: product.metadata,
      variants: hizmetMi ? undefined : product.variants,
    });
    const fiyatTutar =
      typeof product.priceAmount === "number" && Number.isFinite(product.priceAmount) && product.priceAmount > 0
        ? product.priceAmount
        : null;
    const miktarBilgisi = hizmetMi ? null : birimFiyatBilgisi(product.metadata, fiyatTutar);
    return {
      anahtar: product.id || urunSlug || String(index),
      ad: String(product.name || "").trim() || "İsimsiz ürün",
      marka,
      rozet: kartRozeti({
        badgeTag: product.badgeTag,
        priceAmount: product.priceAmount,
        oldPriceAmount: product.oldPriceAmount,
      }),
      fiyat: product.price || "Fiyat sorun",
      fiyatTutar,
      eskiFiyat: eskiFiyatYazisi(product.oldPriceAmount),
      indirimYuzdesi: indirimOrani({
        priceAmount: product.priceAmount,
        oldPriceAmount: product.oldPriceAmount,
      }),
      miktar: miktarBilgisi?.miktar ?? null,
      birimFiyat: miktarBilgisi?.birimFiyat ?? null,
      ozellikler: facts.ozellikler.map((ozellik) => ozellik.value).join(" · "),
      aciklama: String(product.description || "").trim(),
      stokMetni,
      stokTuru: stokTonu(stokMetni),
      maksAdet:
        typeof product.stockQuantity === "number" && product.stockQuantity > 0
          ? Math.min(999, Math.round(product.stockQuantity))
          : null,
      varyantEtiketi: hizmetMi ? null : productVariantLabel(product.variants, metadata.templateKey),
      gorsel,
      gorseller,
      fotoSayisi: gorseller.length,
      urunUrl: `/v/${storeSlug}/urun/${urunSlug}`,
      urunSlug,
      hizmetMi,
    };
  });
}

export function whatsappSiparisUrl(
  baseUrl: string | null,
  storeName: string,
  kart: PrototipKart,
  adet: number,
): string | null {
  return buildWhatsappOrderUrl(baseUrl, storeName, [
    {
      productSlug: kart.urunSlug,
      productName: kart.ad,
      variantKey: kart.varyantEtiketi || "",
      variantText: kart.varyantEtiketi || "",
      priceText: kart.fiyat,
      priceAmount: kart.fiyatTutar,
      imageUrl: kart.gorsel,
      maxQuantity: null,
      quantity: Math.max(1, adet),
    },
  ]);
}

export function stokRengi(tur: PrototipKart["stokTuru"]): { nokta: string; metin: string } | null {
  if (!tur) return null;
  if (tur === "tukendi") {
    return { nokta: "bg-red-500", metin: "text-red-300" };
  }
  if (tur === "az") {
    return { nokta: "bg-amber-500", metin: "text-amber-300" };
  }
  return { nokta: "bg-emerald-500", metin: "text-emerald-300" };
}

export function PrototipGorsel({
  src,
  alt,
  className = "object-cover object-center",
}: {
  src: string | null;
  alt: string;
  className?: string;
}) {
  const [hata, setHata] = useState(false);

  if (!src || hata) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900 px-3 text-center">
        <span className="text-[10px] font-extrabold text-slate-500">Ürün görseli yok</span>
      </div>
    );
  }

  return (
    <Image
      src={src}
      alt={alt}
      fill
      sizes="(max-width: 768px) 50vw, 25vw"
      onError={() => setHata(true)}
      className={className}
    />
  );
}

export const PROTIP_VARYANTLAR = [
  { key: "A", ad: "A — Market kartı" },
  { key: "B", ad: "B — Yoğun liste" },
  { key: "C", ad: "C — Görsel vitrin" },
] as const;

export function PrototipAnahtar({ aktif }: { aktif: string }) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  const gec = useCallback(
    (yon: number) => {
      const keys = PROTIP_VARYANTLAR.map((v) => v.key as string);
      const i = Math.max(0, keys.indexOf(aktif));
      const next = keys[(i + yon + keys.length) % keys.length];
      const params = new URLSearchParams(searchParams.toString());
      params.set("variant", next);
      router.replace(`${pathname}?${params.toString()}`, { scroll: false });
    },
    [aktif, pathname, router, searchParams],
  );

  useEffect(() => {
    const dinle = (event: KeyboardEvent) => {
      const el = event.target as HTMLElement | null;
      if (el && (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.isContentEditable)) return;
      if (event.key === "ArrowLeft") gec(-1);
      if (event.key === "ArrowRight") gec(1);
    };
    window.addEventListener("keydown", dinle);
    return () => window.removeEventListener("keydown", dinle);
  }, [gec]);

  if (process.env.NODE_ENV === "production") return null;

  const ad = PROTIP_VARYANTLAR.find((v) => v.key === aktif)?.ad ?? aktif;

  return (
    <div
      data-prototip="varyant-anahtar"
      className="fixed bottom-4 left-1/2 z-[90] flex -translate-x-1/2 items-center gap-1 rounded-full border border-white/15 bg-[#0B1730]/95 p-1.5 shadow-2xl backdrop-blur-xl"
    >
      <button
        type="button"
        onClick={() => gec(-1)}
        aria-label="Önceki varyant"
        className="flex h-9 w-9 items-center justify-center rounded-full text-white/80 transition hover:bg-white/10"
      >
        ←
      </button>
      <span className="min-w-[9.5rem] text-center text-[11px] font-extrabold tracking-wide text-white">
        {ad}
      </span>
      <button
        type="button"
        onClick={() => gec(1)}
        aria-label="Sonraki varyant"
        className="flex h-9 w-9 items-center justify-center rounded-full text-white/80 transition hover:bg-white/10"
      >
        →
      </button>
    </div>
  );
}
