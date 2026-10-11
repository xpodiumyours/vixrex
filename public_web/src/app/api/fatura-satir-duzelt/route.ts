import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { sahipYetkisi } from "@/lib/faturaYetki";
import { eslesmeyenSatir, siteKartiniUygula, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { satirKanitKayitlari } from "@/lib/faturaIslemKaydi";
import { ArastirmaHatasi, markaSitesiniBul, satirSitesindeAra } from "@/lib/faturaGoru";
import { ARAMA_UCETI_USD, aramaCagrisiSigarMi, bugunkuMaliyetUsd, kullanimKaydet } from "@/lib/faturaMaliyet";

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

  const { data: limitRows, error: limitHatasi } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_duzelt:${yetki.slug}`,
    p_max_requests: LIMIT,
    p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limitHatasi || !limit || typeof limit.allowed !== "boolean") {
    return NextResponse.json({ hata: "Düzeltme limiti kontrol edilemedi." }, { status: 503 });
  }
  if (!limit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla düzeltme yaptın. ${limit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  const is = await admin
    .from("invoice_jobs")
    .select("id,discovery_state,supplier_name,supplier_site")
    .eq("id", islemKimligi)
    .eq("store_id", yetki.storeId)
    .maybeSingle();
  if (!is.data?.id) return NextResponse.json({ hata: "İşlem bulunamadı." }, { status: 404 });

  const kayit = await admin
    .from("invoice_job_lines")
    .select("id,raw_line,model,product_name,barcode,variant_name,size_text,brand,qty,qty_unit,unit_price,line_total,confidence,product_id,outcome,catalog_snapshot")
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
    birim: String(kayit.data.qty_unit ?? ""),
    alisBirimFiyat: kayit.data.unit_price === null ? null : Number(kayit.data.unit_price),
    satirToplam: kayit.data.line_total === null ? null : Number(kayit.data.line_total),
    guven: Number(kayit.data.confidence ?? 0),
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
  let siteAciklama = !kimlikDegisti && typeof kart?.aciklama === "string" ? kart.aciklama : "";
  let siteGorsel = !kimlikDegisti ? (gorseller[0] || "") : "";
  let siteGorseller = !kimlikDegisti ? gorseller : [];
  let siteSayfa = !kimlikDegisti && typeof kart?.kaynak === "string" ? kart.kaynak : "";
  let siteAd = !kimlikDegisti && typeof kart?.resmiAd === "string" ? kart.resmiAd : "";
  let siteMarka = !kimlikDegisti && typeof kart?.marka === "string" ? kart.marka : "";
  let siteKategori = !kimlikDegisti && typeof kart?.kategori === "string" ? kart.kategori : "";
  let siteOzellikler = !kimlikDegisti && Array.isArray(kart?.ozellikler) ? kart.ozellikler : [];
  let siteUrunVaryantlari = !kimlikDegisti && Array.isArray(kart?.urunVaryantlari) ? kart.urunVaryantlari : [];
  let siteDayanak: "kod" | "barkod" | "ad" | undefined =
    !kimlikDegisti && (kart?.dayanak === "kod" || kart?.dayanak === "barkod" || kart?.dayanak === "ad")
      ? kart.dayanak : undefined;
  let siteEslesti = !kimlikDegisti && kayit.data.outcome === "kanitli" && Boolean(siteAd && siteSayfa);
  let siteUyari = "";
  if (kimlikDegisti) {
    // Re-research ONLY this changed invoice item. Luna alone determines manufacturer/product/photos.
    try {
      let harcama = await bugunkuMaliyetUsd(admin, yetki.storeId);
      if (!aramaCagrisiSigarMi(harcama)) throw new Error("KOTA_DOLDU");
      const tedarikci = String(is.data.supplier_name ?? "");
      const bulunan = await markaSitesiniBul({
        marka: duzeltilmis.marka?.trim() ?? "",
        tedarikci, tedarikciSitesi: String(is.data.supplier_site ?? ""),
        model: duzeltilmis.model, ad: duzeltilmis.ad, barkod: duzeltilmis.barkod, hamSatir: duzeltilmis.hamSatir,
      });
      const aramaMaliyeti = (bulunan.maliyet ?? 0) + ARAMA_UCETI_USD;
      await kullanimKaydet(admin, yetki.storeId, { ...bulunan, maliyet: aramaMaliyeti });
      harcama += aramaMaliyeti;
      if (!bulunan.alan) {
        siteUyari = "Luna bu ürünün resmî üreticisini bulamadı.";
      } else if (!aramaCagrisiSigarMi(harcama)) {
        siteUyari = "Araştırma için günlük maliyet sınırı doldu.";
      } else {
        const arama = await satirSitesindeAra({
          alan: bulunan.alan, model: duzeltilmis.model, ad: duzeltilmis.ad || duzeltilmis.hamSatir || "",
          barkod: duzeltilmis.barkod, marka: duzeltilmis.marka,
          varyant: duzeltilmis.varyant, beden: duzeltilmis.beden,
        });
        const maliyet = (arama.maliyet ?? 0) + ARAMA_UCETI_USD;
        await kullanimKaydet(admin, yetki.storeId, { ...arama, maliyet });
        if (arama.sayfa && arama.ad && arama.dayanak) {
          siteEslesti = true;
          siteAd = arama.ad;
          siteMarka = arama.marka ?? "";
          siteDayanak = arama.dayanak;
          siteAciklama = arama.aciklama;
          siteGorsel = arama.gorsel;
          siteGorseller = arama.gorseller ?? [];
          siteKategori = arama.kategori ?? "";
          siteOzellikler = arama.ozellikler ?? [];
          siteUrunVaryantlari = arama.urunVaryantlari ?? [];
          siteSayfa = arama.sayfa;
        } else {
          siteUyari = "Luna resmî üretici ürününü eşleştiremedi.";
        }
      }
    } catch (err) {
      if (err instanceof ArastirmaHatasi) {
        const maliyet = (err.kullanim.maliyet ?? 0) + ARAMA_UCETI_USD;
        await kullanimKaydet(admin, yetki.storeId, { ...err.kullanim, maliyet }, ARAMA_UCETI_USD);
      }
      const kod = err instanceof Error ? err.message : "";
      siteUyari = kod === "OKUYUCU_BAKIYE_BITTI" || kod === "KOTA_DOLDU"
        ? "Araştırma kotası doldu; satır saklandı."
        : "Kaynak araştırması başarısız; satır saklandı.";
      console.error("[fatura-satir-duzelt] arastirma:", kod || err);
    }
  }
  const yeni = siteKartiniUygula(eslesmeyenSatir({
    ...duzeltilmis, siteAd, siteMarka, siteEslesti, siteDayanak,
    siteAciklama, siteGorsel, siteGorseller,
    siteKategori,
    siteOzellikler: siteOzellikler as Array<{ key: string; label: string; value: string }>,
    siteUrunVaryantlari: siteUrunVaryantlari as Array<{ id: string; secenekler: Array<{ key: string; value: string }>; barkod: string; gorseller: string[] }>,
    siteSayfa,
  }));
  if (siteUyari && yeni.sonuc !== "kanitli") yeni.uyari = siteUyari;

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
