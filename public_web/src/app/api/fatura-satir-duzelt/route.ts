import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { sahipYetkisi } from "@/lib/faturaYetki";
import { eslesmeyenSatir, siteKartiniUygula, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { satirKanitKayitlari } from "@/lib/faturaIslemKaydi";

export const dynamic = "force-dynamic";

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function alan(govde: Record<string, unknown>, ad: string, sinir: number): string | undefined {
  const deger = govde[ad];
  return typeof deger === "string" ? deger.trim().slice(0, sinir) : undefined;
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = alan(govde, "slug", 120) ?? "";
  const islemKimligi = alan(govde, "islemKimligi", 64) ?? "";
  const editToken =
    (request.headers.get("x-vixrex-edit-token") ?? "").trim() || (alan(govde, "editToken", 200) ?? "");
  const satirSirasi = govde.satirSirasi;

  if (!KIMLIK.test(islemKimligi) || typeof satirSirasi !== "number" || !Number.isInteger(satirSirasi) || satirSirasi < 0) {
    return NextResponse.json({ hata: "Satır belirtilmedi." }, { status: 422 });
  }

  const yetki = await sahipYetkisi(slug, editToken);
  if (!yetki.tamam) return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });

  const admin = getSupabaseAdmin();
  const is = await admin.from("invoice_jobs").select("id, status, supplier_name, supplier_site, discovery_state").eq("id", islemKimligi).eq("store_id", yetki.storeId).maybeSingle();
  if (!is.data) return NextResponse.json({ hata: "Fatura işlemi bulunamadı." }, { status: 404 });

  const kayit = await admin.from("invoice_job_lines").select("*").eq("job_id", islemKimligi).eq("line_index", satirSirasi).maybeSingle();
  if (!kayit.data) return NextResponse.json({ hata: "Fatura satırı bulunamadı." }, { status: 404 });

  const duzeltilmis: HamFaturaSatiri = {
    hamSatir: String(kayit.data.raw_text ?? ""),
    model: alan(govde, "model", 120) ?? String(kayit.data.model ?? ""),
    ad: alan(govde, "ad", 200) ?? String(kayit.data.product_name ?? ""),
    barkod: alan(govde, "barkod", 64) ?? String(kayit.data.barcode ?? ""),
    varyant: String(kayit.data.variant_name ?? ""),
    beden: String(kayit.data.size_text ?? ""),
    marka: alan(govde, "marka", 120) ?? String(kayit.data.brand ?? ""),
    adet: kayit.data.qty === null ? null : Number(kayit.data.qty),
    birim: String(kayit.data.qty_unit ?? ""),
    alisBirimFiyat: kayit.data.unit_price === null ? null : Number(kayit.data.unit_price),
    satirToplam: kayit.data.line_total === null ? null : Number(kayit.data.line_total),
    guven: 1,
  };

  const kart = kayit.data.catalog_snapshot && typeof kayit.data.catalog_snapshot === "object" && !Array.isArray(kayit.data.catalog_snapshot)
    ? kayit.data.catalog_snapshot as Record<string, unknown>
    : null;

  const kimlikDegisti =
    duzeltilmis.model !== String(kayit.data.model ?? "") ||
    duzeltilmis.ad !== String(kayit.data.product_name ?? "") ||
    duzeltilmis.barkod !== String(kayit.data.barcode ?? "") ||
    (duzeltilmis.marka ?? "") !== String(kayit.data.brand ?? "");

  const gorseller = Array.isArray(kart?.gorseller)
    ? kart.gorseller.filter((url): url is string => typeof url === "string") : [];

  const siteAd = !kimlikDegisti && typeof kart?.resmiAd === "string" ? kart.resmiAd : "";
  const siteMarka = !kimlikDegisti && typeof kart?.marka === "string" ? kart.marka : "";
  const siteDayanak: "kod" | "barkod" | "ad" | undefined =
    !kimlikDegisti && (kart?.dayanak === "kod" || kart?.dayanak === "barkod" || kart?.dayanak === "ad")
      ? kart.dayanak
      : undefined;
  const siteAciklama = !kimlikDegisti && typeof kart?.aciklama === "string" ? kart.aciklama : "";
  const siteGorsel = !kimlikDegisti ? (gorseller[0] || "") : "";
  const siteGorseller = !kimlikDegisti ? gorseller : [];
  const siteKategori = !kimlikDegisti && typeof kart?.kategori === "string" ? kart.kategori : "";
  const siteSayfa = !kimlikDegisti && typeof kart?.kaynak === "string" ? kart.kaynak : "";
  const siteEslesti = !kimlikDegisti && kayit.data.outcome === "kanitli" && Boolean(siteAd && siteSayfa);

  const yeni = siteKartiniUygula(eslesmeyenSatir({
    ...duzeltilmis,
    siteAd,
    siteMarka,
    siteEslesti,
    siteDayanak,
    siteAciklama,
    siteGorsel,
    siteGorseller,
    siteKategori,
    siteSayfa,
  }));
  if (kimlikDegisti && yeni.sonuc !== "kanitli") {
    yeni.uyari = "Kimlik değişti; ürün kartı yeniden hazırlanmalı.";
  }

  const lineId = String(kayit.data.id);
  const kanit = satirKanitKayitlari(lineId, yeni, "");
  const { data: duzeltme, error: yazmaHatasi } = await admin.rpc("replace_invoice_line", {
    p_store_id: yetki.storeId,
    p_job_id: islemKimligi,
    p_line_id: lineId,
    p_line: {
      model: yeni.model.slice(0, 60),
      product_name: yeni.ad.slice(0, 300),
      barcode: yeni.barkod.replace(/\D/g, "").slice(0, 20),
      brand: (yeni.marka ?? "").slice(0, 120),
      outcome: yeni.sonuc,
      warning: (yeni.uyari ?? "").slice(0, 500),
      catalog_snapshot: yeni.katalog,
      conflict_snapshot: null,
    },
    p_evidence: kanit.kanit,
    p_candidates: kanit.aday,
    p_rights: kanit.gorsel,
    p_discovery: is.data.discovery_state ?? {},
  });

  if (yazmaHatasi || duzeltme?.success !== true) {
    return NextResponse.json({ hata: "Düzeltme kaydedilemedi." }, { status: 500 });
  }

  return NextResponse.json({
    tamam: true,
    satir: yeni,
    onaySifirlandi: duzeltme?.onaySifirlandi === true,
    sahipDurumu: duzeltme?.sahipDurumu ?? null,
  });
}
