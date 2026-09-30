import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import {
  belgeGercegiUyuyorMu,
  belgeOzetiniAyikla,
  hamMetniSatirlaraAyir,
  tedarikciAdiniAyikla,
} from "@/lib/faturaSatirAyikla";
import { faturaSatirlariniDijitalIzle, sonucOzeti, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { belgeParmakIzi, islemKaydet } from "@/lib/faturaIslemKaydi";
import { faturaTaslaklari } from "@/lib/faturaTaslagi";

// Ücretli okuyucu olmadan fatura girişi.
//
// Esnaf satırları yazar ya da yapıştırır; metin AYNI zincirden geçer:
// deterministik satır ayırma → katalog eşleştirme → kalıcı işlem kaydı →
// kart taslağı → aynı onay/yayın kapıları. Okuyucu anahtarı gerekmez,
// ücretli çağrı yapılmaz. Esnafın kendi bilgisi taşınır; tahmin üretilmez.
export const dynamic = "force-dynamic";
export const maxDuration = 60;

const VITRIN_BASINA_LIMIT = 20;
const PENCERE_SANIYE = 3600;
const MAKS_METIN = 20000;
const MAKS_SATIR = 100;

interface MetinSatiri {
  hamSatir?: unknown;
  model?: unknown;
  ad?: unknown;
  barkod?: unknown;
  varyant?: unknown;
  beden?: unknown;
  adet?: unknown;
  alisBirimFiyat?: unknown;
  satirToplam?: unknown;
}

function metinDeger(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

function sayiDeger(deger: unknown): number | null {
  if (typeof deger === "number" && Number.isFinite(deger)) return deger;
  if (typeof deger === "string" && deger.trim()) {
    const n = Number(deger.trim().replace(/\s/g, "").replace(",", "."));
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function satirGuveni(satir: { model: string; ad: string; barkod: string; beden: string; adet: number | null; alisBirimFiyat: number | null }): number {
  return (
    [satir.model, satir.ad, satir.barkod, satir.beden, satir.adet !== null, satir.alisBirimFiyat !== null].filter(
      Boolean,
    ).length / 6
  );
}

export async function POST(request: NextRequest) {
  let govde: {
    slug?: unknown;
    editToken?: unknown;
    metin?: unknown;
    satirlar?: unknown;
    tedarikci?: unknown;
    tedarikciSite?: unknown;
    firmaSitesi?: unknown;
  };
  try {
    govde = await request.json();
  } catch {
    return NextResponse.json({ hata: "Geçersiz istek." }, { status: 400 });
  }

  const slug = metinDeger(govde.slug);
  const editTokenGovde = metinDeger(govde.editToken);
  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }

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
    p_client_key: `fatura_metin:${ownerSlug}`,
    p_max_requests: VITRIN_BASINA_LIMIT,
    p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limit && !limit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla denedin. ${limit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  // İki giriş: yapıştırılan metin ya da tek tek yazılan satırlar.
  const metin = metinDeger(govde.metin).slice(0, MAKS_METIN);
  const hamListe = Array.isArray(govde.satirlar) ? (govde.satirlar as MetinSatiri[]).slice(0, MAKS_SATIR) : [];

  let hamSatirlar: HamFaturaSatiri[] = [];
  if (metin) {
    hamSatirlar = hamMetniSatirlaraAyir(metin);
  } else if (hamListe.length > 0) {
    hamSatirlar = hamListe.map((girdi) => {
      const satir = {
        hamSatir: metinDeger(girdi.hamSatir),
        model: metinDeger(girdi.model),
        ad: metinDeger(girdi.ad),
        barkod: metinDeger(girdi.barkod),
        varyant: metinDeger(girdi.varyant),
        beden: metinDeger(girdi.beden),
        adet: sayiDeger(girdi.adet),
        alisBirimFiyat: sayiDeger(girdi.alisBirimFiyat),
        satirToplam: sayiDeger(girdi.satirToplam),
        guven: 0,
      };
      return { ...satir, guven: satirGuveni(satir) };
    }).filter((satir) => satir.model || satir.ad || satir.barkod);
  }

  if (hamSatirlar.length === 0) {
    return NextResponse.json(
      { hata: "Ürün satırı bulunamadı. Model, ürün adı ya da barkod yaz." },
      { status: 422 },
    );
  }

  const tedarikci = metinDeger(govde.tedarikci) || (metin ? tedarikciAdiniAyikla(metin) : "");
  const siteIpucu = metinDeger(govde.firmaSitesi).slice(0, 200);
  const tedarikciSite = metinDeger(govde.tedarikciSite).slice(0, 200) || siteIpucu;
  const ozet = metin ? belgeOzetiniAyikla(metin) : { adet: null, toplam: null };
  const uyum = belgeGercegiUyuyorMu(hamSatirlar, ozet);
  const belgeUyarisi = uyum.uyumlu ? null : uyum.sebep;

  const { satirlar, tedarikciIz } = await faturaSatirlariniDijitalIzle(hamSatirlar, tedarikci, tedarikciSite);
  const eslesenSayisi = satirlar.filter((satir) => satir.katalog !== null).length;

  const kanonik = metin || JSON.stringify(hamListe.map((g) => [g.model, g.ad, g.barkod, g.adet, g.alisBirimFiyat]));
  const islemKimligi = await islemKaydet({
    slug: ownerSlug,
    parmakIzi: belgeParmakIzi(Buffer.from(kanonik, "utf8")),
    belgeAdedi: ozet.adet,
    belgeToplami: ozet.toplam,
    tedarikci,
    tedarikciVergiNo: "",
    tedarikciAdres: "",
    tedarikciSite,
    tedarikciIz,
    satirlar,
    belgeTuru: null,
    belgeNo: null,
    belgeTarihi: null,
    kdvToplam: null,
  });

  return NextResponse.json({
    tamam: true,
    kaynak: "metin",
    satirlar,
    belgeToplami: ozet.toplam,
    belgeAdedi: ozet.adet,
    belgeTuru: null,
    belgeNo: null,
    belgeTarihi: null,
    kdvToplam: null,
    ...(belgeUyarisi ? { belgeUyarisi } : {}),
    tedarikci,
    tedarikciSite,
    tedarikciDijitalIz: tedarikciIz,
    katalogEslesmesi: eslesenSayisi,
    sonucOzeti: sonucOzeti(satirlar),
    taslaklar: faturaTaslaklari(satirlar, islemKimligi),
    islemKimligi,
  });
}
