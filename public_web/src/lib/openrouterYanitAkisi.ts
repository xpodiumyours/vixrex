/** Yalnız OpenRouter SSE taşıması; ürün verisi/araştırma kararı üretmez. */
interface OpenRouterUsage extends Record<string, unknown> {
  completion_tokens_details?: { reasoning_tokens?: number };
}

export interface OpenRouterBirlesikYanit {
  id?: string;
  model?: string;
  error?: { code?: number | string; message?: string };
  choices?: Array<{ finish_reason: string | null; message: { content: string; tool_calls?: unknown[]; refusal?: string } }>;
  usage?: OpenRouterUsage;
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
  const toolCalls: unknown[] = [];
  function event(block: string): void {
    const data = block.split("\n").filter((l) => l.startsWith("data:"))
      .map((l) => l.slice(5).replace(/^ /, "")).join("\n");
    if (!data) return;
    if (data.trim() === "[DONE]") { doneEvent = true; return; }
    let chunk: Record<string, unknown>;
    try { chunk = JSON.parse(data); } catch { throw new Error("OKUYUCU_EKSIK_CEVAP"); }
    if (chunk.error) {
      const error = typeof chunk.error === "object" ? chunk.error as { code?: unknown } : {};
      throw new Error(Number(error.code) === 404 ? "OKUYUCU_MODEL_BULUNAMADI" : "OKUYUCU_CEVAP_VERMEDI");
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
    if (Array.isArray(delta.tool_calls)) toolCalls.push(...delta.tool_calls);
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
