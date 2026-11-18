import { VARSAYILAN_FATURA_PRESET } from "@/lib/faturaPresetSozlesmesi";

export const VARSAYILAN_PRIZ_ADRESI = "https://openrouter.ai/api/v1/chat/completions";
const GEMINI_PRIZ_ADRESI = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

function geminiPrizAnahtari(): string {
  return (process.env.GEMINI_API_KEY || "").trim() || (process.env.GOOGLE_API_KEY || "").trim();
}

function openRouterPrizAnahtari(): string {
  return (process.env.FATURA_PRIZ_API_KEY || "").trim() || (process.env.OPENROUTER_API_KEY || "").trim();
}

export function geminiPrizAktifMi(): boolean {
  const geminiKey = geminiPrizAnahtari();
  if (!geminiKey) return false;
  const acikAdres = (process.env.FATURA_PRIZ_URL || "").trim();
  if (acikAdres.includes("generativelanguage.googleapis.com")) return true;
  const orKey = openRouterPrizAnahtari();
  return !orKey;
}

export function faturaPrizAdresi(): string {
  if (geminiPrizAktifMi()) {
    const acikAdres = (process.env.FATURA_PRIZ_URL || "").trim();
    if (acikAdres.includes("generativelanguage.googleapis.com")) {
      return acikAdres.includes("?key=") ? acikAdres : `${acikAdres}?key=${geminiPrizAnahtari()}`;
    }
    return `${GEMINI_PRIZ_ADRESI}?key=${geminiPrizAnahtari()}`;
  }
  const acikAdres = (process.env.FATURA_PRIZ_URL || "").trim();
  if (acikAdres) return acikAdres;
  const temelAdres = (process.env.OPENROUTER_BASE_URL || "").trim().replace(/\/+$/, "");
  if (temelAdres) {
    return temelAdres.endsWith("/chat/completions") ? temelAdres : `${temelAdres}/chat/completions`;
  }
  return VARSAYILAN_PRIZ_ADRESI;
}

export function faturaPrizAnahtari(): string {
  if (geminiPrizAktifMi()) {
    return geminiPrizAnahtari();
  }
  const orKey = openRouterPrizAnahtari();
  if (orKey) return orKey;
  return geminiPrizAnahtari();
}

export function faturaOkumaPresetReferansi(): string {
  const ham = (process.env.OPENROUTER_PRESET || process.env.OPENROUTER_FATURA_PRESET || VARSAYILAN_FATURA_PRESET).trim();
  return ham.startsWith("@preset/") ? ham : `@preset/${ham}`;
}

export function faturaPrizZamanSiniri(): number {
  const deger = Number(process.env.OPENROUTER_FATURA_TIMEOUT_MS ?? 240_000);
  return Number.isFinite(deger) && deger >= 30_000 && deger <= 900_000 ? deger : 240_000;
}

export function faturaPrizBasliklari(anahtar: string): Record<string, string> {
  if (geminiPrizAktifMi()) {
    return { "Content-Type": "application/json" };
  }
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${anahtar}`,
    "HTTP-Referer": "https://vixrex.com",
    "X-Title": "Vixrex Fatura",
  };
}

function dataUrlToGeminiPart(url: string): Record<string, unknown> {
  const eslesme = /^data:([^;,]+)(?:;[^,]*)?;base64,([\s\S]+)$/.exec(url);
  if (eslesme) {
    return { inlineData: { mimeType: eslesme[1], data: eslesme[2] } };
  }
  return { fileData: { fileUri: url } };
}

function icerikParcasiniCevir(parca: unknown): Record<string, unknown> | null {
  if (typeof parca === "string") return { text: parca };
  if (!parca || typeof parca !== "object") return null;
  const o = parca as Record<string, unknown>;
  if (o.type === "text" && typeof o.text === "string") {
    return { text: o.text };
  }
  if (o.type === "image_url" && o.image_url && typeof o.image_url === "object") {
    const url = (o.image_url as Record<string, unknown>).url;
    if (typeof url === "string" && url) return dataUrlToGeminiPart(url);
  }
  if (o.type === "file" && o.file && typeof o.file === "object") {
    const fileData = (o.file as Record<string, unknown>).file_data;
    if (typeof fileData === "string" && fileData) return dataUrlToGeminiPart(fileData);
  }
  return null;
}

function mesajParcalarListesi(icerik: unknown): Array<Record<string, unknown>> {
  if (typeof icerik === "string") return icerik ? [{ text: icerik }] : [];
  if (!Array.isArray(icerik)) return [];
  return icerik.map(icerikParcasiniCevir).filter((p): p is Record<string, unknown> => p !== null);
}

export function geminiGovdesineCevir(govde: Record<string, unknown>): Record<string, unknown> {
  if (Array.isArray(govde.contents) || !Array.isArray(govde.messages)) return govde;
  const contents: Array<{ role: string; parts: Array<Record<string, unknown>> }> = [];
  const systemParts: Array<Record<string, unknown>> = [];
  for (const mesaj of govde.messages) {
    if (!mesaj || typeof mesaj !== "object") continue;
    const m = mesaj as Record<string, unknown>;
    const parts = mesajParcalarListesi(m.content);
    if (!parts.length) continue;
    if (m.role === "system") {
      systemParts.push(...parts);
      continue;
    }
    contents.push({ role: m.role === "assistant" ? "model" : "user", parts });
  }
  const sonuc: Record<string, unknown> = { contents };
  if (systemParts.length) sonuc.systemInstruction = { parts: systemParts };
  const rf = govde.response_format as Record<string, unknown> | undefined;
  if (rf && typeof rf === "object") {
    const rfType = String(rf.type ?? "");
    if (rfType === "json_schema") {
      const jsonSchemaObj = rf.json_schema as Record<string, unknown> | undefined;
      const sema = jsonSchemaObj && typeof jsonSchemaObj === "object" ? jsonSchemaObj.schema : undefined;
      sonuc.generationConfig = {
        responseMimeType: "application/json",
        ...(sema && typeof sema === "object" ? { responseJsonSchema: sema } : {}),
      };
    } else if (rfType === "json_object") {
      sonuc.generationConfig = { responseMimeType: "application/json" };
    }
  }
  return sonuc;
}

async function geminiYanitiniOpenRouterBicimineCevir(yanit: Response): Promise<Response> {
  if (!yanit.ok || typeof yanit.clone !== "function") return yanit;
  const veri = await yanit.clone().json().catch(() => null) as Record<string, unknown> | null;
  if (!veri || !Array.isArray(veri.candidates) || Array.isArray(veri.choices)) return yanit;
  const aday = (veri.candidates[0] ?? {}) as Record<string, unknown>;
  const icerikNesnesi = (aday.content ?? {}) as Record<string, unknown>;
  const hamParcalar = Array.isArray(icerikNesnesi.parts) ? icerikNesnesi.parts : [];
  const metinParcalari = hamParcalar
    .filter((p): p is Record<string, unknown> => Boolean(p && typeof p === "object" && typeof (p as Record<string, unknown>).text === "string" && (p as Record<string, unknown>).thought !== true))
    .map((p) => String(p.text));
  const icerik = metinParcalari.join("");
  const hamNeden = typeof aday.finishReason === "string" ? aday.finishReason : "STOP";
  const finishReason = hamNeden === "MAX_TOKENS" ? "length" : hamNeden === "STOP" ? "stop" : "content_filter";
  const usageMeta = (veri.usageMetadata ?? {}) as Record<string, unknown>;
  const openrouterYanit = {
    id: typeof veri.responseId === "string" ? veri.responseId : null,
    model: typeof veri.modelVersion === "string" ? veri.modelVersion : "gemini-2.5-flash",
    choices: [{
      finish_reason: finishReason,
      message: {
        content: icerik,
        ...(finishReason === "content_filter" && !icerik ? { refusal: hamNeden } : {}),
      },
    }],
    usage: {
      prompt_tokens: Number(usageMeta.promptTokenCount ?? 0),
      completion_tokens: Number(usageMeta.candidatesTokenCount ?? 0),
      ...(usageMeta.thoughtsTokenCount !== undefined
        ? { completion_tokens_details: { reasoning_tokens: Number(usageMeta.thoughtsTokenCount ?? 0) } }
        : {}),
    },
  };
  return new Response(JSON.stringify(openrouterYanit), {
    status: yanit.status,
    statusText: yanit.statusText,
    headers: { "Content-Type": "application/json" },
  });
}

export async function faturaPrizIstegiGonder(govde: Record<string, unknown>): Promise<Response> {
  const anahtar = faturaPrizAnahtari();
  if (!anahtar) throw new Error("OKUYUCU_HAZIR_DEGIL");
  const geminiAktif = geminiPrizAktifMi();
  const istekGovdesi = geminiAktif ? geminiGovdesineCevir(govde) : govde;
  try {
    const yanit = await fetch(faturaPrizAdresi(), {
      method: "POST",
      headers: faturaPrizBasliklari(anahtar),
      body: JSON.stringify(istekGovdesi),
      signal: AbortSignal.timeout(faturaPrizZamanSiniri()),
    });
    return geminiAktif ? await geminiYanitiniOpenRouterBicimineCevir(yanit) : yanit;
  } catch (hata) {
    if (hata instanceof Error && ["TimeoutError", "AbortError"].includes(hata.name)) {
      throw new Error("OKUYUCU_ZAMAN_ASIMI");
    }
    throw new Error("OKUYUCU_CEVAP_VERMEDI", { cause: hata });
  }
}