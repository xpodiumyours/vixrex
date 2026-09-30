import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { sahipYetkisi } from "@/lib/faturaYetki";
import {
  islemiYukle,
  islemleriListele,
  islemYaniti,
  urundenIslemBul,
  sahipDurumlariniKaydet,
  sahipDurumunuTemizle,
  type SahipDurumu,
} from "@/lib/faturaIslemOku";

export const dynamic = "force-dynamic";

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EN_FAZLA_SATIR = 200;

export async function GET(request: NextRequest) {
  const slug = (request.nextUrl.searchParams.get("slug") ?? "").trim();
  const islemKimligi = (request.nextUrl.searchParams.get("islemKimligi") ?? "").trim();
  const editToken = (request.headers.get("x-vixrex-edit-token") ?? "").trim();

  const yetki = await sahipYetkisi(slug, editToken);
  if (!yetki.tamam) return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });

  const admin = getSupabaseAdmin();

  const urunId = (request.nextUrl.searchParams.get("urunId") ?? "").trim();
  if (urunId) {
    if (!KIMLIK.test(urunId)) {
      return NextResponse.json({ hata: "Ürün kimliği geçersiz." }, { status: 422 });
    }
    const bulunan = await urundenIslemBul(admin, yetki.storeId, urunId);
    if (!bulunan) {
      return NextResponse.json({ hata: "Bu ürün bir faturadan gelmedi." }, { status: 404 });
    }
    return NextResponse.json({ tamam: true, islemKimligi: bulunan });
  }

  if (!islemKimligi) {
    const islemler = await islemleriListele(admin, yetki.storeId);
    return NextResponse.json({ tamam: true, islemler });
  }

  if (!KIMLIK.test(islemKimligi)) {
    return NextResponse.json({ hata: "İşlem kimliği geçersiz." }, { status: 422 });
  }
  const islem = await islemiYukle(admin, yetki.storeId, islemKimligi);
  if (!islem) return NextResponse.json({ hata: "İşlem bulunamadı." }, { status: 404 });

  return NextResponse.json(islemYaniti(islem));
}

export async function PUT(request: NextRequest) {
  let govde: {
    slug?: unknown;
    editToken?: unknown;
    islemKimligi?: unknown;
    satirlar?: unknown;
  };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  const islemKimligi = typeof govde.islemKimligi === "string" ? govde.islemKimligi.trim() : "";
  const editToken =
    (request.headers.get("x-vixrex-edit-token") ?? "").trim() ||
    (typeof govde.editToken === "string" ? govde.editToken.trim() : "");

  if (!KIMLIK.test(islemKimligi)) {
    return NextResponse.json({ hata: "İşlem kimliği geçersiz." }, { status: 422 });
  }
  if (!Array.isArray(govde.satirlar) || govde.satirlar.length === 0) {
    return NextResponse.json({ hata: "Kaydedilecek satır yok." }, { status: 422 });
  }
  if (govde.satirlar.length > EN_FAZLA_SATIR) {
    return NextResponse.json({ hata: "Tek seferde çok fazla satır." }, { status: 422 });
  }

  const guncellemeler: Array<{ satirSirasi: number; sahipDurumu: SahipDurumu }> = [];
  for (const ham of govde.satirlar) {
    const satir = (ham ?? {}) as { satirSirasi?: unknown; sahipDurumu?: unknown };
    const sahipDurumu = sahipDurumunuTemizle(satir.sahipDurumu);
    if (
      typeof satir.satirSirasi !== "number" ||
      !Number.isInteger(satir.satirSirasi) ||
      satir.satirSirasi < 0 ||
      !sahipDurumu
    ) {
      return NextResponse.json({ hata: "Satır bilgisi geçersiz." }, { status: 422 });
    }
    guncellemeler.push({ satirSirasi: satir.satirSirasi, sahipDurumu });
  }

  const yetki = await sahipYetkisi(slug, editToken);
  if (!yetki.tamam) return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });

  const admin = getSupabaseAdmin();
  const kaydedildi = await sahipDurumlariniKaydet(admin, yetki.storeId, islemKimligi, guncellemeler);
  if (!kaydedildi) {
    return NextResponse.json({ hata: "İşlem bulunamadı ya da kaydedilemedi." }, { status: 404 });
  }
  return NextResponse.json({ tamam: true, kaydedilen: guncellemeler.length });
}
