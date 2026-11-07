/** Yalnız OpenRouter SSE taşıması; ürün verisi/araştırma kararı üretmez. */
interface OpenRouterUsage extends Record<string, unknown> {
  completion_tokens_details?: { reasoning_tokens?: number };
}

export interface AracCagrisi {
  id?: string;
  type?: string;
  function: { name?: string; arguments: string };
}

export interface OpenRouterBirlesikYanit {
  id?: string;
  model?: string;
  error?: { code?: number | string; message?: string };
  choices?: Array<{ finish_reason: string | null; message: { content: string; tool_calls?: AracCagrisi[]; refusal?: string } }>;
  usage?: OpenRouterUsage;
}

export function openrouterHataKodu(code: unknown, message?: string): string {
  const sayisal = Number(code);
  if (sayisal === 401 || sayisal === 403) return "OKUYUCU_ANAHTAR_GECERSIZ";
  if (sayisal === 402 || code === "insufficient_quota") return "OKUYUCU_BAKIYE_BITTI";
  if (sayisal === 429) {
    return message?.includes("free-models-per-day") ? "OKUYUCU_UCRETSIZ_KOTA_DOLDU" : "OKUYUCU_ISTEK_SINIRI";
  }
  if (sayisal === 404) return "OKUYUCU_MODEL_BULUNAMADI";
  return "OKUYUCU_CEVAP_VERMEDI";
}

export async function openrouterYanitiniOku(response: Response): Promise<OpenRouterBirlesikYanit | null> {
  if (!response.headers?.get("content-type")?.includes("text/event-stream")) {
    return response.json().catch(() => null);
  }
  if (!response.body) throw new Error("OKUYUCU_EKSIK_CEVAP");
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let pending = "", content = "", id: string | undefined, model: string | undefined;
  let finish: string | null = null, doneEvent = false, refusal: string | undefined;
  let usage: OpenRouterUsage | undefined;
  const toolCalls: AracCagrisi[] = [];
  function event(block: string): void {
    const data = block.split("\n").filter((l) => l.startsWith("data:"))
      .map((l) => l.slice(5).replace(/^ /, "")).join("\n");
    if (!data) return;
    if (data.trim() === "[DONE]") { doneEvent = true; return; }
    let chunk: Record<string, unknown>;
    try { chunk = JSON.parse(data); } catch { throw new Error("OKUYUCU_EKSIK_CEVAP"); }
    if (chunk.error) {
      const error = typeof chunk.error === "object" ? chunk.error as { code?: unknown; message?: string } : {};
      throw new Error(openrouterHataKodu(error.code, error.message));
    }
    if (typeof chunk.id === "string") id = chunk.id;
    if (typeof chunk.model === "string") model = chunk.model;
    if (chunk.usage && typeof chunk.usage === "object") usage = chunk.usage as Record<string, unknown>;
    if (!Array.isArray(chunk.choices)) return;
    const choice = chunk.choices.find((c) => c?.index === 0) ?? chunk.choices[0];
    if (!choice) return;
    if (typeof choice.finish_reason === "string") finish = choice.finish_reason;
    if (finish === "error") throw new Error("OKUYUCU_CEVAP_VERMEDI");
    const delta = choice.delta ?? {};
    if (typeof delta.content === "string") content += delta.content;
    if (content.length > 5_000_000) throw new Error("OKUYUCU_EKSIK_CEVAP");
    if (typeof delta.refusal === "string") refusal = (refusal ?? "") + delta.refusal;
    if (Array.isArray(delta.tool_calls)) {
      for (const ham of delta.tool_calls) {
        if (!ham || typeof ham !== "object") continue;
        const parca = ham as { index?: number; id?: string; type?: string; function?: { name?: string; arguments?: string } };
        const sira = typeof parca.index === "number" ? parca.index : toolCalls.length;
        const hedef = toolCalls[sira] ?? (toolCalls[sira] = { function: { arguments: "" } });
        if (parca.id) hedef.id = parca.id;
        if (parca.type) hedef.type = parca.type;
        if (parca.function?.name) hedef.function.name = parca.function.name;
        if (typeof parca.function?.arguments === "string") hedef.function.arguments += parca.function.arguments;
      }
    }
  }
  try {
    for (;;) {
      const { value, done } = await reader.read();
      pending += done ? decoder.decode() : decoder.decode(value, { stream: true });
      pending = pending.replace(/\r\n/g, "\n");
      let boundary: number;
      while ((boundary = pending.indexOf("\n\n")) !== -1) {
        event(pending.slice(0, boundary)); pending = pending.slice(boundary + 2);
      }
      if (pending.length > 5_000_000) throw new Error("OKUYUCU_EKSIK_CEVAP");
      if (done) break;
    }
    if (pending.trim()) event(pending);
    if (!doneEvent || !finish) throw new Error("OKUYUCU_EKSIK_CEVAP");
    return { id, model, usage, choices: [{ finish_reason: finish, message: {
      content, ...(toolCalls.length ? { tool_calls: toolCalls } : {}), ...(refusal ? { refusal } : {}),
    } }] };
  } finally { reader.releaseLock(); }
}
