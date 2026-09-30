import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { sahipYetkisi } from "@/lib/faturaYetki";
import {
  izinOzetiOku,
  kapsamGecerliMi,
  talepGonderildiIsaretle,
  talepOlustur,
} from "@/lib/firmaIzni";

export const dynamic = "force-dynamic";

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function jetonu(request: NextRequest, govde?: { editToken?: unknown }): string {
  return (
    (request.headers.get("x-vixrex-edit-token") ?? "").trim() ||
    (typeof govde?.editToken === "string" ? govde.editToken.trim() : "")
  );
}

export async function GET(request: NextRequest) {
  const slug = (request.nextUrl.searchParams.get("slug") ?? "").trim();
  const islemKimligi = (request.nextUrl.searchParams.get("islemKimligi") ?? "").trim();
  const kapsam = request.nextUrl.searchParams.get("kapsam") ?? "data_and_images";

  if (!KIMLIK.test(islemKimligi) || !kapsamGecerliMi(kapsam)) {
    return NextResponse.json({ hata: "İşlem belirtilmedi." }, { status: 422 });
  }
  const yetki = await sahipYetkisi(slug, jetonu(request));
  if (!yetki.tamam) return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });

  const ozet = await izinOzetiOku(getSupabaseAdmin(), yetki.storeId, islemKimligi, kapsam);
  if (!ozet) return NextResponse.json({ hata: "Firma bilgisi bulunamadı." }, { status: 404 });
  return NextResponse.json({ tamam: true, ...ozet });
}

export async function POST(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const islemKimligi = typeof govde.islemKimligi === "string" ? govde.islemKimligi.trim() : "";
  const secim = govde.secim;
  const kapsam = govde.kapsam ?? "data_and_images";

  if (!KIMLIK.test(islemKimligi) || (secim !== "owner" && secim !== "vixrex") || !kapsamGecerliMi(kapsam)) {
    return NextResponse.json({ hata: "Talep bilgisi geçersiz." }, { status: 422 });
  }
  const yetki = await sahipYetkisi(slug, jetonu(request, govde));
  if (!yetki.tamam) return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });

  const admin = getSupabaseAdmin();
  const magaza = await admin.from("stores").select("name").eq("id", yetki.storeId).maybeSingle();

  const sonuc = await talepOlustur(admin, {
    storeId: yetki.storeId,
    magazaAdi: String(magaza.data?.name ?? ""),
    magazaSlug: yetki.slug,
    islemKimligi,
    secim,
    kapsam,
    siteOrigin: request.nextUrl.origin,
  });

  if (sonuc.durum === "hata") return NextResponse.json({ hata: sonuc.hata }, { status: 422 });
  return NextResponse.json({ tamam: true, sonuc: sonuc.durum, ...sonuc.ozet });
}

export async function PATCH(request: NextRequest) {
  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const talepKimligi = typeof govde.talepKimligi === "string" ? govde.talepKimligi.trim() : "";
  if (!KIMLIK.test(talepKimligi) || govde.islem !== "gonderildi") {
    return NextResponse.json({ hata: "İşlem geçersiz." }, { status: 422 });
  }
  const yetki = await sahipYetkisi(slug, jetonu(request, govde));
  if (!yetki.tamam) return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });

  const kaydedildi = await talepGonderildiIsaretle(getSupabaseAdmin(), {
    talepKimligi,
    storeId: yetki.storeId,
    isteyen: "owner",
  });
  if (!kaydedildi) return NextResponse.json({ hata: "Talep güncellenemedi." }, { status: 500 });
  return NextResponse.json({ tamam: true });
}
