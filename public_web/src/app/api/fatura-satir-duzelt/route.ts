import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { sahipYetkisi } from "@/lib/faturaYetki";
import { eslesmeyenSatir, siteKartiniUygula, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { satirKanitKayitlari } from "@/lib/faturaIslemKaydi";

export const dynamic = "force-dynamic";

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const LIMIT = 60;
const PENCERE_SANIYE = 3600;

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

  const { data: limitRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_duzelt:${yetki.slug}`,
    p_max_requests: LIMIT,
    p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limit && !limit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla düzeltme yaptın. ${limit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  const is = await admin
    .from("invoice_jobs")
    .select("id,discovery_state")
    .eq("id", islemKimligi)
    .eq("store_id", yetki.storeId)
    .maybeSingle();
  if (!is.data?.id) return NextResponse.json({ hata: "İşlem bulunamadı." }, { status: 404 });

  const kayit = await admin
    .from("invoice_job_lines")
    .select("id,raw_line,model,product_name,barcode,variant_name,size_text,brand,qty,unit_price,line_total,confidence,product_id,catalog_snapshot")
    .eq("job_id", islemKimligi)
    .eq("line_index", satirSirasi)
    .maybeSingle();
  if (!kayit.data?.id) return NextResponse.json({ hata: "Satır bulunamadı." }, { status: 404 });

  const duzeltilmis: HamFaturaSatiri = {
    hamSatir: String(kayit.data.raw_line ?? ""),
    model: alan(govde, "model", 60) ?? String(kayit.data.model ?? ""),
    ad: alan(govde, "ad", 300) ?? String(kayit.data.product_name ?? ""),
    barkod: (alan(govde, "barkod", 20) ?? String(kayit.data.barcode ?? "")).replace(/\D/g, ""),
    varyant: String(kayit.data.variant_name ?? ""),
    beden: String(kayit.data.size_text ?? ""),
    marka: alan(govde, "marka", 120) ?? String(kayit.data.brand ?? ""),
    adet: kayit.data.qty === null ? null : Number(kayit.data.qty),
    alisBirimFiyat: kayit.data.unit_price === null ? null : Number(kayit.data.unit_price),
    satirToplam: kayit.data.line_total === null ? null : Number(kayit.data.line_total),
    guven: Number(kayit.data.confidence ?? 0),
  };

  const kart = kayit.data.catalog_snapshot && typeof kayit.data.catalog_snapshot === "object" && !Array.isArray(kayit.data.catalog_snapshot)
    ? kayit.data.catalog_snapshot as Record<string, unknown>
    : null;
  const gorseller = Array.isArray(kart?.gorseller) ? kart.gorseller : [];
  const siteAciklama = typeof kart?.aciklama === "string" ? kart.aciklama.trim() : "";
  const siteGorsel = typeof gorseller[0] === "string" ? gorseller[0].trim() : "";
  const siteSayfa = typeof kart?.kaynak === "string" ? kart.kaynak.trim() : "";
  const yeni = siteKartiniUygula(eslesmeyenSatir({
    ...duzeltilmis,
    siteAciklama,
    siteGorsel,
    siteSayfa,
    sayfaDogrulandi: Boolean(siteAciklama && siteGorsel.startsWith("https://") && siteSayfa.startsWith("https://")),
  }));

  const lineId = String(kayit.data.id);
  const kayitlar = satirKanitKayitlari(lineId, yeni, "");
  const { data: duzeltme, error: satirHatasi } = await admin.rpc("replace_invoice_line", {
    p_store_id: yetki.storeId,
    p_job_id: islemKimligi,
    p_line_id: lineId,
    p_line: {
      model: duzeltilmis.model.slice(0, 60),
      product_name: duzeltilmis.ad.slice(0, 300),
      barcode: duzeltilmis.barkod.slice(0, 20),
      brand: (duzeltilmis.marka ?? "").slice(0, 120),
      outcome: yeni.sonuc,
      warning: (yeni.uyari ?? "").slice(0, 500),
      catalog_snapshot: yeni.katalog,
      conflict_snapshot: null,
    },
    p_evidence: kayitlar.kanit,
    p_candidates: kayitlar.aday,
    p_rights: kayitlar.gorsel,
    p_discovery: is.data.discovery_state ?? {},
  });
  if (satirHatasi || duzeltme?.success !== true) return NextResponse.json({ hata: "Düzeltme kaydedilemedi. Tekrar dene." }, { status: 500 });

  return NextResponse.json({
    tamam: true,
    satirSirasi,
    satir: yeni,
    sahipDurumu: duzeltme.sahipDurumu ?? null,
    onaySifirlandi: duzeltme.onaySifirlandi === true,
    urunId: kayit.data.product_id ? String(kayit.data.product_id) : null,
  });
}
