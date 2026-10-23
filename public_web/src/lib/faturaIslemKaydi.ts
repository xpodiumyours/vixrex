import { createHash } from "node:crypto";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import type { EslesmisFaturaSatiri } from "@/lib/faturaEslestir";
import {
  alisverisKarari,
  belgeTarihiIso,
  type AlisverisIliskisi,
  type AlisverisSatiri,
} from "@/lib/faturaAlisveris";

export interface TedarikciDijitalIzi {
  anahtar?: string;
  alan?: string;
  platform?: string;
  izinDurumu?: string;
  kaynak?: string;
  havuzda?: boolean;
  dogrulama?: unknown;
}

export interface DijitalIzAramaDurumu {
  erisimHatasi?: boolean;
  sinirDoldu?: boolean;
  sonrakiSatir?: number;
  hatalar?: Record<string, string>;
  siteDurumu?: unknown;
  presetCevabi?: { belgeEkleri?: unknown; gruplar?: unknown[]; uyarilar?: string[]; kartCevabi?: unknown; asamaKullanimlari?: unknown };
}

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
  aramaDurumu?: DijitalIzAramaDurumu;
  providerJobId?: string;
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
  // Araştırma adayında katalog/kaynak saklanmış olabilir. Onu güçlü kanıt
  // olarak etiketlemek, görsel ve varyant doğrulamasını atlamak olur.
  if (satir.sonuc === "kanitli" && satir.katalog) return "strong";
  if (satir.katalog) return "partial";
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
    value_text: (satir.katalog?.resmiAd || satir.ad || ""),
    source: kaynak,
    strength: kanitGucu(satir),
  });
  kanit.push({
    line_id: lineId,
    field_name: "kod",
    value_text: (satir.model || satir.barkod),
    source: kaynak,
    strength: satir.katalog && satir.sonuc === "kanitli" ? "strong" : satir.katalog ? "partial" : "weak",
  });

  if (satir.katalog) {
    aday.push({
      line_id: lineId,
      url: satir.katalog.kaynak,
      platform: platform,
    });

    const durum = gorselIzinDurumu(satir.katalog.izinDurumu);
    for (const adres of new Set([...satir.katalog.gorselAdaylari, ...(satir.katalog.urunVaryantlari ?? []).flatMap((varyant) => varyant.gorseller)])) {
      gorsel.push({
        line_id: lineId,
        image_url: adres,
        usage_status: durum,
        source: satir.katalog.kaynak,
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

    const beklemeVar = girdi.satirlar.some((satir) => satir.sonuc !== "kanitli");
    const isGirdisi = {
          store_id: storeId,
          document_fingerprint: girdi.parmakIzi,
          status: beklemeVar ? "inceleme" : "eslestirme",
          supplier_name: girdi.tedarikci,
          supplier_tax_id: girdi.tedarikciVergiNo,
          supplier_address: girdi.tedarikciAdres,
          supplier_site: girdi.tedarikciSite,
          discovery_state: girdi.aramaDurumu ?? {},
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
          document_warning: (girdi.belgeUyarisi ?? "").trim(),
          document_type: (girdi.belgeTuru ?? ""),
          document_no: (girdi.belgeNo ?? ""),
          document_date: belgeTarihiIso(girdi.belgeTarihi ?? "") || null,
          goods_total: girdi.malBedeli ?? null,
          vat_total: girdi.kdvTutari ?? null,
          discount_total: girdi.indirimTutari ?? null,
          payable_total: girdi.odenecekToplam ?? null,
          updated_at: new Date().toISOString(),
        };
    const satirYazlari = girdi.satirlar.map((satir, sira) => ({
      line_index: sira,
      raw_line: satir.hamSatir ?? "",
      model: satir.model,
      product_name: satir.ad,
      barcode: satir.barkod.replace(/\D/g, ""),
      variant_name: satir.varyant,
      size_text: satir.beden,
      qty: satir.adet,
      qty_unit: (satir.birim ?? ""),
      unit_price: satir.alisBirimFiyat,
      line_total: satir.satirToplam,
      confidence: satir.guven,
      outcome: satir.sonuc,
      brand: (satir.marka ?? ""),
      warning: (satir.uyari ?? "").trim(),
      catalog_snapshot: satir.katalog,
      conflict_snapshot: satir.celiski ?? null,
    }));
    const { data, error } = await admin.rpc(girdi.providerJobId ? "complete_invoice_provider_job" : "save_invoice_job", {
      p_store_id: storeId,
      ...(girdi.providerJobId ? { p_job_id: girdi.providerJobId } : {}),
      p_job: isGirdisi,
      p_lines: satirYazlari,
    });
    if (error || data?.success !== true || typeof data.id !== "string" || !data.id) return null;
    return data.id;
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
