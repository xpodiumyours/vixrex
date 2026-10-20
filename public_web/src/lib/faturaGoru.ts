/**
 * Fatura fotoğrafını OpenRouter üzerinden okuyan TEK yer.
 * Model, talimat ve araç ayarları OpenRouter Preset'inde tutulur; kod yalnız görselleri gönderir.
 */

export interface GoruSatiri {
  hamSatir: string;
  model: string;
  ad: string;
  barkod: string;
  varyant: string;
  beden: string;
  marka: string;
  adet: number | null;
  birim: string;
  birimFiyat: number | null;
  tutar: number | null;
  okumaGuveni: number | null;
  siteAciklama?: string;
  siteGorsel?: string;
  siteGorseller?: string[];
  siteSayfa?: string;
  siteKategori?: string;
}

export interface GoruSonucu {
  tedarikci: string;
  tedarikciVergiNo: string;
  tedarikciAdres: string;
  tedarikciSite: string;
  satirlar: GoruSatiri[];
  belgeAdedi: number | null;
  belgeToplami: number | null;
  belgeTuru: string;
  belgeNo: string;
  belgeTarihi: string;
  malBedeli: number | null;
  kdvTutari: number | null;
  indirimTutari: number | null;
  odenecekToplam: number | null;
  maliyet: number | null;
  gercekMaliyet?: number | null;
  girdiToken: number;
  ciktiToken: number;
  akilToken: number;
}

function sayi(deger: unknown): number | null {
  if (deger === null || deger === undefined || (typeof deger === "string" && !deger.trim())) return null;
  const n = typeof deger === "number" ? deger : Number(String(deger).replace(",", "."));
  return Number.isFinite(n) ? n : null;
}

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

/**
 * Fatura fotoğrafını OpenRouter'a gönderir ve hazır ürün kartı listesini alır.
 */
export async function faturayiOku(dataUrl: string | string[]): Promise<GoruSonucu> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");

  const gorseller = (Array.isArray(dataUrl) ? dataUrl : [dataUrl]).map((url) => ({
    type: "image_url" as const,
    image_url: { url },
  }));

  const presetHam = (process.env.OPENROUTER_PRESET || process.env.OPENROUTER_FATURA_PRESET || "").trim();
  if (!presetHam) throw new Error("OKUYUCU_PRESET_YOK");
  const presetRef = presetHam.startsWith("@preset/") ? presetHam : `@preset/${presetHam}`;

  const bodyData: Record<string, unknown> = {
    model: presetRef,
    messages: [{ role: "user", content: gorseller }],
  };

  const cevap = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
      "HTTP-Referer": "https://vixrex.com",
      "X-Title": "Vixrex Fatura",
    },
    body: JSON.stringify(bodyData),
  });

  if (!cevap.ok) {
    const hataGovdesi = await cevap.json().catch(() => null);
    const kod = (hataGovdesi as { error?: { code?: string } } | null)?.error?.code;
    throw new Error(
      cevap.status === 402 || kod === "insufficient_quota" ? "OKUYUCU_BAKIYE_BITTI" : "OKUYUCU_CEVAP_VERMEDI",
    );
  }

  const hamCevap = await cevap.json().catch(() => null);
  const metinCevap = hamCevap?.choices?.[0]?.message?.content;
  if (typeof metinCevap !== "string" || !metinCevap.trim()) {
    throw new Error("FOTOGRAFTA_YAZI_YOK");
  }

  const bas = metinCevap.indexOf("{");
  const son = metinCevap.lastIndexOf("}");
  if (bas < 0 || son <= bas) throw new Error("OKUMA_COZULEMEDI");

  let cozulen: Record<string, unknown>;
  try {
    cozulen = JSON.parse(metinCevap.slice(bas, son + 1));
  } catch {
    throw new Error("OKUMA_COZULEMEDI");
  }

  const hamSatirlar: Array<Record<string, unknown>> = Array.isArray(cozulen.satirlar) ? cozulen.satirlar : [];
  const satirlar: GoruSatiri[] = hamSatirlar.map((s) => {
    const gorsellerListesi: string[] = Array.isArray(s.site_gorseller)
      ? s.site_gorseller.filter((g): g is string => typeof g === "string" && g.startsWith("http"))
      : typeof s.site_gorsel === "string" ? [s.site_gorsel] : [];

    return {
      hamSatir: metin(s.ham_satir),
      model: metin(s.model),
      ad: metin(s.ad),
      barkod: metin(s.barkod),
      varyant: metin(s.varyant),
      beden: metin(s.beden),
      marka: metin(s.marka),
      adet: sayi(s.adet),
      birim: metin(s.birim),
      birimFiyat: sayi(s.birim_fiyat),
      tutar: sayi(s.tutar),
      okumaGuveni: sayi(s.okuma_guveni) ?? 1,
      siteAciklama: metin(s.site_aciklama),
      siteGorsel: gorsellerListesi[0] || "",
      siteGorseller: gorsellerListesi,
      siteSayfa: metin(s.site_sayfa),
      siteKategori: metin(s.kategori),
    };
  });

  const usage = hamCevap?.usage;
  return {
    tedarikci: metin(cozulen.tedarikci),
    tedarikciVergiNo: metin(cozulen.tedarikci_vergi_no),
    tedarikciAdres: metin(cozulen.tedarikci_adres),
    tedarikciSite: metin(cozulen.tedarikci_site),
    satirlar,
    belgeAdedi: sayi(cozulen.toplam_adet),
    belgeToplami: sayi(cozulen.toplam_tutar),
    belgeTuru: metin(cozulen.belge_turu) || "fatura",
    belgeNo: metin(cozulen.belge_no),
    belgeTarihi: metin(cozulen.belge_tarihi),
    malBedeli: sayi(cozulen.mal_bedeli),
    kdvTutari: sayi(cozulen.kdv_tutari),
    indirimTutari: sayi(cozulen.indirim_tutari),
    odenecekToplam: sayi(cozulen.odenecek_toplam),
    maliyet: sayi(usage?.cost),
    gercekMaliyet: sayi(usage?.cost),
    girdiToken: Number(usage?.prompt_tokens ?? usage?.input_tokens ?? 0),
    ciktiToken: Number(usage?.completion_tokens ?? usage?.output_tokens ?? 0),
    akilToken: Number(usage?.completion_tokens_details?.reasoning_tokens ?? 0),
  };
}
