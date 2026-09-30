import { createHash } from "node:crypto";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import type { TedarikciDijitalIzi } from "@/lib/faturaDijitalIz";
import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import {
  alisverisKarari,
  belgeTarihiIso,
  type AlisverisIliskisi,
  type AlisverisSatiri,
} from "@/lib/faturaAlisveris";

export function belgeParmakIzi(bayt: Uint8Array): string {
  return createHash("sha256").update(bayt).digest("hex");
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
  belgeTuru?: string;
  belgeNo?: string;
  belgeTarihi?: string;
  malBedeli?: number | null;
  kdvTutari?: number | null;
  indirimTutari?: number | null;
  odenecekToplam?: number | null;
  belgeUyarisi?: string | null;
}

export interface AyniAlisverisAdayi {
  islemKimligi: string;
  iliski: Exclude<AlisverisIliskisi, "farkli">;
  sebep: string;
  belgeTuru: string;
  belgeNo: string;
  belgeTarihi: string | null;
  satirSayisi: number;
  satirlar: AlisverisSatiri[];
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

export function satirKanitKayitlari(
  lineId: string,
  satir: EslesmisFaturaSatiri,
  platform: string,
): {
  kanit: Array<Record<string, unknown>>;
  aday: Array<Record<string, unknown>>;
  gorsel: Array<Record<string, unknown>>;
} {
  const kanit: Array<Record<string, unknown>> = [];
  const aday: Array<Record<string, unknown>> = [];
  const gorsel: Array<Record<string, unknown>> = [];

  const kaynak = satir.katalog?.kaynak || "fatura";
  kanit.push({
    line_id: lineId,
    field_name: "urun_adi",
    value_text: (satir.katalog?.resmiAd || satir.ad || "").slice(0, 300),
    source: kaynak,
    strength: kanitGucu(satir),
  });
  kanit.push({
    line_id: lineId,
    field_name: "kod",
    value_text: (satir.model || satir.barkod).slice(0, 60),
    source: kaynak,
    strength: satir.katalog ? "strong" : "weak",
  });

  if (satir.katalog) {
    aday.push({
      line_id: lineId,
      url: satir.katalog.kaynak.slice(0, 500),
      platform: platform.slice(0, 40),
    });

    const durum = gorselIzinDurumu(satir.katalog.izinDurumu);
    for (const adres of satir.katalog.gorselAdaylari) {
      gorsel.push({
        line_id: lineId,
        image_url: adres.slice(0, 500),
        usage_status: durum,
        source: satir.katalog.kaynak.slice(0, 500),
      });
    }
  }

  return { kanit, aday, gorsel };
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

    const varolan = await admin
      .from("invoice_jobs")
      .select("id")
      .eq("store_id", storeId)
      .eq("document_fingerprint", girdi.parmakIzi)
      .maybeSingle();
    if (typeof varolan.data?.id === "string" && varolan.data.id) {
      const satirVar = await admin
        .from("invoice_job_lines")
        .select("id", { count: "exact", head: true })
        .eq("job_id", varolan.data.id);
      if ((satirVar.count ?? 0) > 0) return varolan.data.id;
    }

    const beklemeVar = girdi.satirlar.some((satir) => satir.sonuc !== "kanitli");
    const isKaydi = await admin
      .from("invoice_jobs")
      .upsert(
        {
          store_id: storeId,
          document_fingerprint: girdi.parmakIzi,
          status: beklemeVar ? "inceleme" : "eslestirme",
          supplier_name: girdi.tedarikci.slice(0, 200),
          supplier_tax_id: girdi.tedarikciVergiNo.slice(0, 40),
          supplier_address: girdi.tedarikciAdres.slice(0, 500),
          supplier_site: girdi.tedarikciSite.slice(0, 200),
          supplier_trace: girdi.tedarikciIz
            ? {
                anahtar: girdi.tedarikciIz.anahtar,
                alan: girdi.tedarikciIz.alan,
                platform: girdi.tedarikciIz.platform,
                izinDurumu: girdi.tedarikciIz.izinDurumu,
                kaynak: girdi.tedarikciIz.kaynak,
                havuzda: girdi.tedarikciIz.havuzda,
                dogrulama: girdi.tedarikciIz.dogrulama ?? null,
              }
            : null,
          document_adet: girdi.belgeAdedi,
          document_total: girdi.belgeToplami,
          document_warning: (girdi.belgeUyarisi ?? "").slice(0, 500),
          document_type: (girdi.belgeTuru ?? "").slice(0, 40),
          document_no: (girdi.belgeNo ?? "").slice(0, 60),
          document_date: belgeTarihiIso(girdi.belgeTarihi ?? "") || null,
          goods_total: girdi.malBedeli ?? null,
          vat_total: girdi.kdvTutari ?? null,
          discount_total: girdi.indirimTutari ?? null,
          payable_total: girdi.odenecekToplam ?? null,
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
      brand: (satir.marka ?? "").slice(0, 120),
      warning: (satir.uyari ?? "").slice(0, 500),
      catalog_snapshot: satir.katalog,
      conflict_snapshot: satir.celiski ?? null,
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

      const kayitlar = satirKanitKayitlari(lineId, satir, girdi.tedarikciIz?.platform ?? "");
      kanitSatillari.push(...kayitlar.kanit);
      adaySatirlari.push(...kayitlar.aday);
      gorselSatirlari.push(...kayitlar.gorsel);
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

export async function ayniAlisverisAdaylari(args: {
  slug: string;
  islemKimligi: string;
  girdi: IslemKaydiGirdisi;
}): Promise<AyniAlisverisAdayi[]> {
  try {
    const admin = getSupabaseAdmin();

    const magaza = await admin.from("stores").select("id").eq("slug", args.slug).maybeSingle();
    const storeId = magaza.data?.id;
    if (typeof storeId !== "string" || !storeId) return [];

    const oncekiler = await admin
      .from("invoice_jobs")
      .select("id,supplier_name,supplier_tax_id,document_type,document_no,document_date")
      .eq("store_id", storeId)
      .neq("id", args.islemKimligi)
      .order("created_at", { ascending: false })
      .limit(50);
    const kayitlar = Array.isArray(oncekiler.data) ? oncekiler.data : [];
    if (kayitlar.length === 0) return [];

    const yeniSatirlar: AlisverisSatiri[] = args.girdi.satirlar.map((satir) => ({
      kod: satir.model || satir.barkod,
      adet: satir.adet,
    }));
    const yeniKimlik = {
      tur: args.girdi.belgeTuru ?? "",
      no: args.girdi.belgeNo ?? "",
      tarih: args.girdi.belgeTarihi ?? "",
      saticiVergiNo: args.girdi.tedarikciVergiNo,
      saticiAd: args.girdi.tedarikci,
    };

    const adaylar: AyniAlisverisAdayi[] = [];
    for (const kayit of kayitlar) {
      const satirlar = await admin
        .from("invoice_job_lines")
        .select("model,barcode,qty")
        .eq("job_id", kayit.id);
      const eskiSatirlar: AlisverisSatiri[] = (Array.isArray(satirlar.data) ? satirlar.data : []).map(
        (satir) => ({
          kod: String(satir.model || satir.barcode || ""),
          adet: typeof satir.qty === "number" ? satir.qty : satir.qty === null ? null : Number(satir.qty),
        }),
      );

      const karar = alisverisKarari(
        { kimlik: yeniKimlik, satirlar: yeniSatirlar },
        {
          kimlik: {
            tur: String(kayit.document_type ?? ""),
            no: String(kayit.document_no ?? ""),
            tarih: String(kayit.document_date ?? ""),
            saticiVergiNo: String(kayit.supplier_tax_id ?? ""),
            saticiAd: String(kayit.supplier_name ?? ""),
          },
          satirlar: eskiSatirlar,
        },
      );
      if (karar.iliski === "farkli") continue;

      adaylar.push({
        islemKimligi: String(kayit.id),
        iliski: karar.iliski,
        sebep: karar.sebep,
        belgeTuru: String(kayit.document_type ?? ""),
        belgeNo: String(kayit.document_no ?? ""),
        belgeTarihi: kayit.document_date ? String(kayit.document_date) : null,
        satirSayisi: eskiSatirlar.length,
        satirlar: eskiSatirlar,
      });
    }
    return adaylar;
  } catch (hata) {
    console.error(
      "[faturaIslemKaydi] ayni alisveris adaylari okunamadi:",
      hata instanceof Error ? hata.message : hata,
    );
    return [];
  }
}
