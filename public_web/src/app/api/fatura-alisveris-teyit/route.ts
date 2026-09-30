import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { verifyStoreEditToken } from "@/lib/instagramServer";

export const dynamic = "force-dynamic";

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function POST(request: NextRequest) {
  let govde: {
    slug?: unknown;
    editToken?: unknown;
    islemKimligi?: unknown;
    digerIslemKimligi?: unknown;
    ayni?: unknown;
  };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const islemKimligi = typeof govde.islemKimligi === "string" ? govde.islemKimligi.trim() : "";
  const digerKimlik =
    typeof govde.digerIslemKimligi === "string" ? govde.digerIslemKimligi.trim() : "";
  const editTokenGovde = typeof govde.editToken === "string" ? govde.editToken.trim() : "";

  if (!slug) return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 422 });
  if (!KIMLIK.test(islemKimligi) || !KIMLIK.test(digerKimlik) || islemKimligi === digerKimlik) {
    return NextResponse.json({ hata: "İşlem kimliği geçersiz." }, { status: 422 });
  }
  if (typeof govde.ayni !== "boolean") {
    return NextResponse.json({ hata: "Cevap belirtilmedi." }, { status: 422 });
  }

  const cookieStore = await cookies();
  const cerezliOturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);

  let storeId = cerezliOturum?.storeId ?? "";
  if (!cerezliOturum) {
    if (!editTokenGovde) {
      return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
    }
    try {
      const store = await verifyStoreEditToken(slug, editTokenGovde);
      storeId = store.id;
    } catch {
      return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
    }
  }
  if (!storeId) return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });

  const admin = getSupabaseAdmin();
  const { data: isler } = await admin
    .from("invoice_jobs")
    .select("id")
    .eq("store_id", storeId)
    .in("id", [islemKimligi, digerKimlik]);
  if (!Array.isArray(isler) || isler.length !== 2) {
    return NextResponse.json({ hata: "İşlem bulunamadı." }, { status: 404 });
  }

  const { error } = await admin
    .from("invoice_jobs")
    .update({
      same_purchase_of: govde.ayni ? digerKimlik : null,
      same_purchase_confirmed_at: new Date().toISOString(),
    })
    .eq("id", islemKimligi)
    .eq("store_id", storeId);
  if (error) {
    console.error("[fatura-alisveris-teyit] yazilamadi:", error.message);
    return NextResponse.json({ hata: "Cevabın kaydedilemedi. Tekrar dene." }, { status: 500 });
  }

  return NextResponse.json({ tamam: true, ayni: govde.ayni });
}
