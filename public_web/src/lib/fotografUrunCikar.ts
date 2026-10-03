const ADRES = "https://openrouter.ai/api/v1/chat/completions";

export interface FotografUrunOnerisi {
  ad: string;
  kategori: string;
  aciklama: string;
  fiyat: string;
  marka: string | null;
}

const SORU = [
  "Bu tek bir urun fotografidir (urunun kendisi, fatura veya etiket degil). Fotograftaki urunu incele.",
  'Yalniz JSON dondur: {"ad":"","kategori":"","aciklama":"","fiyat":"","marka":""}',
  "1. ad: urunun ne oldugu — fotografta yaziyorsa yazan adi kullan, yazmiyorsa gorunenden net tanimla.",
  "2. kategori: vitrin kategorisi gibi kisa bir etiket (orn. Telefon Aksesuar, Gida, Temizlik).",
  "3. aciklama: urunun1-2 kisa cumlelik tanimi; yazmiyorsan bos birak.",
  "4. fiyat: fotografta acikca bir fiyat yazmiyorsa bos birak, tahmin etme; yaziyorsa sadece sayiyi virgulle (orn. 299,90).",
  "5. marka: urunun uzerinde yazmiyorsa bos birak, tahmin etme.",
  "6. Uydurma yok; gorunmeyen bilgiyi yazma.",
].join("\n");

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

export async function fotografdanUrunCikar(dataUrl: string): Promise<FotografUrunOnerisi> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");

  const cevap = await fetch(ADRES, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
    },
    body: JSON.stringify({
      model: "openai/gpt-5.6-luna",
      temperature: 0,
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

  if (!cevap.ok) throw new Error(`OKUYUCU_HATA_${cevap.status}`);
  const govde = (await cevap.json().catch(() => null)) as
    | { choices?: Array<{ message?: { content?: unknown } }> }
    | null;
  const ham = govde?.choices?.[0]?.message?.content;
  const metinGovde = Array.isArray(ham)
    ? ham.map((parca) => (parca && typeof parca === "object" && "text" in parca ? String((parca as { text?: unknown }).text ?? "") : "")).join("")
    : typeof ham === "string"
      ? ham
      : "";
  const ilkParantez = metinGovde.indexOf("{");
  const sonParantez = metinGovde.lastIndexOf("}");
  if (ilkParantez < 0 || sonParantez <= ilkParantez) throw new Error("OKUYUCU_SONUC_YOK");
  let ayrilmis: unknown;
  try {
    ayrilmis = JSON.parse(metinGovde.slice(ilkParantez, sonParantez + 1));
  } catch {
    throw new Error("OKUYUCU_SONUC_YOK");
  }
  const nesne = (ayrilmis ?? {}) as Record<string, unknown>;
  const ad = metin(nesne.ad);
  if (!ad) throw new Error("OKUYUCU_SONUC_YOK");
  return {
    ad,
    kategori: metin(nesne.kategori),
    aciklama: metin(nesne.aciklama),
    fiyat: metin(nesne.fiyat),
    marka: metin(nesne.marka) || null,
  };
}
