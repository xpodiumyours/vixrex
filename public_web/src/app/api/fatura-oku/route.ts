import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";
import { belgeGercegiUyuyorMu } from "@/lib/faturaSatirAyikla";
import { faturaSatirlariniDijitalIzle, sonucOzeti, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { ayniAlisverisAdaylari, belgeParmakIzi, islemKaydet } from "@/lib/faturaIslemKaydi";
import { faturaTaslaklari } from "@/lib/faturaTaslagi";
import { faturayiOku, type GoruSatiri } from "@/lib/faturaGoru";

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
  // Esnaf firmanın sitesini biliyorsa yazar (zorunlu değil): havuzda olmayan
  // veya el yazısı faturada okunamayan site için keşif buradan yürür.
  const siteIpucu = String(form.get("firmaSitesi") ?? "").trim().slice(0, 200);

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

  // Okuma tek yerde: src/lib/faturaGoru.ts. Anahtar yoksa hiç denenmez.
  if (!process.env.OPENROUTER_API_KEY) {
    return NextResponse.json({ hata: "Fatura okuyucu hazır değil." }, { status: 503 });
  }

  // Yarım okuma bir kere olabilir; ısrarla olmaz. Belge kendi toplamını
  // tutturana kadar en fazla DENEME_SINIRI kez okunur. Tutmazsa bile akış
  // durmaz — okunan satırlar uyarıyla taşınır, el yazısı bizi bağlamaz.
  const DENEME_SINIRI = 3;
  const goruntu = `data:${tur};base64,${base64Cevir(bayt)}`;

  try {
    let sonUyum: ReturnType<typeof belgeGercegiUyuyorMu> | null = null;
    let sonSatirlar: HamFaturaSatiri[] = [];
    let sonOzet = { adet: null as number | null, toplam: null as number | null };
    let sonTedarikci = "";
    let sonTedarikciVergiNo = "";
    let sonTedarikciAdres = "";
    let sonTedarikciSite = "";
    let sonBelge = {
      belgeTuru: "",
      belgeNo: "",
      belgeTarihi: "",
      malBedeli: null as number | null,
      kdvTutari: null as number | null,
      indirimTutari: null as number | null,
      odenecekToplam: null as number | null,
    };

    for (let deneme = 1; deneme <= DENEME_SINIRI; deneme++) {
      const okuma = await faturayiOku(goruntu);

      const hamSatirlar: HamFaturaSatiri[] = okuma.satirlar
        .filter((satir: GoruSatiri) => satir.model || satir.ad || satir.barkod)
        .map((satir: GoruSatiri) => ({
          hamSatir: satir.hamSatir,
          model: satir.model,
          ad: satir.ad,
          barkod: satir.barkod,
          varyant: satir.varyant,
          beden: satir.beden,
          marka: satir.marka,
          adet: satir.adet,
          alisBirimFiyat: satir.birimFiyat,
          satirToplam: satir.tutar,
          // Güven, satırın kendi kanıtından gelir: kod/barkod/adet/fiyat.
          guven:
            [satir.model, satir.ad, satir.barkod, satir.beden, satir.adet !== null, satir.birimFiyat !== null]
              .filter(Boolean).length / 6,
        }));

      if (hamSatirlar.length === 0) {
        return NextResponse.json(
          { hata: "Bu fotoğrafta ürün satırı bulunamadı. Daha net bir fotoğraf dene." },
          { status: 422 },
        );
      }

      sonTedarikci = okuma.tedarikci;
      sonTedarikciVergiNo = okuma.tedarikciVergiNo;
      sonTedarikciAdres = okuma.tedarikciAdres;
      sonTedarikciSite = okuma.tedarikciSite;
      sonOzet = { adet: okuma.belgeAdedi, toplam: okuma.belgeToplami };
      sonSatirlar = hamSatirlar;
      sonBelge = {
        belgeTuru: okuma.belgeTuru,
        belgeNo: okuma.belgeNo,
        belgeTarihi: okuma.belgeTarihi,
        malBedeli: okuma.malBedeli,
        kdvTutari: okuma.kdvTutari,
        indirimTutari: okuma.indirimTutari,
        odenecekToplam: okuma.odenecekToplam,
      };
      sonUyum = belgeGercegiUyuyorMu(hamSatirlar, {
        adet: sonOzet.adet,
        toplam: okuma.malBedeli ?? sonOzet.toplam,
      });
      if (sonUyum.uyumlu) break;

      console.warn(
        `[fatura-oku] belge gercegi tutmadi (deneme ${deneme}/${DENEME_SINIRI}): ${sonUyum.sebep}`,
      );
    }

    // Belge gerçeği NOTU (kilitli kapsam): el yazısı ve toptancı notu bizi
    // bağlamaz. Toplam tutmazsa akış DURMAZ — okunan satırlar kaybolmaz,
    // tutmayan kısım uyarı olarak taşınır; her satır kendi kanıtıyla
    // değerlendirilir. Sessizce yanlış stok/fiyat yazılmaz, uydurulmaz.
    const belgeUyarisi = !sonUyum || !sonUyum.uyumlu ? (sonUyum?.sebep ?? null) : null;
    if (belgeUyarisi) {
      console.warn(`[fatura-oku] belge uyumsuzlugu not edildi, akis suruyor: ${belgeUyarisi}`);
    }

    // Esnafın site ipucu: OCR siteyi okuyamadıysa keşif buradan yürür.
    const etkinSite = sonTedarikciSite || siteIpucu;

    const { satirlar, tedarikciIz } = await faturaSatirlariniDijitalIzle(
      sonSatirlar,
      sonTedarikci,
      etkinSite,
      { tedarikciKimligi: { vergiNo: sonTedarikciVergiNo, adres: sonTedarikciAdres } },
    );
    const eslesenSayisi = satirlar.filter((satir) => satir.katalog !== null).length;

    const kayitGirdisi = {
      slug: ownerSlug,
      parmakIzi: belgeParmakIzi(bayt),
      belgeAdedi: sonOzet.adet,
      belgeToplami: sonOzet.toplam,
      tedarikci: sonTedarikci,
      tedarikciVergiNo: sonTedarikciVergiNo,
      tedarikciAdres: sonTedarikciAdres,
      tedarikciSite: etkinSite,
      tedarikciIz,
      satirlar,
      ...sonBelge,
    };
    const islemKimligi = await islemKaydet(kayitGirdisi);
    const ayniAlisveris = islemKimligi
      ? await ayniAlisverisAdaylari({ slug: ownerSlug, islemKimligi, girdi: kayitGirdisi })
      : [];

    return NextResponse.json({
      tamam: true,
      satirlar,
      belgeToplami: sonOzet.toplam,
      belgeAdedi: sonOzet.adet,
      // Toplam tutmadıysa akış durmaz; uyarı esnafa açıkça gösterilir.
      ...(belgeUyarisi ? { belgeUyarisi } : {}),
      tedarikci: sonTedarikci,
      tedarikciVergiNo: sonTedarikciVergiNo,
      tedarikciAdres: sonTedarikciAdres,
      tedarikciSite: etkinSite,
      tedarikciDijitalIz: tedarikciIz,
      katalogEslesmesi: eslesenSayisi,
      sonucOzeti: sonucOzeti(satirlar),
      taslaklar: faturaTaslaklari(satirlar, islemKimligi),
      islemKimligi,
      belge: sonBelge,
      ayniAlisveris,
    });
  } catch (err) {
    const kod = err instanceof Error ? err.message : "unknown";
    console.error("[fatura-oku] failed:", kod);

    // Bakiye bitmesi "tekrar dene" ile geçiştirilmez; esnaf boşuna uğraşmasın.
    if (kod === "OKUYUCU_BAKIYE_BITTI") {
      return NextResponse.json(
        { hata: "Fatura okuyucu şu an kullanılamıyor. Biz ilgileniyoruz." },
        { status: 503 },
      );
    }
    if (kod === "FOTOGRAFTA_YAZI_YOK") {
      return NextResponse.json(
        { hata: "Bu fotoğrafta yazı bulunamadı. Daha net bir fotoğraf dene." },
        { status: 422 },
      );
    }
    return NextResponse.json({ hata: "Fatura şu an okunamadı. Tekrar dene." }, { status: 500 });
  }
}
