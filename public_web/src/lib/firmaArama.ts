import { alanAdiTemizle } from "@/lib/ureticiKatalog";
import {
  siteFirmayaAitMi,
  type FirmaDogrulamasi,
  type FirmaDogrulaBagimliliklari,
} from "@/lib/firmaDogrula";

// Firmanın resmi sitesini Luna ile bulma.
//
// Brave + jeton eşleşme kaldırıldı: arama Luna `web_search` (open web),
// karar + doğrulama aynı kapıdan geçer. Sonuç kalıcı saklanmaz.

export interface FirmaAramaBagimliliklari {
  fetcher?: (input: string, init?: RequestInit) => Promise<Response>;
  apiAnahtari?: string;
  model?: string;
  kimlik?: { vergiNo: string; adres: string };
  dogrula?: FirmaDogrulaBagimliliklari;
}

export type FirmaAramaDurumu =
  | { durum: "kapali"; sebep: string }
  | { durum: "bulunamadi"; sebep: string }
  | { durum: "bulundu"; alan: string; kaynak: string; dogrulama?: FirmaDogrulamasi; maliyet?: number | null; girdiToken?: number; ciktiToken?: number; akilToken?: number };

const ARAMA_ZAMAN_ASIMI_MS = 60000;

const LUNA_ADRES = "https://openrouter.ai/api/v1/responses";
const LUNA_MODEL = "openai/gpt-5.6-luna";

// Pazar yeri, sosyal ağ, video ve sözlük adresleri firmanın resmi sitesi
// sayılmaz — buralardan eşleşme kurulmaz.
const RESMI_SITE_OLMAYANLAR = [
  "sahibinden.com",
  "trendyol.com",
  "hepsiburada.com",
  "amazon.",
  "n11.com",
  "ciceksepeti.com",
  "facebook.com",
  "instagram.com",
  "linkedin.com",
  "youtube.com",
  "x.com",
  "twitter.com",
  "tiktok.com",
  "wikipedia.org",
  "eksisozluk.com",
];

function resmiSiteOlmayan(alan: string): boolean {
  return RESMI_SITE_OLMAYANLAR.some((kalip) => alan === kalip || alan.endsWith(`.${kalip}`) || alan.includes(kalip));
}

export function resmiSiteSayilmaz(alan: string): boolean {
  const temiz = alanAdiTemizle(alan);
  return !temiz || resmiSiteOlmayan(temiz);
}

function lunaCiktiMetni(govde: { output_text?: unknown; output?: unknown }): string {
  if (typeof govde.output_text === "string" && govde.output_text.trim()) return govde.output_text;
  if (!Array.isArray(govde.output)) return "";
  const parcalar: string[] = [];
  for (const oge of govde.output) {
    const kayit = oge as { type?: unknown; content?: unknown };
    if (kayit.type !== "message" || !Array.isArray(kayit.content)) continue;
    for (const icerik of kayit.content) {
      const parca = icerik as { type?: unknown; text?: unknown };
      if (parca.type === "output_text" && typeof parca.text === "string") parcalar.push(parca.text);
    }
  }
  return parcalar.join("");
}

const FIRMA_SITE_SEMA = {
  type: "object",
  additionalProperties: false,
  required: ["alan", "kaynak"],
  properties: { alan: { type: "string" }, kaynak: { type: "string" } },
};

export async function firmaSitesiniAra(
  tedarikciAdi: string,
  bagimliliklar: FirmaAramaBagimliliklari = {},
): Promise<FirmaAramaDurumu> {
  const ad = tedarikciAdi.trim();
  if (ad.length < 3) return { durum: "bulunamadi", sebep: "Firma adı okunamadı." };

  const anahtar = (bagimliliklar.apiAnahtari ?? process.env.OPENROUTER_API_KEY ?? "").trim();
  if (!anahtar) {
    return {
      durum: "kapali",
      sebep: "Arama servisi bağlı değil; firmanın sitesini yazarak devam edilebilir.",
    };
  }

  const fetcher = bagimliliklar.fetcher ?? fetch;
  const model = (bagimliliklar.model ?? LUNA_MODEL).trim() || LUNA_MODEL;
  const vergiNo = (bagimliliklar.kimlik?.vergiNo ?? "").replace(/\D/g, "");
  const sorgu =
    vergiNo.length >= 10
      ? `${ad} firmasının resmi web sitesi hangisidir? Vergi No ${vergiNo}. Yalnız resmi siteyi döndür, pazaryeri ve sosyal ağ döndürme.`
      : `${ad} firmasının resmi web sitesi hangisidir? Yalnız resmi siteyi döndür, pazaryeri ve sosyal ağ döndürme.`;

  let govde: {
    output_text?: unknown;
    output?: unknown;
    usage?: { input_tokens?: unknown; output_tokens?: unknown };
  } | null;
  try {
    const yanit = await fetcher(LUNA_ADRES, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${anahtar}` },
      signal: AbortSignal.timeout(ARAMA_ZAMAN_ASIMI_MS),
      body: JSON.stringify({
        model,
        max_output_tokens: 512,
        reasoning: { effort: "low" },
        tools: [{ type: "openrouter:web_search", parameters: { engine: "native" } }],
        text: { format: { type: "json_schema", name: "firma_site", strict: true, schema: FIRMA_SITE_SEMA } },
        input: [{ role: "user", content: [{ type: "input_text", text: sorgu }] }],
      }),
    });
    if (!yanit.ok) return { durum: "bulunamadi", sebep: "Arama servisi yanıt vermedi." };
    govde = (await yanit.json().catch(() => null)) as typeof govde;
  } catch {
    return { durum: "bulunamadi", sebep: "Arama servisine ulaşılamadı." };
  }
  if (!govde) return { durum: "bulunamadi", sebep: "Arama yanıtı okunamadı." };

  let cozulen: { alan?: unknown; kaynak?: unknown } | null = null;
  try {
    cozulen = JSON.parse(lunaCiktiMetni(govde));
  } catch {
    return { durum: "bulunamadi", sebep: "Firmanın resmi sitesi aramada bulunamadı." };
  }
  const hamAlan = typeof cozulen?.alan === "string" ? cozulen.alan : "";
  const hamKaynak = typeof cozulen?.kaynak === "string" ? cozulen.kaynak : "";
  const alan = alanAdiTemizle(hamKaynak || hamAlan || "");
  if (!alan || resmiSiteOlmayan(alan)) {
    return { durum: "bulunamadi", sebep: "Firmanın resmi sitesi aramada bulunamadı." };
  }

  const dogrulama = await siteFirmayaAitMi(
    alan,
    { ad, vergiNo: bagimliliklar.kimlik?.vergiNo ?? "", adres: bagimliliklar.kimlik?.adres ?? "" },
    {
      fetcher: bagimliliklar.dogrula?.fetcher ?? fetcher,
      ...(bagimliliklar.dogrula?.resolveHost ? { resolveHost: bagimliliklar.dogrula.resolveHost } : {}),
    },
  );
  if (dogrulama.guc !== "guclu") {
    return {
      durum: "bulunamadi",
      sebep: "Bulunan site faturadaki firma bilgileriyle (vergi no, adres, ad) doğrulanamadı.",
    };
  }

  const kullanim = (govde.usage ?? {}) as { input_tokens?: unknown; output_tokens?: unknown };
  const girdi = Number(kullanim.input_tokens);
  const cikti = Number(kullanim.output_tokens);
  return {
    durum: "bulundu",
    alan,
    kaynak: `https://${alan}`,
    dogrulama,
    girdiToken: Number.isFinite(girdi) ? girdi : 0,
    ciktiToken: Number.isFinite(cikti) ? cikti : 0,
    akilToken: 0,
    maliyet: null,
  };
}
