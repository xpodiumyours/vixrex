import type { SupabaseClient } from "@supabase/supabase-js";

export type IzinKapsami = "data" | "images" | "data_and_images";
export type IzinDurumu = "izin_yok" | "izin_verildi" | "reddedildi" | "geri_cekildi";
export type TalepDurumu =
  | "hazirlandi"
  | "gonderim_bekliyor"
  | "gonderildi"
  | "cevaplandi"
  | "geri_cekildi";

export const IZIN_KAPSAMLARI: readonly IzinKapsami[] = ["data", "images", "data_and_images"];

export interface IzinKaydi {
  durum: IzinDurumu;
  kapsam: IzinKapsami;
  gecerli: boolean;
  gecerlilik: string | null;
  cevapZamani: string | null;
  not: string;
}

export interface TalepKaydi {
  talepKimligi: string;
  durum: TalepDurumu;
  isteyen: "owner" | "vixrex";
  kapsam: IzinKapsami;
  mesaj: string;
  ornekAdres: string;
  gonderimZamani: string | null;
  olusturma: string;
  urunSayisi: number;
}

export interface IzinOzeti {
  firmaAnahtari: string;
  firmaAdi: string;
  izin: IzinKaydi;
  talep: TalepKaydi | null;
  etiket: string;
}

export function kapsamGecerliMi(deger: unknown): deger is IzinKapsami {
  return typeof deger === "string" && (IZIN_KAPSAMLARI as readonly string[]).includes(deger);
}

export function izinEtiketi(izin: IzinKaydi, talep: TalepKaydi | null): string {
  if (izin.durum === "izin_verildi" && izin.gecerli) return "Firma izni verildi";
  if (izin.durum === "izin_verildi" && !izin.gecerli) return "Firma izninin süresi doldu";
  if (izin.durum === "reddedildi") return "Firma izni reddetti";
  if (izin.durum === "geri_cekildi") return "Firma izni geri çekti";
  if (!talep) return "İzin henüz sorulmadı";
  if (talep.durum === "hazirlandi") return "Talep metni hazır; göndermeyi sen yapacaksın";
  if (talep.durum === "gonderim_bekliyor") return "Talep sıraya alındı; henüz gönderilmedi";
  if (talep.durum === "gonderildi") return "Talep gönderildi; firma cevabı bekleniyor";
  return "İzin henüz sorulmadı";
}

function bugun(simdi: Date): string {
  return simdi.toISOString().slice(0, 10);
}

export function izinGecerliMi(
  durum: IzinDurumu,
  gecerlilik: string | null,
  simdi: Date = new Date(),
): boolean {
  if (durum !== "izin_verildi") return false;
  return gecerlilik === null || gecerlilik >= bugun(simdi);
}

export function talepMetniOlustur(args: {
  firmaAdi: string;
  esnafAdi: string;
  urunAdlari: string[];
  ornekAdres: string;
  kapsam: IzinKapsami;
}): string {
  const kapsamMetni =
    args.kapsam === "data"
      ? "ürün bilgilerinizin"
      : args.kapsam === "images"
        ? "ürün görsellerinizin"
        : "ürün bilgileriniz ve görsellerinizin";
  const urunler = args.urunAdlari.slice(0, 10).map((ad) => `- ${ad}`);
  return [
    `Merhaba ${args.firmaAdi} ekibi,`,
    "",
    `${args.esnafAdi} ürünlerinizi satan bir esnaf. Vixrex ile aldığı ürünlerin fatura fotoğrafından, doğru ürün bilgileri ve görselleriyle dijital vitrin hazırlıyoruz. Çalışan örneği burada görebilirsiniz: ${args.ornekAdres}`,
    "",
    urunler.length > 0 ? "Örnekte yer alan ürünleriniz:" : "",
    ...urunler,
    urunler.length > 0 ? "" : "",
    `Bu köprüyü ürünlerinizi satan küçük esnafların kullanımına açabilmek için ${kapsamMetni} kullanım iznini rica ediyoruz. Onayınız ya da çekincelerinizi bu mesaja yanıt olarak iletebilirsiniz; izin verilmedikçe başka bir kullanım yapılmaz.`,
    "",
    "Teşekkürler.",
  ]
    .filter((satir, sira, hepsi) => !(satir === "" && hepsi[sira - 1] === ""))
    .join("\n")
    .trim();
}

interface IsBilgisi {
  id: string;
  supplier_name: string | null;
  supplier_site: string | null;
  supplier_trace: { anahtar?: unknown; alan?: unknown } | null;
}

export function firmaAnahtariUret(is: IsBilgisi): string {
  const izAnahtari = typeof is.supplier_trace?.anahtar === "string" ? is.supplier_trace.anahtar : "";
  if (izAnahtari) return izAnahtari;
  const alan = typeof is.supplier_trace?.alan === "string" ? is.supplier_trace.alan : "";
  if (alan) return alan.toLowerCase();
  return (is.supplier_name ?? "")
    .toLocaleLowerCase("tr-TR")
    .replace(/[^a-z0-9çğıöşü]/g, "");
}

function izinKaydiOlustur(kayit: Record<string, unknown> | null, kapsam: IzinKapsami): IzinKaydi {
  if (!kayit) {
    return { durum: "izin_yok", kapsam, gecerli: false, gecerlilik: null, cevapZamani: null, not: "" };
  }
  const durum = String(kayit.status ?? "izin_yok") as IzinDurumu;
  const gecerlilik = kayit.valid_until ? String(kayit.valid_until) : null;
  return {
    durum,
    kapsam,
    gecerli: izinGecerliMi(durum, gecerlilik),
    gecerlilik,
    cevapZamani: kayit.responded_at ? String(kayit.responded_at) : null,
    not: String(kayit.response_note ?? ""),
  };
}

function talepKaydiOlustur(kayit: Record<string, unknown>, urunSayisi: number): TalepKaydi {
  return {
    talepKimligi: String(kayit.id),
    durum: String(kayit.status) as TalepDurumu,
    isteyen: kayit.requested_by === "vixrex" ? "vixrex" : "owner",
    kapsam: kapsamGecerliMi(kayit.scope) ? kayit.scope : "data_and_images",
    mesaj: String(kayit.message ?? ""),
    ornekAdres: String(kayit.sample_url ?? ""),
    gonderimZamani: kayit.sent_at ? String(kayit.sent_at) : null,
    olusturma: String(kayit.created_at ?? ""),
    urunSayisi,
  };
}

async function isiOku(admin: SupabaseClient, storeId: string, islemKimligi: string): Promise<IsBilgisi | null> {
  const is = await admin
    .from("invoice_jobs")
    .select("id,supplier_name,supplier_site,supplier_trace")
    .eq("id", islemKimligi)
    .eq("store_id", storeId)
    .maybeSingle();
  return is.data?.id ? (is.data as IsBilgisi) : null;
}

export async function izinOzetiOku(
  admin: SupabaseClient,
  storeId: string,
  islemKimligi: string,
  kapsam: IzinKapsami = "data_and_images",
): Promise<IzinOzeti | null> {
  const is = await isiOku(admin, storeId, islemKimligi);
  if (!is) return null;
  const firmaAnahtari = firmaAnahtariUret(is);
  if (!firmaAnahtari) return null;

  const izin = await admin
    .from("supplier_permissions")
    .select("status,valid_until,responded_at,response_note")
    .eq("supplier_key", firmaAnahtari)
    .eq("scope", kapsam)
    .maybeSingle();
  const izinKaydi = izinKaydiOlustur(izin.data as Record<string, unknown> | null, kapsam);

  const talepler = await admin
    .from("supplier_permission_requests")
    .select("id,status,requested_by,scope,message,sample_url,sent_at,created_at")
    .eq("store_id", storeId)
    .eq("supplier_key", firmaAnahtari)
    .eq("scope", kapsam)
    .order("created_at", { ascending: false })
    .limit(1);
  const sonTalep = Array.isArray(talepler.data) ? (talepler.data[0] as Record<string, unknown> | undefined) : undefined;

  let talep: TalepKaydi | null = null;
  if (sonTalep) {
    const say = await admin
      .from("supplier_permission_products")
      .select("product_id", { count: "exact", head: true })
      .eq("request_id", String(sonTalep.id));
    talep = talepKaydiOlustur(sonTalep, say.count ?? 0);
  }

  return {
    firmaAnahtari,
    firmaAdi: is.supplier_name ?? "",
    izin: izinKaydi,
    talep,
    etiket: izinEtiketi(izinKaydi, talep),
  };
}

export type TalepSonucu =
  | { durum: "izin-var"; ozet: IzinOzeti }
  | { durum: "reddedilmis"; ozet: IzinOzeti }
  | { durum: "mevcut" | "olustu"; ozet: IzinOzeti }
  | { durum: "hata"; hata: string };

export async function talepOlustur(
  admin: SupabaseClient,
  args: {
    storeId: string;
    magazaAdi: string;
    magazaSlug: string;
    islemKimligi: string;
    secim: "owner" | "vixrex";
    kapsam: IzinKapsami;
    siteOrigin: string;
  },
): Promise<TalepSonucu> {
  const is = await isiOku(admin, args.storeId, args.islemKimligi);
  if (!is) return { durum: "hata", hata: "İşlem bulunamadı." };
  const firmaAnahtari = firmaAnahtariUret(is);
  if (!firmaAnahtari) return { durum: "hata", hata: "Faturadaki firma belirlenemedi; izin talebi açılamaz." };

  const mevcut = await izinOzetiOku(admin, args.storeId, args.islemKimligi, args.kapsam);
  if (!mevcut) return { durum: "hata", hata: "İzin durumu okunamadı." };
  if (mevcut.izin.durum === "izin_verildi" && mevcut.izin.gecerli) return { durum: "izin-var", ozet: mevcut };
  if (mevcut.izin.durum === "reddedildi") return { durum: "reddedilmis", ozet: mevcut };
  if (
    mevcut.talep &&
    (mevcut.talep.durum === "hazirlandi" ||
      mevcut.talep.durum === "gonderim_bekliyor" ||
      mevcut.talep.durum === "gonderildi")
  ) {
    return { durum: "mevcut", ozet: mevcut };
  }

  const satirlar = await admin
    .from("invoice_job_lines")
    .select("product_id,catalog_snapshot")
    .eq("job_id", args.islemKimligi);
  const kayitlar = Array.isArray(satirlar.data) ? satirlar.data : [];
  const eslesenler = kayitlar.filter((kayit) => kayit.catalog_snapshot);
  const urunAdlari = eslesenler
    .map((kayit) => String((kayit.catalog_snapshot as { resmiAd?: unknown }).resmiAd ?? ""))
    .filter(Boolean);
  const urunIdleri = eslesenler
    .map((kayit) => (kayit.product_id ? String(kayit.product_id) : ""))
    .filter(Boolean);

  const ornekAdres = `${args.siteOrigin.replace(/\/$/, "")}/v/${args.magazaSlug}`;
  const firmaAdi = (is.supplier_name ?? "").trim() || "ilgili firma";
  const mesaj = talepMetniOlustur({
    firmaAdi,
    esnafAdi: args.magazaAdi || "Bir esnaf",
    urunAdlari,
    ornekAdres,
    kapsam: args.kapsam,
  });

  const eklenen = await admin
    .from("supplier_permission_requests")
    .insert({
      store_id: args.storeId,
      job_id: args.islemKimligi,
      supplier_key: firmaAnahtari,
      supplier_name: firmaAdi,
      supplier_site: (is.supplier_site ?? "").slice(0, 200),
      scope: args.kapsam,
      requested_by: args.secim,
      status: args.secim === "owner" ? "hazirlandi" : "gonderim_bekliyor",
      message: mesaj,
      sample_url: ornekAdres,
    })
    .select("id")
    .single();

  if (eklenen.error || !eklenen.data?.id) {
    const cakisma = await izinOzetiOku(admin, args.storeId, args.islemKimligi, args.kapsam);
    if (cakisma?.talep) return { durum: "mevcut", ozet: cakisma };
    return { durum: "hata", hata: "Talep kaydedilemedi. Tekrar dene." };
  }

  if (urunIdleri.length > 0) {
    await admin
      .from("supplier_permission_products")
      .upsert(
        urunIdleri.map((productId) => ({ request_id: String(eklenen.data.id), product_id: productId })),
        { onConflict: "request_id,product_id" },
      );
  }

  const ozet = await izinOzetiOku(admin, args.storeId, args.islemKimligi, args.kapsam);
  if (!ozet) return { durum: "hata", hata: "Talep okunamadı." };
  return { durum: "olustu", ozet };
}

export async function talepGonderildiIsaretle(
  admin: SupabaseClient,
  args: { talepKimligi: string; storeId?: string; isteyen?: "owner" | "vixrex" },
): Promise<boolean> {
  let sorgu = admin
    .from("supplier_permission_requests")
    .update({ status: "gonderildi", sent_at: new Date().toISOString(), updated_at: new Date().toISOString() })
    .eq("id", args.talepKimligi)
    .in("status", ["hazirlandi", "gonderim_bekliyor"]);
  if (args.storeId) sorgu = sorgu.eq("store_id", args.storeId);
  if (args.isteyen) sorgu = sorgu.eq("requested_by", args.isteyen);
  const { error } = await sorgu;
  return !error;
}

export async function cevapKaydet(
  admin: SupabaseClient,
  args: {
    firmaAnahtari: string;
    firmaAdi: string;
    kapsam: IzinKapsami;
    durum: Exclude<IzinDurumu, "izin_yok">;
    gecerlilik: string | null;
    not: string;
    dogrulayan: string;
  },
): Promise<{ tamam: boolean; gizlenen: number }> {
  const simdi = new Date().toISOString();
  const { error } = await admin.from("supplier_permissions").upsert(
    {
      supplier_key: args.firmaAnahtari,
      supplier_name: args.firmaAdi.slice(0, 200),
      scope: args.kapsam,
      status: args.durum,
      valid_until: args.gecerlilik,
      responded_at: simdi,
      response_note: args.not.slice(0, 1000),
      verified_by: args.dogrulayan.slice(0, 120),
      updated_at: simdi,
    },
    { onConflict: "supplier_key,scope" },
  );
  if (error) return { tamam: false, gizlenen: 0 };

  await admin
    .from("supplier_permission_requests")
    .update({ status: "cevaplandi", updated_at: simdi })
    .eq("supplier_key", args.firmaAnahtari)
    .eq("scope", args.kapsam)
    .in("status", ["hazirlandi", "gonderim_bekliyor", "gonderildi"]);

  if (args.durum !== "reddedildi" && args.durum !== "geri_cekildi") return { tamam: true, gizlenen: 0 };

  const talepler = await admin
    .from("supplier_permission_requests")
    .select("id")
    .eq("supplier_key", args.firmaAnahtari)
    .eq("scope", args.kapsam);
  const talepIdleri = (Array.isArray(talepler.data) ? talepler.data : []).map((kayit) => String(kayit.id));
  if (talepIdleri.length === 0) return { tamam: true, gizlenen: 0 };

  const bagli = await admin
    .from("supplier_permission_products")
    .select("request_id,product_id")
    .in("request_id", talepIdleri);
  const urunIdleri = [
    ...new Set((Array.isArray(bagli.data) ? bagli.data : []).map((kayit) => String(kayit.product_id))),
  ];
  if (urunIdleri.length === 0) return { tamam: true, gizlenen: 0 };

  const urunler = await admin
    .from("products")
    .select("id,fatura_kanit")
    .in("id", urunIdleri)
    .eq("is_visible", true);
  const gizlenecek = (Array.isArray(urunler.data) ? urunler.data : [])
    .filter((urun) => (urun.fatura_kanit as { ureticiGorsel?: unknown } | null)?.ureticiGorsel === true)
    .map((urun) => String(urun.id));
  if (gizlenecek.length === 0) return { tamam: true, gizlenen: 0 };

  const { error: gizlemeHatasi } = await admin
    .from("products")
    .update({ is_visible: false })
    .in("id", gizlenecek);
  if (gizlemeHatasi) return { tamam: false, gizlenen: 0 };

  await admin
    .from("supplier_permission_products")
    .update({ action: "gizlendi", action_at: simdi })
    .in("product_id", gizlenecek)
    .in("request_id", talepIdleri);

  return { tamam: true, gizlenen: gizlenecek.length };
}
