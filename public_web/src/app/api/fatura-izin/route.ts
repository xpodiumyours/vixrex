import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";

// Hazır kart üzerinden firma izin talebi: esnaf "Ben isteyeceğim" ya da
// "VixRex benim için istesin" der. Kayıt + gönderim + cevap ayrı durumlardır;
// talep, firmanın izni yerine geçmez.
export const dynamic = "force-dynamic";

function slugFrom(url: string): string {
  try {
    return new URL(url).searchParams.get("slug")?.trim() ?? "";
  } catch {
    return "";
  }
}

export async function GET(request: NextRequest) {
  const slug = request.nextUrl.searchParams.get("slug")?.trim() ?? "";
  if (!slug) return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });
  const cookieStore = await cookies();
  const oturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!oturum) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
  try {
    const admin = getSupabaseAdmin();
    const { data } = await admin
      .from("invoice_permission_requests")
      .select("id,firma,kapsam,sorumlu,durum,gonderildi_at,cevap_at,cevap_notu,job_id,ornek_urun_id,created_at")
      .eq("store_id", oturum.storeId)
      .order("created_at", { ascending: false })
      .limit(50);
    return NextResponse.json({ tamam: true, talepler: Array.isArray(data) ? data : [] });
  } catch (err) {
    console.error("[fatura-izin] liste okunamadi:", err);
    return NextResponse.json({ hata: "Talepler okunamadı." }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : slugFrom(request.url);
  const firma = typeof govde.firma === "string" ? govde.firma.trim().slice(0, 200) : "";
  const sorumlu = govde.sorumlu === "vixrex" ? "vixrex" : "esnaf";
  const jobId = typeof govde.islemKimligi === "string" && govde.islemKimligi.trim() ? govde.islemKimligi.trim() : null;
  const ornekUrunId =
    typeof govde.ornekUrunId === "string" && govde.ornekUrunId.trim() ? govde.ornekUrunId.trim() : null;
  const kapsam = typeof govde.kapsam === "string" ? govde.kapsam.trim().slice(0, 500) : "";
  if (!slug || !firma) return NextResponse.json({ hata: "Vitrin ve firma zorunludur." }, { status: 422 });

  const cookieStore = await cookies();
  const oturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!oturum) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });

  try {
    const admin = getSupabaseAdmin();
    // Aynı firma + aynı iş için tekrar talep yağmasın: açık talep varsa onu döndür.
    if (jobId) {
      const { data: mevcut } = await admin
        .from("invoice_permission_requests")
        .select("id,durum")
        .eq("store_id", oturum.storeId)
        .eq("job_id", jobId)
        .eq("firma", firma)
        .limit(1)
        .maybeSingle();
      const kayit = mevcut as { id?: string } | null;
      if (kayit?.id) return NextResponse.json({ tamam: true, id: kayit.id, mevcut: true });
    }
    const { data, error } = await admin
      .from("invoice_permission_requests")
      .insert({
        store_id: oturum.storeId,
        job_id: jobId,
        firma,
        kapsam: kapsam || "Ürün bilgileri ve görselleri",
        ornek_urun_id: ornekUrunId,
        sorumlu,
        durum: sorumlu === "vixrex" ? "cevap_bekliyor" : "hazir",
        gonderildi_at: sorumlu === "vixrex" ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
      })
      .select("id")
      .single();
    if (error || !(data as { id?: string } | null)?.id) {
      return NextResponse.json({ hata: "Talep kaydedilemedi." }, { status: 500 });
    }
    return NextResponse.json({ tamam: true, id: (data as { id: string }).id });
  } catch (err) {
    console.error("[fatura-izin] yazilamadi:", err);
    return NextResponse.json({ hata: "Talep kaydedilemedi." }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }
  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const id = typeof govde.id === "string" ? govde.id.trim() : "";
  const durum =
    govde.durum === "gonderildi" || govde.durum === "izin_var" || govde.durum === "reddedildi"
      ? (govde.durum as string)
      : null;
  if (!slug || !id || !durum) return NextResponse.json({ hata: "Vitrin, talep ve durum zorunludur." }, { status: 422 });
  const cookieStore = await cookies();
  const oturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);
  if (!oturum) return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
  try {
    const admin = getSupabaseAdmin();
    const yama: Record<string, unknown> = { durum, updated_at: new Date().toISOString() };
    if (durum === "gonderildi") yama.gonderildi_at = new Date().toISOString();
    if (durum === "izin_var" || durum === "reddedildi") {
      yama.cevap_at = new Date().toISOString();
      if (typeof govde.cevapNotu === "string") yama.cevap_notu = govde.cevapNotu.slice(0, 500);
    }
    const { error } = await admin
      .from("invoice_permission_requests")
      .update(yama)
      .eq("id", id)
      .eq("store_id", oturum.storeId);
    if (error) return NextResponse.json({ hata: "Talep güncellenemedi." }, { status: 500 });
    return NextResponse.json({ tamam: true });
  } catch (err) {
    console.error("[fatura-izin] guncellenemedi:", err);
    return NextResponse.json({ hata: "Talep güncellenemedi." }, { status: 500 });
  }
}
