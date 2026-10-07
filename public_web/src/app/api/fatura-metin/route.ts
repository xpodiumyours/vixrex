import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { sahipYetkisi } from "@/lib/faturaYetki";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";
import { belgeGercegiUyuyorMu, belgeOzetiniAyikla, hamMetniSatirlaraAyir, tedarikciAdiniAyikla } from "@/lib/faturaSatirAyikla";
import { eslesmeyenSatir, siteKartiniUygula, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { ayniAlisverisAdaylari, belgeParmakIzi, islemKaydet } from "@/lib/faturaIslemKaydi";
import { islemiYukle, islemYaniti, parmakIzindenIslemBul } from "@/lib/faturaIslemOku";

export const dynamic = "force-dynamic";
export const maxDuration = 60;
const MAKS_BAYT = 5 * 1024 * 1024;
const MAKS_SATIR = 200;
const metinDeger = (deger: unknown): string => typeof deger === "string" ? deger.trim() : "";
function sayiDeger(deger: unknown): number | null {
  const temiz = typeof deger === "string" ? deger.trim().replace(/\s/g, "") : deger;
  if (temiz === "" || temiz === null || temiz === undefined) return null;
  const sayi = typeof temiz === "string" ? Number(temiz.includes(",") ? temiz.replace(/\./g, "").replace(",", ".") : temiz) : temiz;
  return typeof sayi === "number" && Number.isFinite(sayi) && sayi >= 0 ? sayi : null;
}
export async function POST(request: NextRequest) {
  try {
    const hamGovde = await request.text();
    if (Buffer.byteLength(hamGovde, "utf8") > MAKS_BAYT) return NextResponse.json({ hata: "Belge en fazla 5 MB olabilir." }, { status: 413 });
    let govde: Record<string, unknown>;
    try {
      const parsed: unknown = JSON.parse(hamGovde);
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error();
      govde = parsed as Record<string, unknown>;
    } catch { return NextResponse.json({ hata: "Belge bilgileri okunamadı." }, { status: 400 }); }
    const slug = metinDeger(govde.slug);
    if (!slug) return NextResponse.json({ hata: "Vitrin bilgisi eksik." }, { status: 400 });
    const yetki = await sahipYetkisi(slug, metinDeger(govde.editToken));
    if (!yetki.tamam) return NextResponse.json({ hata: yetki.hata }, { status: yetki.durum });
    const admin = getSupabaseAdmin();
    if (!admin) return NextResponse.json({ hata: "Sistem hazır değil." }, { status: 503 });
    const limit = await admin.rpc("consume_assistant_request", { p_client_key: `fatura_oku:${yetki.slug}`, p_max_requests: 20, p_window_seconds: 3600 });
    const sinir = Array.isArray(limit.data) ? limit.data[0] : limit.data;
    if (limit.error || !sinir?.allowed) return NextResponse.json({ hata: "Biraz sonra tekrar dene." }, { status: 429 });
    const ipLimit = await admin.rpc("consume_assistant_request", { p_client_key: `fatura_oku_ip:${fingerprintClient(getClientIp(request))}`, p_max_requests: 40, p_window_seconds: 86400 });
    const ipSiniri = Array.isArray(ipLimit.data) ? ipLimit.data[0] : ipLimit.data;
    if (ipLimit.error || !ipSiniri?.allowed) return NextResponse.json({ hata: "Biraz sonra tekrar dene." }, { status: 429 });
    const metin = metinDeger(govde.metin);
    const liste = Array.isArray(govde.satirlar) ? govde.satirlar : [];
    if (liste.length > MAKS_SATIR) return NextResponse.json({ hata: "Bir belgede en fazla 200 ürün satırı olabilir." }, { status: 413 });
    const hamSatirlar: HamFaturaSatiri[] = metin ? hamMetniSatirlaraAyir(metin) : liste.map((girdi: unknown) => {
      const g = girdi && typeof girdi === "object" && !Array.isArray(girdi) ? girdi as Record<string, unknown> : {};
      const satir = { hamSatir: metinDeger(g.hamSatir), model: metinDeger(g.model), ad: metinDeger(g.ad), barkod: metinDeger(g.barkod), varyant: metinDeger(g.varyant), beden: metinDeger(g.beden), marka: metinDeger(g.marka), adet: sayiDeger(g.adet), alisBirimFiyat: sayiDeger(g.alisBirimFiyat), satirToplam: sayiDeger(g.satirToplam), guven: 0 };
      satir.guven = [satir.model, satir.ad, satir.barkod, satir.varyant, satir.beden, satir.adet].filter(v => v !== "" && v !== null).length / 6;
      return satir;
    }).filter(satir => satir.model || satir.ad || satir.barkod);
    if (hamSatirlar.length > MAKS_SATIR) return NextResponse.json({ hata: "Bir belgede en fazla 200 ürün satırı olabilir." }, { status: 413 });
    if (!hamSatirlar.length) return NextResponse.json({ hata: "Ürün satırı bulunamadı. Model, ürün adı ya da barkod yaz." }, { status: 422 });
    const tedarikci = metinDeger(govde.tedarikci) || (metin ? tedarikciAdiniAyikla(metin) : "");
    const tedarikciSite = (metinDeger(govde.tedarikciSite) || metinDeger(govde.firmaSitesi)).slice(0, 200);
    const parmakIzi = belgeParmakIzi(Buffer.from(JSON.stringify({ kaynak: "metin", metin, satirlar: hamSatirlar, tedarikci, tedarikciSite }), "utf8"));
    const onceki = await parmakIzindenIslemBul(admin, yetki.storeId, parmakIzi);
    if (onceki) {
      const kayit = await islemiYukle(admin, yetki.storeId, onceki);
      if (kayit) return NextResponse.json(islemYaniti(kayit));
    }
    const ozet = metin ? belgeOzetiniAyikla(metin) : { adet: null, toplam: null };
    const uyum = belgeGercegiUyuyorMu(hamSatirlar, ozet);
    const satirlar = hamSatirlar.map((satir) => siteKartiniUygula(eslesmeyenSatir(satir)));
    const girdi = { slug: yetki.slug, parmakIzi, belgeAdedi: ozet.adet, belgeToplami: ozet.toplam, tedarikci, tedarikciVergiNo: "", tedarikciAdres: "", tedarikciSite, tedarikciIz: null, satirlar, aramaDurumu: { erisimHatasi: false, sinirDoldu: false }, belgeUyarisi: uyum.uyumlu ? null : uyum.sebep };
    const islemKimligi = await islemKaydet(girdi);
    if (!islemKimligi) return NextResponse.json({ hata: "Fatura kaydedilemedi. Tekrar dene." }, { status: 503 });
    const kayit = await islemiYukle(admin, yetki.storeId, islemKimligi);
    if (!kayit) return NextResponse.json({ hata: "Fatura kaydı doğrulanamadı. Tekrar dene." }, { status: 503 });
    return NextResponse.json({ ...islemYaniti(kayit), tekrar: false, kaynak: "metin", ayniAlisveris: await ayniAlisverisAdaylari({ slug: yetki.slug, girdi, islemKimligi }) });
  } catch { return NextResponse.json({ hata: "Belge işlenemedi. Tekrar dene." }, { status: 500 }); }
}
