import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";
import {
  belgeGercegiUyuyorMu,
  belgeOzetiniAyikla,
  hamMetniSatirlaraAyir,
  tedarikciAdiniAyikla,
  urunSatirlari,
} from "@/lib/faturaSatirAyikla";
import { faturaSatirlariniEslestir } from "@/lib/faturaEslestir";

// Vixrex'in TEK fatura okuma ucu.
//
// Telefon kamerası VE web'den yüklenen fotoğraf AYNI bu uçtan geçer — iki
// ayrı "okuma beyni" olmaz (bkz. 2026-09-26 mimari düzeltmesi: önceden web
// tarafı ayrı bir OpenAI zinciri kullanıyordu, anahtar yoktu, hiç çalışmadı).
//
// Zincir: görüntü → vixrex-fatura-goru (Kilo, ücretsiz, anahtarsız) → ham
// metin → faturaSatirAyikla.ts (deterministik satır ayırma) →
// faturaEslestir.ts (gerçek üretici kataloğu). Hiçbir aşama ürün oluşturmaz
// veya yayınlamaz — o /api/products/batch üzerinden, esnaf onayıyla olur.
//
// Kimlik doğrulama: tarayıcı çerezle (verifyOwnerSession), Flutter
// store edit_token ile (verifyStoreEditToken) — /api/fatura-eslestir ile
// aynı desen, ikisi de bu tek ucu çağırabilir.

export const dynamic = "force-dynamic";
export const maxDuration = 60;

const MAKS_BAYT = 5 * 1024 * 1024;
const VITRIN_BASINA_LIMIT = 20;
const PENCERE_SANIYE = 3600;

const IZINLI_TURLER = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"],
]);

function gercekTur(bayt: Uint8Array): string | null {
  if (bayt.length < 12) return null;
  if (bayt[0] === 0xff && bayt[1] === 0xd8 && bayt[2] === 0xff) return "image/jpeg";
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (png.every((b, i) => bayt[i] === b)) return "image/png";
  const riff = [0x52, 0x49, 0x46, 0x46];
  const webp = [0x57, 0x45, 0x42, 0x50];
  if (riff.every((b, i) => bayt[i] === b) && webp.every((b, i) => bayt[8 + i] === b)) {
    return "image/webp";
  }
  return null;
}

function base64Cevir(bayt: Uint8Array): string {
  return Buffer.from(bayt).toString("base64");
}

export async function POST(request: NextRequest) {
  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = String(form.get("slug") ?? "").trim();
  const dosya = form.get("dosya");
  const editTokenGovde = String(form.get("editToken") ?? "").trim();

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }
  if (!(dosya instanceof File)) {
    return NextResponse.json({ hata: "Fatura fotoğrafı bulunamadı." }, { status: 400 });
  }

  // İki giriş yolu: tarayıcı çerezle, Flutter kendi edit_token'ıyla
  // (/api/fatura-eslestir ile birebir aynı desen).
  const cookieStore = await cookies();
  const cerezliOturum = verifyOwnerSession(cookieStore.get(OWNER_SESSION_COOKIE)?.value, slug);

  let ownerSlug: string;
  if (cerezliOturum) {
    ownerSlug = cerezliOturum.slug;
  } else if (editTokenGovde) {
    try {
      const store = await verifyStoreEditToken(slug, editTokenGovde);
      ownerSlug = store.slug;
    } catch {
      return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
    }
  } else {
    return NextResponse.json({ hata: "Oturumun geçersiz veya süresi dolmuş." }, { status: 401 });
  }

  const admin = getSupabaseAdmin();

  const { data: limitRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_oku:${ownerSlug}`,
    p_max_requests: VITRIN_BASINA_LIMIT,
    p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limit && !limit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla fatura okudun. ${limit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  const clientKey = fingerprintClient(getClientIp(request));
  const { data: ipRows } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_oku_ip:${clientKey}`,
    p_max_requests: 40,
    p_window_seconds: 86400,
  });
  const ipLimit = Array.isArray(ipRows) ? ipRows[0] : ipRows;
  if (ipLimit && !ipLimit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla fatura okudun. ${ipLimit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  if (dosya.size > MAKS_BAYT) {
    return NextResponse.json({ hata: "Fotoğraf çok büyük. En fazla 5 MB." }, { status: 413 });
  }

  const bayt = new Uint8Array(await dosya.arrayBuffer());
  if (bayt.length > MAKS_BAYT) {
    return NextResponse.json({ hata: "Fotoğraf çok büyük. En fazla 5 MB." }, { status: 413 });
  }

  const tur = gercekTur(bayt);
  if (!tur || !IZINLI_TURLER.has(tur)) {
    return NextResponse.json(
      { hata: "Yalnız JPG, PNG veya WebP yükleyebilirsin." },
      { status: 415 },
    );
  }

  const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !serviceRoleKey) {
    return NextResponse.json({ hata: "Fatura okuyucu hazır değil." }, { status: 503 });
  }

  // Yarım okuma bir kere olabilir; ısrarla olmaz. Belge kendi toplamını
  // tutturana kadar en fazla DENEME_SINIRI kez tekrar okunur. Tutmazsa
  // akış durur — eksik okunmuş satırdan ürün kartı üretilmez.
  const DENEME_SINIRI = 3;
  const goruntu = `data:${tur};base64,${base64Cevir(bayt)}`;

  try {
    let sonUyum: ReturnType<typeof belgeGercegiUyuyorMu> | null = null;
    let sonSatirlar: ReturnType<typeof urunSatirlari> = [];
    let sonOzet = { adet: null as number | null, toplam: null as number | null };
    let sonTedarikci = "";

    for (let deneme = 1; deneme <= DENEME_SINIRI; deneme++) {
      const cevap = await fetch(`${supabaseUrl}/functions/v1/vixrex-fatura-goru`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ goruntu }),
      });

      const govde = await cevap.json().catch(() => null);
      if (!cevap.ok || !govde || typeof govde !== "object") {
        const mesaj =
          govde && typeof govde === "object" && typeof (govde as { hata?: unknown }).hata === "string"
            ? (govde as { hata: string }).hata
            : "Fatura şu an okunamadı. Tekrar dene.";
        return NextResponse.json({ hata: mesaj }, { status: cevap.ok ? 502 : cevap.status });
      }

      const yazi =
        typeof (govde as { yazi?: unknown }).yazi === "string" ? (govde as { yazi: string }).yazi : "";
      if (!yazi.trim()) {
        return NextResponse.json(
          { hata: "Bu fotoğrafta yazı bulunamadı. Daha net bir fotoğraf dene." },
          { status: 422 },
        );
      }

      const hamSatirlar = urunSatirlari(hamMetniSatirlaraAyir(yazi));
      if (hamSatirlar.length === 0) {
        return NextResponse.json(
          { hata: "Bu fotoğrafta ürün satırı bulunamadı. Daha net bir fotoğraf dene." },
          { status: 422 },
        );
      }

      sonTedarikci = tedarikciAdiniAyikla(yazi);
      sonOzet = belgeOzetiniAyikla(yazi);
      sonSatirlar = hamSatirlar;
      sonUyum = belgeGercegiUyuyorMu(hamSatirlar, sonOzet);
      if (sonUyum.uyumlu) break;

      console.warn(
        `[fatura-oku] belge gercegi tutmadi (deneme ${deneme}/${DENEME_SINIRI}): ${sonUyum.sebep}`,
      );
    }

    // Belge gerçeği kapısı: tutmadıysa ürün üretilmez. Esnafa neyin
    // tutmadığı açıkça söylenir; sessizce yanlış stok/fiyat yazılmaz.
    if (!sonUyum || !sonUyum.uyumlu) {
      return NextResponse.json(
        {
          hata: `${sonUyum?.sebep ?? "Fatura tam okunamadı."} Daha net bir fotoğraf dene.`,
          belgeAdedi: sonUyum?.belgeAdedi ?? null,
          belgeToplami: sonUyum?.belgeToplami ?? null,
          okunanAdet: sonUyum?.okunanAdet ?? 0,
          okunanToplam: sonUyum?.okunanToplam ?? 0,
        },
        { status: 422 },
      );
    }

    const satirlar = faturaSatirlariniEslestir(sonSatirlar, sonTedarikci);
    const eslesenSayisi = satirlar.filter((satir) => satir.katalog !== null).length;

    return NextResponse.json({
      tamam: true,
      satirlar,
      belgeToplami: sonOzet.toplam,
      belgeAdedi: sonOzet.adet,
      tedarikci: sonTedarikci,
      katalogEslesmesi: eslesenSayisi,
    });
  } catch (err) {
    console.error("[fatura-oku] failed:", err instanceof Error ? err.message : "unknown");
    return NextResponse.json({ hata: "Fatura şu an okunamadı. Tekrar dene." }, { status: 500 });
  }
}
