import { NextResponse, type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { OWNER_SESSION_COOKIE, verifyOwnerSession } from "@/lib/ownerSession";
import { verifyStoreEditToken } from "@/lib/instagramServer";
import { fingerprintClient, getClientIp } from "@/lib/rentDemoSecurity";
import { belgeGercegiUyuyorMu } from "@/lib/faturaSatirAyikla";
import { eslesmeyenSatir, siteKartiniUygula, sonucOzeti, type EslesmisFaturaSatiri, type HamFaturaSatiri } from "@/lib/faturaEslestir";
import { ayniAlisverisAdaylari, belgeParmakIzi, islemKaydet, satirKanitKayitlari } from "@/lib/faturaIslemKaydi";
import { faturaTaslaklari } from "@/lib/faturaTaslagi";
import { firmaAlaniniKilitle, faturayiOku, lunaGorseliniDogrula, markaSitesiniBul, satirSitesindeAra, type GoruSatiri, type GoruSonucu } from "@/lib/faturaGoru";
import { kaynakGorseliniDogrula, urunSayfasindaGorselKaniti } from "@/lib/faturaGorsel";
import { ARAMA_UCETI_USD, aramaCagrisiSigarMi, bugunkuMaliyetUsd, gunlukTavanDolduMu, kullanimKaydet } from "@/lib/faturaMaliyet";
import { islemiYukle, islemYaniti, parmakIzindenIslemBul } from "@/lib/faturaIslemOku";

// Vixrex'in TEK fatura okuma ucu.
//
// Telefon kamerası VE web'den yüklenen fotoğraf AYNI bu uçtan geçer — iki
// ayrı "okuma beyni" olmaz (bkz. 2026-09-26 mimari düzeltmesi: önceden web
// tarafı ayrı bir OpenAI zinciri kullanıyordu, anahtar yoktu, hiç çalışmadı).
//
// Zincir: görüntü → faturaGoru.ts (OpenAI/gpt-5.6-luna, katı şema) →
// faturaSatirAyikla.ts (belge gerçeği doğrulaması) → faturaEslestir.ts
// (modelin site fotoğrafı, açıklaması ve sayfa adresi). Tutmayan okuma vitrine yazılmaz.
// (Eski "vixrex-fatura-goru" kenar fonksiyonu ve Kilo zinciri 2026-10-04'te
// kaldırıldı — ikinci okuma beyniydi. OpenRouter bu hattan 2026-10-06'da çıktı.)
// Hiçbir aşama ürün oluşturmaz veya yayınlamaz — o /api/products/batch
// üzerinden, esnaf onayıyla olur.
//
// Kimlik doğrulama: tarayıcı çerezle (verifyOwnerSession), Flutter
// store edit_token ile (verifyStoreEditToken) — /api/fatura-eslestir ile
// aynı desen, ikisi de bu tek ucu çağırabilir.

export const dynamic = "force-dynamic";
export const maxDuration = 300;

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

  const { data: limitRows, error: limitHatasi } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_oku:${ownerSlug}`,
    p_max_requests: VITRIN_BASINA_LIMIT,
    p_window_seconds: PENCERE_SANIYE,
  });
  const limit = Array.isArray(limitRows) ? limitRows[0] : limitRows;
  if (limitHatasi || !limit || typeof limit.allowed !== "boolean") {
    return NextResponse.json({ hata: "Fatura kullanım limiti doğrulanamadı; ücretli okuma başlatılmadı." }, { status: 503 });
  }
  if (!limit.allowed) {
    return NextResponse.json(
      { hata: `Çok fazla fatura okudun. ${limit.retry_after_seconds} sn sonra dene.` },
      { status: 429 },
    );
  }

  const clientKey = fingerprintClient(getClientIp(request));
  const { data: ipRows, error: ipHatasi } = await admin.rpc("consume_assistant_request", {
    p_client_key: `fatura_oku_ip:${clientKey}`,
    p_max_requests: 40,
    p_window_seconds: 86400,
  });
  const ipLimit = Array.isArray(ipRows) ? ipRows[0] : ipRows;
  if (ipHatasi || !ipLimit || typeof ipLimit.allowed !== "boolean") {
    return NextResponse.json({ hata: "Fatura IP limiti doğrulanamadı; ücretli okuma başlatılmadı." }, { status: 503 });
  }
  if (!ipLimit.allowed) {
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

  let magazaId: string;
  try {
    const magaza = await admin.from("stores").select("id").eq("slug", ownerSlug).maybeSingle();
    if (typeof magaza.data?.id !== "string" || !magaza.data.id) {
      return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 404 });
    }
    magazaId = magaza.data.id;
  } catch (hata) {
    console.error("[fatura-oku] vitrin okunamadi:", hata instanceof Error ? hata.message : hata);
    return NextResponse.json({ hata: "Vitrin bulunamadı." }, { status: 503 });
  }

  const parmakIzi = belgeParmakIzi(bayt);
  const eskiKimlik = await parmakIzindenIslemBul(admin, magazaId, parmakIzi);
  const oncekiIslem = eskiKimlik ? await islemiYukle(admin, magazaId, eskiKimlik) : null;
  const oncekiCursor = oncekiIslem?.aramaDurumu?.sonrakiSatir;
  if (oncekiIslem && (typeof oncekiCursor !== "number" || !Number.isInteger(oncekiCursor) || oncekiCursor >= oncekiIslem.satirlar.length)) {
    return NextResponse.json({
      ...islemYaniti(oncekiIslem),
      taslaklar: faturaTaslaklari(oncekiIslem.satirlar, oncekiIslem.islemKimligi),
    });
  }
  if (!process.env.OPENROUTER_API_KEY) {
    return NextResponse.json({ hata: "Fatura okuyucu hazır değil." }, { status: 503 });
  }

  let gunlukHarcama = 0;
  try {
    gunlukHarcama = await bugunkuMaliyetUsd(admin, magazaId);
  } catch (hata) {
    console.error("[fatura-oku] maliyet okunamadi:", hata instanceof Error ? hata.message : hata);
    return NextResponse.json({ hata: "Günlük maliyet doğrulanamadı; ücretli okuma başlatılmadı." }, { status: 503 });
  }
  if (gunlukTavanDolduMu(gunlukHarcama)) {
    return NextResponse.json({ hata: "Günlük fatura okuma maliyet sınırı doldu." }, { status: 429 });
  }

  const goruntu = `data:${tur};base64,${base64Cevir(bayt)}`;

  try {
    // Ayni belge tekrar yukunurse OCR tekrarlanmaz; kayitli ham satirlar kullanilir.
    const okuma: GoruSonucu = oncekiIslem ? {
      tedarikci: oncekiIslem.tedarikci, tedarikciVergiNo: oncekiIslem.tedarikciVergiNo,
      tedarikciAdres: oncekiIslem.tedarikciAdres, tedarikciSite: oncekiIslem.tedarikciSite,
      satirlar: oncekiIslem.satirlar.map((satir) => ({
        hamSatir: satir.hamSatir, model: satir.model, ad: satir.ad, barkod: satir.barkod,
        varyant: satir.varyant, beden: satir.beden, marka: satir.marka ?? "",
        adet: satir.adet, birim: satir.birim ?? "", birimFiyat: satir.alisBirimFiyat,
        tutar: satir.satirToplam, okumaGuveni: satir.guven,
      })),
      belgeAdedi: oncekiIslem.belgeAdedi, belgeToplami: oncekiIslem.belgeToplami,
      belgeTuru: oncekiIslem.belge.belgeTuru, belgeNo: oncekiIslem.belge.belgeNo,
      belgeTarihi: oncekiIslem.belge.belgeTarihi ?? "", malBedeli: oncekiIslem.belge.malBedeli,
      kdvTutari: oncekiIslem.belge.kdvTutari, indirimTutari: oncekiIslem.belge.indirimTutari,
      odenecekToplam: oncekiIslem.belge.odenecekToplam,
      maliyet: 0, girdiToken: 0, ciktiToken: 0, akilToken: 0,
    } : await faturayiOku(goruntu);
    if (!oncekiIslem) {
      try {
        await kullanimKaydet(admin, magazaId, okuma);
        gunlukHarcama += okuma.maliyet ?? 0;
      } catch (hata) {
        console.error("[fatura-oku] maliyet yazilamadi:", hata instanceof Error ? hata.message : hata);
        return NextResponse.json({ hata: "Fatura okuma kaydı yazılamadı. Tekrar dene." }, { status: 503 });
      }
    }

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
        birim: satir.birim,
        alisBirimFiyat: satir.birimFiyat,
        satirToplam: satir.tutar,
        guven: satir.okumaGuveni ?? 0,
      }));

    if (hamSatirlar.length === 0) {
      return NextResponse.json(
        { hata: "Bu fotoğrafta ürün satırı bulunamadı. Daha net bir fotoğraf dene." },
        { status: 422 },
      );
    }

    const sonTedarikci = okuma.tedarikci;
    const sonTedarikciVergiNo = okuma.tedarikciVergiNo;
    const sonTedarikciAdres = okuma.tedarikciAdres;
    const sonTedarikciSite = okuma.tedarikciSite;
    const sonOzet = { adet: okuma.belgeAdedi, toplam: okuma.belgeToplami };
    const sonSatirlar = hamSatirlar;
    const sonBelge = {
      belgeTuru: okuma.belgeTuru,
      belgeNo: okuma.belgeNo,
      belgeTarihi: okuma.belgeTarihi,
      malBedeli: okuma.malBedeli,
      kdvTutari: okuma.kdvTutari,
      indirimTutari: okuma.indirimTutari,
      odenecekToplam: okuma.odenecekToplam,
    };
    const sonUyum = belgeGercegiUyuyorMu(hamSatirlar, {
      adet: sonOzet.adet,
      toplam: okuma.malBedeli ?? sonOzet.toplam,
    });
    if (!sonUyum.uyumlu) {
      return NextResponse.json(
        { hata: "Fotoğraf tutmadı. Satırların toplamı belgenin toplamıyla uyuşmuyor. Daha net bir fotoğraf dene." },
        { status: 422 },
      );
    }
    const belgeUyarisi = null;

    const etkinSite = oncekiIslem?.tedarikciSite || await firmaAlaniniKilitle({
      belgedeYazan: sonTedarikciSite,
      esnafIpucu: siteIpucu,
      tedarikciAdi: sonTedarikci,
      vergiNo: sonTedarikciVergiNo,
      adres: sonTedarikciAdres,
    }, {
      izin: () => aramaCagrisiSigarMi(gunlukHarcama),
      kaydet: async (kullanim) => {
        const maliyet = (kullanim.maliyet ?? 0) + ARAMA_UCETI_USD;
        await kullanimKaydet(admin, magazaId, { ...kullanim, maliyet });
        gunlukHarcama += maliyet;
      },
    });

    const ilkDurum = {
      erisimHatasi: false, sinirDoldu: false, sonrakiSatir: 0,
      hatalar: {} as Record<string, string>,
    };
    const kayitGirdisi = {
      slug: ownerSlug, parmakIzi,
      belgeAdedi: sonOzet.adet, belgeToplami: sonOzet.toplam,
      tedarikci: sonTedarikci, tedarikciVergiNo: sonTedarikciVergiNo,
      tedarikciAdres: sonTedarikciAdres, tedarikciSite: etkinSite,
      tedarikciIz: null,
      aramaDurumu: ilkDurum,
      satirlar: sonSatirlar.map((satir) => siteKartiniUygula(eslesmeyenSatir(satir))),
      belgeUyarisi, ...sonBelge,
    };
    // Araştırma baslamadan ham satirlar atomik kayda alinir.
    const islemKimligi = oncekiIslem?.islemKimligi ?? await islemKaydet(kayitGirdisi);
    if (!islemKimligi) return NextResponse.json({ hata: "Fatura işlemi kaydedilemedi." }, { status: 503 });
    const ilkKayit = oncekiIslem ?? await islemiYukle(admin, magazaId, islemKimligi);
    if (!ilkKayit || ilkKayit.satirlar.length !== sonSatirlar.length) {
      return NextResponse.json({ hata: "Kaydedilen fatura tekrar açılamadı. Tekrar dene." }, { status: 503 });
    }
    const aramaDurumu = oncekiIslem?.aramaDurumu ? {
      erisimHatasi: oncekiIslem.aramaDurumu.erisimHatasi,
      sinirDoldu: false,
      sonrakiSatir: oncekiCursor ?? 0,
      hatalar: { ...(oncekiIslem.aramaDurumu.hatalar ?? {}) },
    } : ilkDurum;
    const satirlar: EslesmisFaturaSatiri[] = [];
    const markaAlanlari = new Map<string, string>();
    let aramaAcik = true;
    for (const [sira, satir] of sonSatirlar.entries()) {
      if (sira < aramaDurumu.sonrakiSatir) {
        satirlar.push(ilkKayit.satirlar[sira]);
        continue;
      }
      let siteAciklama = "";
      let siteGorsel = "";
      let siteSayfa = "";
      let siteAd = "";
      let siteDayanak: "kod" | "barkod" | "ad" | undefined;
      let siteFotografKaniti: { kaynakSayfa: string; kaynakGorsel: string; kaynakAlintisi: string; lunaGerekcesi: string } | undefined;
      let siteUyari = etkinSite ? "" : "Resmî üretici sitesi doğrulanamadı.";
      if (!etkinSite && !aramaCagrisiSigarMi(gunlukHarcama)) {
        aramaAcik = false;
        aramaDurumu.sinirDoldu = true;
        siteUyari = "Resmî site araştırması için günlük maliyet sınırı doldu.";
      }
      const marka = satir.marka?.trim() ?? "";
      const ayriMarka = Boolean(marka) &&
        marka.toLocaleLowerCase("tr-TR") !== sonTedarikci.trim().toLocaleLowerCase("tr-TR");
      const markaAnahtari = marka.toLocaleLowerCase("tr-TR");
      if (ayriMarka && !markaAlanlari.has(markaAnahtari) && aramaAcik && aramaCagrisiSigarMi(gunlukHarcama)) {
        try {
          const bulunan = await markaSitesiniBul({
            marka, tedarikci: sonTedarikci, tedarikciSitesi: etkinSite,
            model: satir.model, ad: satir.ad,
          });
          const aramaMaliyeti = (bulunan.maliyet ?? 0) + ARAMA_UCETI_USD;
          await kullanimKaydet(admin, magazaId, { ...bulunan, maliyet: aramaMaliyeti });
          gunlukHarcama += aramaMaliyeti;
          markaAlanlari.set(markaAnahtari, bulunan.alan);
        } catch (hata) {
          const mesaj = hata instanceof Error ? hata.message : "";
          aramaAcik = false;
          aramaDurumu.sinirDoldu = true;
          aramaDurumu.erisimHatasi = true;
          siteUyari = mesaj === "OKUYUCU_BAKIYE_BITTI"
            ? "Üretici arama bakiyesi doldu; satır doğrulanmadı."
            : "Üretici araştırması servisine erişilemedi; yeniden denenecek.";
          console.error("[fatura-oku] marka sitesi aramasi durdu:", mesaj || hata);
          markaAlanlari.set(markaAnahtari, "");
        }
      }
      const satirSitesi = ayriMarka ? (markaAlanlari.get(markaAnahtari) ?? "") : etkinSite;
      const aranabilir = Boolean(satirSitesi && (satir.model || satir.ad || satir.barkod));
      if (aramaAcik && ayriMarka && !satirSitesi && !aramaCagrisiSigarMi(gunlukHarcama)) {
        aramaAcik = false;
        aramaDurumu.sinirDoldu = true;
        siteUyari = "Üretici araması için günlük maliyet sınırı doldu.";
      }
      if (aramaAcik && aranabilir && !aramaCagrisiSigarMi(gunlukHarcama)) {
        aramaAcik = false;
        aramaDurumu.sinirDoldu = true;
        siteUyari = "Günlük araştırma maliyet sınırı doldu; kaldığı satırdan devam edebilir.";
      }
      if (aramaAcik && aranabilir && aramaCagrisiSigarMi(gunlukHarcama)) {
        try {
          const arama = await satirSitesindeAra({
            alan: satirSitesi,
            model: satir.model,
            ad: satir.ad,
            barkod: satir.barkod,
            marka: satir.marka,
            varyant: satir.varyant,
            beden: satir.beden,
          });
          const aramaMaliyeti = (arama.maliyet ?? 0) + ARAMA_UCETI_USD;
          await kullanimKaydet(admin, magazaId, { ...arama, maliyet: aramaMaliyeti });
          gunlukHarcama += aramaMaliyeti;
          if (!arama.sayfa || !arama.gorsel) {
            siteUyari = "Resmî sitedeki ürün kimliği ve fotoğrafı doğrulanamadı.";
          }
          if (arama.sayfa && arama.gorsel) {
            const gorselDogrulama = await kaynakGorseliniDogrula(arama.gorsel);
            const gorsel = gorselDogrulama.tamam ? arama.gorsel : "";
            const aciklama = arama.aciklama.trim() || satir.ad.trim() || satir.model.trim();
            if (gorsel && aciklama) {
              const kaynakKaniti = await urunSayfasindaGorselKaniti(arama.sayfa, gorsel, satir.varyant);
              if (!kaynakKaniti) {
                siteUyari = "Fotoğrafın bu resmî ürün sayfasına ve doğru renk seçeneğine bağlı olduğu doğrulanamadı.";
              } else if (!aramaCagrisiSigarMi(gunlukHarcama)) {
                siteUyari = "Fotoğraf incelemesi için günlük kullanım sınırı doldu.";
              } else {
                const dogrulananGorselVerisi = gorselDogrulama.bayt && gorselDogrulama.tur
                  ? `data:${gorselDogrulama.tur};base64,${Buffer.from(gorselDogrulama.bayt).toString("base64")}`
                  : "";
                if (!dogrulananGorselVerisi) {
                  throw new Error("FOTOGRAF_VERISI_DOGRULANAMADI");
                }
                const inceleme = await lunaGorseliniDogrula({
                  gorsel: dogrulananGorselVerisi, kaynakSayfa: arama.sayfa, kaynakAlintisi: kaynakKaniti.kaynakAlintisi,
                  urunAdi: arama.ad, faturaAdi: satir.ad, marka: satir.marka ?? "",
                  renk: satir.varyant, beden: satir.beden,
                });
                await kullanimKaydet(admin, magazaId, inceleme);
                gunlukHarcama += inceleme.maliyet ?? 0;
                if (inceleme.uyumlu) {
                  siteAd = arama.ad;
                  siteDayanak = arama.dayanak ?? undefined;
                  siteAciklama = aciklama;
                  siteGorsel = gorsel;
                  siteSayfa = arama.sayfa;
                  siteFotografKaniti = {
                    kaynakSayfa: arama.sayfa, kaynakGorsel: gorsel,
                    kaynakAlintisi: kaynakKaniti.kaynakAlintisi,
                    lunaGerekcesi: inceleme.gerekce,
                  };
                } else {
                  siteUyari = "Luna fotoğraftaki ürün veya renk uyumunu doğrulayamadı.";
                }
              }
            }
          }
        } catch (hata) {
          const mesaj = hata instanceof Error ? hata.message : "";
          aramaAcik = false;
          aramaDurumu.sinirDoldu = true;
          aramaDurumu.erisimHatasi = true;
          siteUyari = mesaj === "OKUYUCU_BAKIYE_BITTI"
            ? "OpenRouter bakiyesi doldu; satırın araştırması tamamlanmadı."
            : "Ürün araştırma servisine erişilemedi; kaldığı satırdan sürebilir.";
          console.error("[fatura-oku] site aramasi durdu:", mesaj || hata);
        }
      }
      const sonucSatir = siteKartiniUygula(eslesmeyenSatir({
        ...satir,
        siteAd,
        siteDayanak,
        siteAciklama,
        siteGorsel,
        siteSayfa,
        siteFotografKaniti,
        sayfaDogrulandi: Boolean(siteFotografKaniti),
      }));
      if (siteUyari && sonucSatir.sonuc !== "kanitli") sonucSatir.uyari = siteUyari;
      satirlar.push(sonucSatir);
      const satirId = ilkKayit.satirlar[sira]?.satirId;
      if (!satirId) throw new Error("FATURA_SATIR_KIMLIGI_EKSIK");
      aramaDurumu.sonrakiSatir = aramaAcik ? sira + 1 : sira;
      if (siteUyari) aramaDurumu.hatalar[String(sira)] = siteUyari;
      else delete aramaDurumu.hatalar[String(sira)];
      const kanit = satirKanitKayitlari(satirId, sonucSatir, "");
      const { data: yazildi, error: yazmaHatasi } = await admin.rpc("replace_invoice_line", {
        p_store_id: magazaId, p_job_id: islemKimligi, p_line_id: satirId,
        p_line: {
          model: sonucSatir.model, product_name: sonucSatir.ad,
          barcode: sonucSatir.barkod.replace(/\D/g, ""),
          brand: sonucSatir.marka ?? "", outcome: sonucSatir.sonuc,
          warning: sonucSatir.uyari ?? "", catalog_snapshot: sonucSatir.katalog,
          conflict_snapshot: sonucSatir.celiski ?? null,
        },
        p_evidence: kanit.kanit, p_candidates: kanit.aday,
        p_rights: kanit.gorsel, p_discovery: aramaDurumu,
      });
      if (yazmaHatasi || yazildi?.success !== true) throw new Error("FATURA_SATIR_KAYDI_BASARISIZ");
      if (!aramaAcik) break;
    }

    const kayitli = await islemiYukle(admin, magazaId, islemKimligi);
    if (!kayitli) {
      return NextResponse.json({ hata: "Kaydedilen fatura tekrar açılamadı. Tekrar dene." }, { status: 503 });
    }
    const ayniAlisveris = islemKimligi
      ? await ayniAlisverisAdaylari({ slug: ownerSlug, islemKimligi, girdi: kayitGirdisi })
      : [];

    return NextResponse.json({
      tamam: true,
      satirlar: kayitli.satirlar,
      belgeToplami: kayitli.belgeToplami,
      belgeAdedi: kayitli.belgeAdedi,
      ...(kayitli.belgeUyarisi ? { belgeUyarisi: kayitli.belgeUyarisi } : {}),
      tedarikci: kayitli.tedarikci,
      tedarikciVergiNo: kayitli.tedarikciVergiNo,
      tedarikciAdres: kayitli.tedarikciAdres,
      tedarikciSite: kayitli.tedarikciSite,
      siteDurumu: kayitli.aramaDurumu?.siteDurumu ?? null,
      tedarikciDijitalIz: kayitli.tedarikciDijitalIz,
      katalogEslesmesi: kayitli.satirlar.filter((satir) => satir.katalog !== null).length,
      sonucOzeti: sonucOzeti(kayitli.satirlar),
      taslaklar: faturaTaslaklari(kayitli.satirlar, islemKimligi),
      islemKimligi,
      belge: kayitli.belge,
      ayniAlisveris,
      aramaSuruyor: aramaDurumu.sinirDoldu || aramaDurumu.sonrakiSatir < sonSatirlar.length,
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
