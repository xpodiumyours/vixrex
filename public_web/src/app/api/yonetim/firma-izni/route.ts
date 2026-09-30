import { timingSafeEqual } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { cevapKaydet, kapsamGecerliMi, talepGonderildiIsaretle } from "@/lib/firmaIzni";

export const dynamic = "force-dynamic";

const KIMLIK = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const TARIH = /^\d{4}-\d{2}-\d{2}$/;

function anahtarDogruMu(gelen: string, beklenen: string): boolean {
  const a = Buffer.from(gelen);
  const b = Buffer.from(beklenen);
  return a.length === b.length && timingSafeEqual(a, b);
}

export async function POST(request: NextRequest) {
  const beklenen = (process.env.FIRMA_IZNI_YONETICI_ANAHTARI ?? "").trim();
  if (!beklenen) {
    return NextResponse.json({ hata: "Yönetici ucu kapalı." }, { status: 503 });
  }
  const gelen = (request.headers.get("x-vixrex-yonetici") ?? "").trim();
  if (!gelen || !anahtarDogruMu(gelen, beklenen)) {
    return NextResponse.json({ hata: "Yetkisiz." }, { status: 401 });
  }

  let govde: Record<string, unknown>;
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const admin = getSupabaseAdmin();

  if (govde.islem === "gonderildi") {
    const talepKimligi = typeof govde.talepKimligi === "string" ? govde.talepKimligi.trim() : "";
    if (!KIMLIK.test(talepKimligi)) {
      return NextResponse.json({ hata: "Talep kimliği geçersiz." }, { status: 422 });
    }
    const tamam = await talepGonderildiIsaretle(admin, { talepKimligi });
    return tamam
      ? NextResponse.json({ tamam: true })
      : NextResponse.json({ hata: "Talep güncellenemedi." }, { status: 500 });
  }

  if (govde.islem === "cevap") {
    const firmaAnahtari = typeof govde.firmaAnahtari === "string" ? govde.firmaAnahtari.trim() : "";
    const durum = govde.durum;
    const kapsam = govde.kapsam ?? "data_and_images";
    const gecerlilik = typeof govde.gecerlilik === "string" && govde.gecerlilik ? govde.gecerlilik : null;
    const dogrulayan = typeof govde.dogrulayan === "string" ? govde.dogrulayan.trim() : "";

    if (
      !firmaAnahtari ||
      !dogrulayan ||
      !kapsamGecerliMi(kapsam) ||
      (durum !== "izin_verildi" && durum !== "reddedildi" && durum !== "geri_cekildi") ||
      (gecerlilik !== null && !TARIH.test(gecerlilik))
    ) {
      return NextResponse.json({ hata: "Cevap bilgisi eksik ya da geçersiz." }, { status: 422 });
    }

    const sonuc = await cevapKaydet(admin, {
      firmaAnahtari,
      firmaAdi: typeof govde.firmaAdi === "string" ? govde.firmaAdi : "",
      kapsam,
      durum,
      gecerlilik,
      not: typeof govde.not === "string" ? govde.not : "",
      dogrulayan,
    });
    return sonuc.tamam
      ? NextResponse.json({ tamam: true, gizlenen: sonuc.gizlenen })
      : NextResponse.json({ hata: "Cevap kaydedilemedi." }, { status: 500 });
  }

  return NextResponse.json({ hata: "İşlem geçersiz." }, { status: 422 });
}
