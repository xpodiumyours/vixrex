import { createHash } from "node:crypto";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import type { TedarikciDijitalIzi } from "@/lib/faturaDijitalIz";
import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";

export interface BelgeKimligi {
  belgeNo?: string | null;
  tarih?: string | null;
}

/**
 * Belgenin parmak izi: dosya-hash + belgeNo/tarih birleşimi.
 * İkisi de yoksa dosya hash'ine düşer — aynı fotoğraf yeniden yüklenince
 * aynı iş açılır, ikinci kayıt oluşmaz. Geriye uyumlu: tek argümanla
 * çağrılınca eski dosya-hash davranışı korunur.
 */
export function belgeParmakIzi(bayt: Uint8Array, kimlik?: BelgeKimligi): string {
  const dosyaHash = createHash("sha256").update(bayt).digest("hex");
  const no = kimlik?.belgeNo?.trim() ?? "";
  const tarih = kimlik?.tarih?.trim() ?? "";
  if (!no && !tarih) return dosyaHash;
  return createHash("sha256").update(`${dosyaHash}|${no}|${tarih}`).digest("hex");
}

export interface IslemKaydiGirdisi {
  slug: string;
  parmakIzi: string;
  belgeAdedi: number | null;
  belgeToplami: number | null;
  tedarikci: string;
  tedarikciVergiNo: string;
  tedarikciAdres: string;
  tedarikciSite: string;
  tedarikciIz: TedarikciDijitalIzi | null;
  satirlar: EslesmisFaturaSatiri[];
  /** Belge üstü kimlik — migration yok; supplier_trace içine gömülür. */
  belgeTuru?: string | null;
  belgeNo?: string | null;
  belgeTarihi?: string | null;
  kdvToplam?: number | null;
}

// Kilitli kapsam: üretici görseli karta girer ve yayınlanır; kullanım izni
// sonra, çalışan sistemle istenir. Bu yüzden izni olmayan görsel `denied`
// değil `unknown` (izin turu bekliyor) olarak kaydedilir; izin turu bu
// listeden yürür. `denied`, firmanın açıkça reddettiği durum için saklıdır.
function gorselIzinDurumu(izin: "yok" | "bekliyor" | "var"): string {
  if (izin === "var") return "verified_supplier_permission";
  return "unknown";
}

function kanitGucu(satir: EslesmisFaturaSatiri): "strong" | "partial" | "weak" {
  if (satir.katalog) return "strong";
  return satir.guven >= 0.6 ? "partial" : "weak";
}

/**
 * Aynı alışverişin farklı fotoğrafı mı? Belge no + tarih + tedarikçi aynıysa
 * aynı iştir — örn. bilgi fişi + e-Arşiv faturası 8 adedi 16 yapmaz.
 * supplier_trace içine gömülü belgeNo/tarih üzerinden son işlere bakılır.
 */
export async function ayniAlisIsiniBul(args: {
  storeId: string;
  tedarikci: string;
  belgeNo: string | null | undefined;
  belgeTarihi: string | null | undefined;
}): Promise<{ id: string; parmakIzi: string } | null> {
  const no = (args.belgeNo ?? "").trim();
  if (!no) return null;
  try {
    const admin = getSupabaseAdmin();
    const { data } = await admin
      .from("invoice_jobs")
      .select("id,document_fingerprint,supplier_name,supplier_trace")
      .eq("store_id", args.storeId)
      .order("updated_at", { ascending: false })
      .limit(20);
    if (!Array.isArray(data)) return null;
    const tarih = (args.belgeTarihi ?? "").trim();
    for (const satir of data as Array<{
      id: string;
      document_fingerprint: string;
      supplier_name?: string;
      supplier_trace?: Record<string, unknown> | null;
    }>) {
      const iz = (satir.supplier_trace ?? {}) as Record<string, unknown>;
      const kayitNo = String(iz.belgeNo ?? "").trim();
      if (!kayitNo || kayitNo !== no) continue;
      const kayitTarih = String(iz.belgeTarihi ?? "").trim();
      // Tarih iki belgede de yazıyorsa tutmalı; biri boşsa no + tedarikçi yeter.
      if (tarih && kayitTarih && kayitTarih !== tarih) continue;
      return { id: String(satir.id), parmakIzi: String(satir.document_fingerprint) };
    }
    return null;
  } catch {
    return null;
  }
}

export async function islemKaydet(girdi: IslemKaydiGirdisi): Promise<string | null> {
  try {
    const admin = getSupabaseAdmin();

    const magaza = await admin
      .from("stores")
      .select("id")
      .eq("slug", girdi.slug)
      .maybeSingle();
    const storeId = magaza.data?.id;
    if (typeof storeId !== "string" || !storeId) return null;

    // Aynı alışverişin ikinci belgesi aynı işe bağlanır: çift kart/stok çıkmaz.
    const mevcut = await ayniAlisIsiniBul({
      storeId,
      tedarikci: girdi.tedarikci,
      belgeNo: girdi.belgeNo,
      belgeTarihi: girdi.belgeTarihi,
    });
    const parmakIzi = mevcut ? mevcut.parmakIzi : girdi.parmakIzi;

    const beklemeVar = girdi.satirlar.some((satir) => satir.sonuc !== "kanitli");
    // Migration yok: invoice_jobs'ta belge_no/tur/tarih kolonu açılmaz.
    // Belge kimliği mevcut kolonlara gömülür — adet/total zaten
    // document_adet/document_total'da, no/tur/tarih/KDV supplier_trace JSON'undadır.
    const izTabani = girdi.tedarikciIz
      ? {
          anahtar: girdi.tedarikciIz.anahtar,
          alan: girdi.tedarikciIz.alan,
          platform: girdi.tedarikciIz.platform,
          izinDurumu: girdi.tedarikciIz.izinDurumu,
          kaynak: girdi.tedarikciIz.kaynak,
          havuzda: girdi.tedarikciIz.havuzda,
        }
      : null;
    const belgeMeta: Record<string, string | number | null> = {};
    if (girdi.belgeTuru) belgeMeta.belgeTuru = girdi.belgeTuru.slice(0, 40);
    if (girdi.belgeNo) belgeMeta.belgeNo = girdi.belgeNo.slice(0, 80);
    if (girdi.belgeTarihi) belgeMeta.belgeTarihi = girdi.belgeTarihi.slice(0, 40);
    if (typeof girdi.kdvToplam === "number" && Number.isFinite(girdi.kdvToplam)) {
      belgeMeta.kdvToplam = girdi.kdvToplam;
    }
    const tedarikciIzKaydi =
      izTabani || Object.keys(belgeMeta).length > 0 ? { ...izTabani, ...belgeMeta } : null;
    const isKaydi = await admin
      .from("invoice_jobs")
      .upsert(
        {
          store_id: storeId,
          document_fingerprint: parmakIzi,
          status: beklemeVar ? "inceleme" : "eslestirme",
          supplier_name: girdi.tedarikci.slice(0, 200),
          supplier_tax_id: girdi.tedarikciVergiNo.slice(0, 40),
          supplier_address: girdi.tedarikciAdres.slice(0, 500),
          supplier_site: girdi.tedarikciSite.slice(0, 200),
          supplier_trace: tedarikciIzKaydi,
          document_adet: girdi.belgeAdedi,
          document_total: girdi.belgeToplami,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "store_id,document_fingerprint" },
      )
      .select("id")
      .single();

    const jobId = isKaydi.data?.id;
    if (typeof jobId !== "string" || !jobId) return null;

    await admin.from("invoice_job_lines").delete().eq("job_id", jobId);

    const satirYazlari = girdi.satirlar.map((satir, sira) => ({
      job_id: jobId,
      line_index: sira,
      raw_line: (satir.hamSatir ?? "").slice(0, 1000),
      model: satir.model.slice(0, 60),
      product_name: satir.ad.slice(0, 300),
      barcode: satir.barkod.replace(/\D/g, "").slice(0, 20),
      variant_name: satir.varyant.slice(0, 80),
      size_text: satir.beden.slice(0, 60),
      qty: satir.adet,
      unit_price: satir.alisBirimFiyat,
      line_total: satir.satirToplam,
      confidence: satir.guven,
      outcome: satir.sonuc,
    }));

    const satirKayitlari = satirYazlari.length
      ? await admin.from("invoice_job_lines").insert(satirYazlari).select("id")
      : { data: [] as Array<{ id: string }> };
    const satirIdleri = Array.isArray(satirKayitlari.data)
      ? satirKayitlari.data.map((kayit) => String(kayit.id))
      : [];

    const kanitSatillari: Array<Record<string, unknown>> = [];
    const adaySatirlari: Array<Record<string, unknown>> = [];
    const gorselSatirlari: Array<Record<string, unknown>> = [];

    satirIdleri.forEach((lineId, sira) => {
      const satir = girdi.satirlar[sira];
      if (!satir) return;

      const kaynak = satir.katalog?.kaynak || "fatura";
      kanitSatillari.push({
        line_id: lineId,
        field_name: "urun_adi",
        value_text: (satir.katalog?.resmiAd || satir.ad || "").slice(0, 300),
        source: kaynak,
        strength: kanitGucu(satir),
      });
      kanitSatillari.push({
        line_id: lineId,
        field_name: "kod",
        value_text: (satir.model || satir.barkod).slice(0, 60),
        source: kaynak,
        strength: satir.katalog ? "strong" : "weak",
      });

      if (satir.katalog) {
        adaySatirlari.push({
          line_id: lineId,
          url: satir.katalog.kaynak.slice(0, 500),
          platform: (girdi.tedarikciIz?.platform ?? "").slice(0, 40),
        });

        const durum = gorselIzinDurumu(satir.katalog.izinDurumu);
        for (const aday of satir.katalog.gorselAdaylari) {
          gorselSatirlari.push({
            line_id: lineId,
            image_url: aday.slice(0, 500),
            usage_status: durum,
            source: satir.katalog.kaynak.slice(0, 500),
          });
        }
      }
    });

    if (kanitSatillari.length) {
      await admin
        .from("invoice_line_evidence")
        .upsert(kanitSatillari, { onConflict: "line_id,field_name,source" });
    }
    if (adaySatirlari.length) {
      await admin.from("invoice_line_candidates").upsert(adaySatirlari, { onConflict: "line_id,url" });
    }
    if (gorselSatirlari.length) {
      await admin
        .from("invoice_image_rights")
        .upsert(gorselSatirlari, { onConflict: "line_id,image_url" });
    }

    return jobId;
  } catch (hata) {
    console.error(
      "[faturaIslemKaydi] is kaydi yazilamadi:",
      hata instanceof Error ? hata.message : hata,
    );
    return null;
  }
}
