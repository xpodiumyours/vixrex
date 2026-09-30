import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { verifyStoreEditToken } from "@/lib/instagramServer";

// Fatura işlemini geri açma: esnaf ekranı kapatıp aynı işten devam eder.
// Yalnız bu vitrine ait kayıt döner; satırlar + bağlı ürün kimlikleri birlikte gelir.
export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const slug = request.nextUrl.searchParams.get("slug")?.trim() ?? "";
  const islemKimligi = request.nextUrl.searchParams.get("islem")?.trim() ?? "";
  const editTokenGovde = request.nextUrl.searchParams.get("editToken")?.trim() ?? "";
  if (!slug || !islemKimligi) {
    return NextResponse.json({ hata: "Vitrin ve işlem belirtilmedi." }, { status: 422 });
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

  try {
    const admin = getSupabaseAdmin();
    const { data: is } = await admin
      .from("invoice_jobs")
      .select("id,store_id,status,supplier_name,supplier_site,document_adet,document_total,supplier_trace,updated_at")
      .eq("id", islemKimligi)
      .maybeSingle();
    const kayit = is as {
      id?: string;
      store_id?: string;
      status?: string;
      supplier_name?: string;
      supplier_site?: string;
      document_adet?: number | null;
      document_total?: number | null;
      supplier_trace?: Record<string, unknown> | null;
      updated_at?: string;
    } | null;
    if (!kayit?.id || kayit.store_id !== storeId) {
      return NextResponse.json({ hata: "İşlem bulunamadı." }, { status: 404 });
    }
    const { data: satirlar } = await admin
      .from("invoice_job_lines")
      .select("line_index,model,product_name,barcode,variant_name,size_text,qty,unit_price,line_total,confidence,outcome,raw_line")
      .eq("job_id", islemKimligi)
      .order("line_index", { ascending: true });
    const { data: baglar } = await admin
      .from("invoice_product_links")
      .select("line_index,product_id")
      .eq("job_id", islemKimligi);
    const urunIdleri = new Map<number, string>();
    if (Array.isArray(baglar)) {
      for (const b of baglar as Array<{ line_index: number; product_id: string }>) {
        urunIdleri.set(Number(b.line_index), String(b.product_id));
      }
    }
    return NextResponse.json({
      tamam: true,
      islemKimligi: kayit.id,
      durum: kayit.status ?? "inceleme",
      tedarikci: kayit.supplier_name ?? "",
      tedarikciSite: kayit.supplier_site ?? "",
      belgeAdedi: kayit.document_adet ?? null,
      belgeToplami: kayit.document_total ?? null,
      belgeNo: String((kayit.supplier_trace as Record<string, unknown> | null)?.belgeNo ?? ""),
      satirlar: (Array.isArray(satirlar) ? satirlar : []).map((s) => {
        const satir = s as Record<string, unknown>;
        const idx = Number(satir.line_index);
        return { ...satir, urunId: urunIdleri.get(idx) ?? null };
      }),
    });
  } catch (err) {
    console.error("[fatura-islem] okunamadi:", err);
    return NextResponse.json({ hata: "İşlem okunamadı." }, { status: 500 });
  }
}
