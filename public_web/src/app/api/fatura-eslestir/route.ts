import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";
import { faturaSatirlariniEslestir, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { verifyStoreEditToken } from "@/lib/instagramServer";

// Fatura satırlarını üretici kataloğuyla eşleştirir.
//
// Bu uç nokta fotoğrafı OKUMAZ — satırları biri (telefon uygulamasının
// kendi OCR'ı, Başak, ya da ileride tarayıcı) zaten çıkarmış olarak
// gönderir. Görevi tek: her satırı gerçek üretici kataloğuna bağlamak.
//
// Hiçbir ürün oluşturmaz, hiçbir şey yayınlamaz. Kart oluşturma ve yayın
// kapısı /api/products/batch üzerinden, esnaf onayı ve fiyatıyla olur.

export const dynamic = "force-dynamic";
export const maxDuration = 30;

const VITRIN_BASINA_LIMIT = 60;
const PENCERE_SANIYE = 3600;
const MAKS_SATIR = 200;

function satirTemizle(ham: unknown): HamFaturaSatiri | null {
  const satir = (ham ?? {}) as Record<string, unknown>;
  const metin = (v: unknown, maks: number) =>
    typeof v === "string" ? v.trim().slice(0, maks) : "";
  const sayi = (v: unknown) => {
    const n = typeof v === "number" ? v : Number(v);
    return Number.isFinite(n) && n > 0 ? n : null;
  };

  const model = metin(satir.model, 60);
  const ad = metin(satir.ad, 200);
  if (!model && !ad) return null;

  return {
    model,
    ad,
    barkod: metin(satir.barkod, 20).replace(/\D/g, ""),
    varyant: metin(satir.varyant, 60),
    beden: metin(satir.beden, 40),
    adet: sayi(satir.adet),
    alisBirimFiyat: sayi(satir.alisBirimFiyat),
    satirToplam: sayi(satir.satirToplam),
    guven: typeof satir.guven === "number" ? Math.min(1, Math.max(0, satir.guven)) : 0.5,
  };
}

export async function POST(request: NextRequest) {
  let govde: { slug?: unknown; satirlar?: unknown; editToken?: unknown; tedarikci?: unknown };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = typeof govde.slug === "string" ? govde.slug.trim() : "";
  if (!slug) return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });

  if (!Array.isArray(govde.satirlar) || govde.satirlar.length === 0) {
    return NextResponse.json({ hata: "En az bir satır gerekli." }, { status: 422 });
  }

  // İki giriş yolu var: tarayıcıdaki esnaf paneli çerezle gelir (verifyOwnerSession),
  // Flutter uygulaması çerez taşımaz — kendi edit_token'ını gövdede gönderir
  // (Instagram uçlarıyla aynı desen: verifyStoreEditToken).
  const cookieStore = await cookies();
  const cerezliOturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);

  let ownerSlug: string;
  if (cerezliOturum) {
    ownerSlug = cerezliOturum.slug;
  } else {
    const editToken = typeof govde.editToken === "string" ? govde.editToken.trim() : "";
    if (!editToken) {
      return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
    }
    try {
      const store = await verifyStoreEditToken(slug, editToken);
      ownerSlug = store.slug;
    } catch {
      return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
    }
  }

  const admin = getSupabaseAdmin();

  const { data: limitRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_eslestir:${ownerSlug}`,
    p_max_requests: VITRIN_BASINA_LIMIT,
    p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limit && !limit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla istek. ${limit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  const clientKey = fingerprintClient(getClientIp(request));
  const { data: ipRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_eslestir_ip:${clientKey}`,
    p_max_requests: 200,
    p_window_seconds: 86400,
  });
  const ipLimit = Array.isArray(ipRows) ? ipRows[0] : ipRows;
  if (ipLimit && !ipLimit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla istek. ${ipLimit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  const hamSatirlar = (govde.satirlar as unknown[]).slice(0, MAKS_SATIR);
  const temizSatirlar = hamSatirlar.map(satirTemizle).filter((s): s is HamFaturaSatiri => s !== null);

  if (temizSatirlar.length === 0) {
    return NextResponse.json({ hata: "Geçerli satır bulunamadı." }, { status: 422 });
  }

  // Tedarikçi adı isteğe bağlıdır: fotoğrafı kim okursa okusun (telefon,
  // Başak, tarayıcı) biliyorsa gönderir; bilmiyorsa firma dağılımına bakılır.
  const tedarikci = typeof govde.tedarikci === "string" ? govde.tedarikci.trim() : "";
  const eslesenSatirlar = faturaSatirlariniEslestir(temizSatirlar, tedarikci);
  const eslesenSayisi = eslesenSatirlar.filter((s) => s.katalog !== null).length;

  return NextResponse.json({
    tamam: true,
    satirlar: eslesenSatirlar,
    toplamSatir: eslesenSatirlar.length,
    katalogEslesmesi: eslesenSayisi,
  });
}
