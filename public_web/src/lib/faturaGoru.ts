/**
 * Fatura fotoğrafını okuyan TEK yer.
 *
 * Telefon uygulaması da web de `/api/fatura-oku` ucuna gider; o uç da buraya.
 * İkinci bir "okuma beyni" yoktur.
 *
 * Sağlayıcı: OpenRouter üzerinden `openai/gpt-5.6-luna`.
 *
 * Neden bu model — 2026-09-26'da gerçek faturayla (fis_4, 13 satır / 75 adet /
 * 6.034,00 TL) ölçüldü:
 *   gpt-5.6-luna      13/13 satır, 75/75 adet, 6.034 TL, 0 yanlış  ~7 kuruş
 *   gpt-5.4-mini      12/13 satır, 74/75 adet, 5 doğru adet        ~19 kuruş
 *   claude-sonnet     13/13 satır, 75/75 adet ama yalnız 5 doğru   ~4 TL
 *   ücretsiz modeller hiçbiri tutturamadı
 * luna üç kez üst üste hatasız okudu; hem en doğru hem en ucuz olduğu için
 * seçildi. Model değiştirilecekse aynı faturayla yeniden ölçülmelidir.
 *
 * Model satırları YAPILANDIRILMIŞ döndürür; yine de doğru kabul edilmez —
 * `belgeGercegiUyuyorMu` satır toplamlarını belgenin kendi toplamıyla
 * karşılaştırır. Tutmayan okuma kullanılmaz.
 */

const ADRES = "https://openrouter.ai/api/v1/chat/completions";
export const GORU_MODELI = "openai/gpt-5.6-luna";

const SORU = [
  "Bu bir fatura tablosu. HER urun satirini oku. Yalniz JSON dondur.",
  '{"tedarikci":"","satirlar":[{"model":"","barkod":"","varyant":"","beden":"","adet":0,"birim_fiyat":0,"tutar":0}],"toplam_adet":0,"toplam_tutar":0}',
  "1. Her satirda adet * birim_fiyat = tutar olmali.",
  "2. Satirlarin adet toplami = toplam_adet, tutar toplami = toplam_tutar.",
  "3. toplam_adet/toplam_tutar en alttaki 'Toplam' satirindan alinir.",
  "4. Sayilari 6.034,00 -> 6034.00 bicimine cevir. Uydurma yok.",
  "5. tedarikci = faturayi kesen firmanin adi. Yazmiyorsa bos birak, tahmin etme.",
].join("\n");

export interface GoruSatiri {
  model: string;
  barkod: string;
  varyant: string;
  beden: string;
  adet: number | null;
  birimFiyat: number | null;
  tutar: number | null;
}

export interface GoruSonucu {
  /** Faturayı kesen firma. Belgede yazmıyorsa boş — tahmin edilmez. */
  tedarikci: string;
  satirlar: GoruSatiri[];
  belgeAdedi: number | null;
  belgeToplami: number | null;
  /** Bu okumanın OpenRouter'da tuttuğu gerçek maliyet (USD). */
  maliyet: number | null;
}

function sayi(deger: unknown): number | null {
  const n = typeof deger === "number" ? deger : Number(String(deger ?? "").replace(",", "."));
  return Number.isFinite(n) ? n : null;
}

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

/**
 * Fotoğrafı okur. Hata durumunda `Error` fırlatır — çağıran uç kullanıcıya
 * ne olduğunu kendi diliyle söyler.
 */
export async function faturayiOku(dataUrl: string): Promise<GoruSonucu> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");

  const cevap = await fetch(ADRES, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
    },
    body: JSON.stringify({
      model: GORU_MODELI,
      temperature: 0,
      usage: { include: true },
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: SORU },
            { type: "image_url", image_url: { url: dataUrl } },
          ],
        },
      ],
    }),
  });

  if (!cevap.ok) {
    // 402 = bakiye bitti; bunu ayırmak önemli, "tekrar dene" demek yanlış olur.
    throw new Error(cevap.status === 402 ? "OKUYUCU_BAKIYE_BITTI" : "OKUYUCU_CEVAP_VERMEDI");
  }

  const govde = await cevap.json().catch(() => null);
  const ham = govde?.choices?.[0]?.message?.content;
  if (typeof ham !== "string" || !ham.trim()) throw new Error("FOTOGRAFTA_YAZI_YOK");

  // Model bazen JSON'u açıklama arasına koyabiliyor; ilk süslü parantezden
  // sonuncusuna kadar alınır.
  const bas = ham.indexOf("{");
  const son = ham.lastIndexOf("}");
  if (bas < 0 || son <= bas) throw new Error("OKUMA_COZULEMEDI");

  let cozulen: unknown;
  try {
    cozulen = JSON.parse(ham.slice(bas, son + 1));
  } catch {
    throw new Error("OKUMA_COZULEMEDI");
  }

  const kok = cozulen as {
    tedarikci?: unknown;
    satirlar?: unknown;
    toplam_adet?: unknown;
    toplam_tutar?: unknown;
  };
  const hamSatirlar = Array.isArray(kok.satirlar) ? kok.satirlar : [];

  const satirlar: GoruSatiri[] = hamSatirlar.map((girdi) => {
    const s = girdi as Record<string, unknown>;
    return {
      model: metin(s.model),
      barkod: metin(s.barkod),
      varyant: metin(s.varyant),
      beden: metin(s.beden),
      adet: sayi(s.adet),
      birimFiyat: sayi(s.birim_fiyat),
      tutar: sayi(s.tutar),
    };
  });

  return {
    tedarikci: metin(kok.tedarikci),
    satirlar,
    belgeAdedi: sayi(kok.toplam_adet),
    belgeToplami: sayi(kok.toplam_tutar),
    maliyet: sayi(govde?.usage?.cost),
  };
}
