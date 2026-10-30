import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { sahipYetkisi } from "@/lib/faturaYetki";
import { islemiYukle } from "@/lib/faturaIslemOku";
import { faturaTaslakYanitiniHazirla } from "@/lib/faturaOtomatikTaslakKaydi";
import { vitrinOnbelleginiYenile } from "@/lib/vitrinYayinDogrula";

export const dynamic = "force-dynamic";
export const maxDuration = 300;

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Barkodsuz fatura satırı vitrindeki bir kartla "aynı ürün olabilir" görünüyorsa
 * kart sessizce açılmaz; esnafın cevabı bu uçtan yazılır.
 *
 * birlestir: satır var olan karta bağlanır, stok toplanır.
 * ayri     : satır normal yoldan kendi kartını açar.
 *
 * Cevap yazıldıktan sonra fatura yeniden işlenir ve güncel hâli döndürülür.
 */
export async function POST(request: NextRequest) {
  let govde: {
    slug?: unknown;
    islemKimligi?: unknown;
    satirSirasi?: unknown;
    karar?: unknown;
    editToken?: unknown;
  };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const islemKimligi = typeof govde.islemKimligi === "string" ? govde.islemKimligi.trim() : "";
  const karar = govde.karar === "birlestir" || govde.karar === "ayri" ? govde.karar : "";
  const sira = govde.satirSirasi;

  if (!KIMLIK.test(islemKimligi)) {
    return NextResponse.json({ hata: "İşlem kimliği geçersiz." }, { status: 422 });
  }
  if (typeof sira !== "number" || !Number.isInteger(sira) || sira < 0) {
    return NextResponse.json({ hata: "Satır bilgisi geçersiz." }, { status: 422 });
  }
  if (!karar) {
    return NextResponse.json({ hata: "Karar belirtilmedi." }, { status: 422 });
  }

  const editToken =
    (request.headers.get("x-vixrex-edit-token") ?? "").trim() ||
    (typeof govde.editToken === "string" ? govde.editToken.trim() : "");

  const yetki = await sahipYetkisi(slug, editToken);
  if (!yetki.tamam) return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });

  const admin = getSupabaseAdmin();
  const is = await admin
    .from("invoice_jobs")
    .select("id")
    .eq("id", islemKimligi)
    .eq("store_id", yetki.storeId)
    .maybeSingle();
  if (!is.data?.id) {
    return NextResponse.json({ hata: "İşlem bulunamadı." }, { status: 404 });
  }

  const satir = await admin
    .from("invoice_job_lines")
    .select("id,product_id,merge_candidate_product_id")
    .eq("job_id", islemKimligi)
    .eq("line_index", sira)
    .maybeSingle();
  if (!satir.data?.id) {
    return NextResponse.json({ hata: "Satır bulunamadı." }, { status: 404 });
  }
  if (satir.data.product_id) {
    return NextResponse.json(
      { hata: "Bu satır zaten bir karta bağlı." },
      { status: 409, headers: { "Cache-Control": "private, no-store" } },
    );
  }

  const adayId = satir.data.merge_candidate_product_id
    ? String(satir.data.merge_candidate_product_id)
    : "";
  if (karar === "birlestir" && !adayId) {
    return NextResponse.json({ hata: "Birleştirilecek kart bulunamadı." }, { status: 404 });
  }

  const yazma = await admin
    .from("invoice_job_lines")
    .update(
      karar === "birlestir"
        ? { merge_decision: "birlestir", merge_candidate_product_id: adayId }
        : { merge_decision: "ayri", merge_candidate_product_id: null },
    )
    .eq("id", satir.data.id);
  if (yazma.error) {
    return NextResponse.json({ hata: "Karar kaydedilemedi." }, { status: 500 });
  }

  const islem = await islemiYukle(admin, yetki.storeId, islemKimligi);
  if (!islem) {
    return NextResponse.json({ hata: "İşlem bulunamadı." }, { status: 404 });
  }

  const sonuc = await faturaTaslakYanitiniHazirla(admin, yetki.storeId, yetki.slug, islem);
  if ((sonuc.satirlar as Array<{ urunId?: string | null }> | undefined)?.some((kayit) => kayit.urunId)) {
    vitrinOnbelleginiYenile(yetki.slug);
  }
  return NextResponse.json(sonuc, {
    status: sonuc.hazirlaniyor ? 202 : 200,
    headers: { "Cache-Control": "private, no-store" },
  });
}
