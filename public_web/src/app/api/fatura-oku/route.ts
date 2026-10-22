import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import { belgeParmakIzi } from "@/lib/faturaIslemKaydi";
import { faturaTaslaklari } from "@/lib/faturaTaslagi";
import { islemiYukle, islemYaniti, parmakIzindenIslemBul } from "@/lib/faturaIslemOku";
import { faturayiArkaPlanaGonder, bekleyenFaturaYaniti, arkaPlanFaturaHatasi } from "@/lib/faturaArkaPlanIslemi";

export const dynamic = "force-dynamic";
export const maxDuration = 60;

const MAKS_BAYT = 4 * 1024 * 1024;
const MAKS_SAYFA = 3;
const VITRIN_BASINA_LIMIT = 30;
const PENCERE_SANIYE = 3600;
const IZINLI_TURLER = new Set(["image/jpeg", "image/png", "image/webp", "application/pdf"]);

function gercekTur(bayt: Uint8Array): string | null {
  if (bayt.length < 12) return null;
  if (bayt[0] === 0x25 && bayt[1] === 0x50 && bayt[2] === 0x44 && bayt[3] === 0x46 && bayt[4] === 0x2d) return "application/pdf";
  if (bayt[0] === 0xff && bayt[1] === 0xd8 && bayt[2] === 0xff) return "image/jpeg";
  if ([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a].every((b, i) => bayt[i] === b)) return "image/png";
  if ([0x52, 0x49, 0x46, 0x46].every((b, i) => bayt[i] === b) && [0x57, 0x45, 0x42, 0x50].every((b, i) => bayt[8 + i] === b)) return "image/webp";
  return null;
}

export async function POST(request: NextRequest) {
  let form: FormData;
  try { form = await request.formData(); }
  catch { return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 }); }
  const slug = String(form.get("slug") ?? "").trim();
  const dosyalar = form.getAll("dosya");
  const editToken = String(form.get("editToken") ?? "").trim();
  if (!slug) return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  if (!dosyalar.length || dosyalar.some((d) => !(d instanceof File))) return NextResponse.json({ hata: "Fatura fotoğrafı bulunamadı." }, { status: 400 });
  if (dosyalar.length > MAKS_SAYFA) return NextResponse.json({ hata: "Tek faturada en fazla 3 sayfa fotoğrafı yüklenebilir." }, { status: 413 });
  const secilen = dosyalar as File[];
  const cookieStore = await cookies();
  const oturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  let ownerSlug: string;
  if (oturum) ownerSlug = oturum.slug;
  else if (editToken) {
    try { ownerSlug = (await verifyStoreEditToken(slug, editToken)).slug; }
    catch { return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 }); }
  } else return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });

  const admin = getSupabaseAdmin();
  const magaza = await admin.from("stores").select("id").eq("slug", ownerSlug).maybeSingle();
  const storeId = magaza.data?.id;
  if (!storeId) return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  const limitSonucu = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_oku:${ownerSlug}`, p_max_requests: VITRIN_BASINA_LIMIT, p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitSonucu.data) ? limitSonucu.data[0] : limitSonucu.data;
  if (!limitSonucu.error && limit?.allowed === false) return NextResponse.json({ hata: `Çok fazla fatura okudun. ${limit.retry_after_seconds} sn sonra dene.` }, { status: 429 });
  if (secilen.reduce((sum, f) => sum + f.size, 0) > MAKS_BAYT) return NextResponse.json({ hata: "Sayfa fotoğraflarının toplamı en fazla 4 MB olabilir." }, { status: 413 });
  const baytlar = await Promise.all(secilen.map(async (f) => new Uint8Array(await f.arrayBuffer())));
  const turler = baytlar.map(gercekTur);
  if (turler.some((t) => !t || !IZINLI_TURLER.has(t))) return NextResponse.json({ hata: "Fatura yalnız JPG, PNG, WebP veya PDF biçiminde olmalıdır." }, { status: 415 });
  const ozet = Buffer.concat(baytlar.map((b) => {
    const uzunluk = Buffer.alloc(4); uzunluk.writeUInt32BE(b.length, 0);
    return Buffer.concat([uzunluk, Buffer.from(b)]);
  }));
  const parmakIzi = belgeParmakIzi(ozet);
  const eskiId = await parmakIzindenIslemBul(admin, storeId, parmakIzi);
  const onceki = eskiId ? await islemiYukle(admin, storeId, eskiId) : null;
  if (onceki?.satirlar.length) return NextResponse.json({ ...islemYaniti(onceki), taslaklar: faturaTaslaklari(onceki.satirlar, onceki.islemKimligi) });
  if (!process.env.OPENROUTER_API_KEY) return NextResponse.json({ hata: "Fatura okuyucu hazır değil." }, { status: 503 });
  const fotograflar = baytlar.map((b, i) => `data:${turler[i]};base64,${Buffer.from(b).toString("base64")}`);
  try {
    const id = await faturayiArkaPlanaGonder(admin, storeId, parmakIzi, fotograflar);
    return NextResponse.json(bekleyenFaturaYaniti(id), { status: 202, headers: { "Cache-Control": "private, no-store" } });
  } catch (err) {
    const kod = err instanceof Error ? err.message : "OKUYUCU_CEVAP_VERMEDI";
    return NextResponse.json({ hata: arkaPlanFaturaHatasi(kod) }, { status: 503 });
  }
}
