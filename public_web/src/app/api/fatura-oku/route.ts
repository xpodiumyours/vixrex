import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import { faturaSatiriniAktar } from "@/lib/faturaPresetAktarimi";
import { belgeParmakIzi, islemKaydet } from "@/lib/faturaIslemKaydi";
import { faturaTaslaklari } from "@/lib/faturaTaslagi";
import { faturayiOku, type GoruSonucu } from "@/lib/faturaGoru";
import { islemiYukle, islemYaniti, parmakIzindenIslemBul } from "@/lib/faturaIslemOku";

export const dynamic = "force-dynamic";
export const maxDuration = 300;

const MAKS_BAYT = 4 * 1024 * 1024;
const MAKS_SAYFA = 3;
const VITRIN_BASINA_LIMIT = 30;
const PENCERE_SANIYE = 3600;

const IZINLI_TURLER = new Map([
  ["image/jpeg", "jpg"],
  ["image/png", "png"],
  ["image/webp", "webp"],
  ["application/pdf", "pdf"],
]);

function gercekTur(bayt: Uint8Array): string | null {
  if (bayt.length < 12) return null;
  if (bayt[0] === 0x25 && bayt[1] === 0x50 && bayt[2] === 0x44 &&
      bayt[3] === 0x46 && bayt[4] === 0x2d) return "application/pdf";
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
  const dosyalar = form.getAll("dosya");
  const editTokenGovde = String(form.get("editToken") ?? "").trim();

  if (!slug) {
    return NextResponse.json({ hata: "Vitrin belirtilmedi." }, { status: 400 });
  }
  if (dosyalar.length === 0 || dosyalar.some((deger) => !(deger instanceof File))) {
    return NextResponse.json({ hata: "Fatura fotoğrafı bulunamadı." }, { status: 400 });
  }
  if (dosyalar.length > MAKS_SAYFA) {
    return NextResponse.json({ hata: "Tek faturada en fazla 3 sayfa fotoğrafı yüklenebilir." }, { status: 413 });
  }
  const secilenDosyalar = dosyalar as File[];

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

  const { data: magazaData } = await admin
    .from("stores")
    .select("id")
    .eq("slug", ownerSlug)
    .maybeSingle();
  const magazaId = magazaData?.id;
  if (!magazaId) {
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
  }

  const { data: limitRows, error: limitHatasi } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_oku:${ownerSlug}`,
    p_max_requests: VITRIN_BASINA_LIMIT,
    p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (!limitHatasi && limit && limit.allowed === false) {
    return NextResponse.json(
      { hata: `Çok fazla fatura okudun. ${limit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  const toplamBoyut = secilenDosyalar.reduce((toplam, d) => toplam + d.size, 0);
  if (toplamBoyut > MAKS_BAYT) {
    return NextResponse.json({ hata: "Sayfa fotoğraflarının toplamı en fazla 4 MB olabilir." }, { status: 413 });
  }
  const sayfaBaytlari = await Promise.all(secilenDosyalar.map(async (d) => new Uint8Array(await d.arrayBuffer())));
  const sayfaTurleri = sayfaBaytlari.map(gercekTur);
  if (sayfaTurleri.some((tur) => !tur || !IZINLI_TURLER.has(tur))) {
    return NextResponse.json(
      { hata: "Fatura yalnız JPG, PNG, WebP veya PDF biçiminde olmalıdır." },
      { status: 415 },
    );
  }

  const ozetBaytlari = Buffer.concat(await Promise.all(
    sayfaBaytlari.map(async (icerik) => {
      const uzunluk = Buffer.alloc(4);
      uzunluk.writeUInt32BE(icerik.length, 0);
      return Buffer.concat([uzunluk, Buffer.from(icerik)]);
    }),
  ));
  const parmakIzi = belgeParmakIzi(ozetBaytlari);
  const eskiKimlik = await parmakIzindenIslemBul(admin, magazaId, parmakIzi);
  const oncekiIslem = eskiKimlik ? await islemiYukle(admin, magazaId, eskiKimlik) : null;
  if (oncekiIslem && oncekiIslem.satirlar.length > 0) {
    return NextResponse.json({
      ...islemYaniti(oncekiIslem),
      taslaklar: faturaTaslaklari(oncekiIslem.satirlar, oncekiIslem.islemKimligi),
    });
  }

  if (!process.env.OPENROUTER_API_KEY) {
    return NextResponse.json({ hata: "Fatura okuyucu hazır değil." }, { status: 503 });
  }

  const fotograflar = sayfaBaytlari.map((bayt, index) =>
    `data:${sayfaTurleri[index]};base64,${base64Cevir(bayt)}`);
  const goruntu = fotograflar.length === 1 ? fotograflar[0] : fotograflar;

  try {
    const okuma: GoruSonucu = await faturayiOku(goruntu);

    if (!okuma.satirlar || okuma.satirlar.length === 0) {
      return NextResponse.json(
        { hata: "Bu fotoğrafta ürün satırı bulunamadı. Daha net bir fotoğraf dene." },
        { status: 422 },
      );
    }

    const sonSatirlar = okuma.satirlar.map((satir) => faturaSatiriniAktar(satir, okuma.tedarikci));

    const kayitGirdisi = {
      slug: ownerSlug,
      parmakIzi,
      belgeAdedi: okuma.belgeAdedi,
      belgeToplami: okuma.belgeToplami,
      tedarikci: okuma.tedarikci,
      tedarikciVergiNo: okuma.tedarikciVergiNo,
      tedarikciAdres: okuma.tedarikciAdres,
      tedarikciSite: okuma.tedarikciSite,
      tedarikciIz: null,
      aramaDurumu: {
        erisimHatasi: sonSatirlar.some((s) => s.dogrulamaDurumu?.includes("Araştırılamadı")),
        sonrakiSatir: sonSatirlar.length,
        presetCevabi: { belgeEkleri: okuma.belgeEkleri, gruplar: okuma.gruplar, uyarilar: okuma.uyarilar },
      },
      satirlar: sonSatirlar,
      belgeTuru: okuma.belgeTuru,
      belgeNo: okuma.belgeNo,
      belgeTarihi: okuma.belgeTarihi,
      malBedeli: okuma.malBedeli,
      kdvTutari: okuma.kdvTutari,
      indirimTutari: okuma.indirimTutari,
      odenecekToplam: okuma.odenecekToplam,
      belgeUyarisi: (okuma.uyarilar ?? []).join(" · "),
    };

    const islemKimligi = await islemKaydet(kayitGirdisi);
    if (!islemKimligi) {
      return NextResponse.json({ hata: "Fatura işlemi kaydedilemedi." }, { status: 503 });
    }

    const taslaklar = faturaTaslaklari(sonSatirlar, islemKimligi);

    return NextResponse.json({
      tamam: true,
      satirlar: sonSatirlar,
      taslaklar,
      tedarikci: okuma.tedarikci,
      tedarikciVergiNo: okuma.tedarikciVergiNo,
      tedarikciAdres: okuma.tedarikciAdres,
      tedarikciSite: okuma.tedarikciSite,
      belgeToplami: okuma.belgeToplami,
      belgeAdedi: okuma.belgeAdedi,
      belgeTuru: okuma.belgeTuru,
      belgeNo: okuma.belgeNo,
      belgeTarihi: okuma.belgeTarihi,
      belge: { malBedeli: okuma.malBedeli, kdvTutari: okuma.kdvTutari, indirimTutari: okuma.indirimTutari, odenecekToplam: okuma.odenecekToplam },
      belgeEkleri: okuma.belgeEkleri,
      gruplar: okuma.gruplar,
      uyarilar: okuma.uyarilar,
      belgeUyarisi: (okuma.uyarilar ?? []).join(" · "),
      islemKimligi,
    });
  } catch (err) {
    const kod = err instanceof Error ? err.message : "unknown";
    console.error("[fatura-oku] hata:", kod);

    if (kod === "OKUYUCU_BAKIYE_BITTI") {
      return NextResponse.json(
        { hata: "Fatura okuyucu şu an kullanılamıyor. Lütfen bakiye durumunu kontrol edin." },
        { status: 503 },
      );
    }
    if (kod === "OKUYUCU_MODEL_BULUNAMADI") {
      return NextResponse.json({ hata: "Fatura okuma modeline şu anda erişilemiyor. Ürün taslakları oluşturulmadı." }, { status: 503 });
    }
    if (kod === "OKUYUCU_UCRETSIZ_KOTA_DOLDU") {
      return NextResponse.json({ hata: "Fatura okuyucunun günlük ücretsiz kullanım sınırı doldu. Ürün taslakları oluşturulmadı." }, { status: 503 });
    }
    if (kod === "OKUYUCU_ISTEK_SINIRI") {
      return NextResponse.json({ hata: "Fatura okuyucu şu anda istek sınırına ulaştı. Lütfen daha sonra deneyin." }, { status: 503 });
    }
    if (kod === "FOTOGRAFTA_YAZI_YOK") {
      return NextResponse.json(
        { hata: "Bu fotoğrafta yazı bulunamadı. Daha net bir fotoğraf deneyin." },
        { status: 422 },
      );
    }
    if (["OKUYUCU_ZAMAN_ASIMI", "OKUYUCU_EKSIK_CEVAP", "OKUYUCU_TAMAMLANMADI"].includes(kod)) {
      return NextResponse.json({ hata: "Ürün hazırlama tamamlanamadı. Eksik cevap yayınlanmadı; tekrar deneyin." }, { status: 504 });
    }
    return NextResponse.json({ hata: "Fatura şu an okunamadı. Tekrar deneyin." }, { status: 500 });
  }
}
