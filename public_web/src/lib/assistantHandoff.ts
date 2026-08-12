// Vixrex Asistan güvenli handoff — sunucudan gelen konuşma özeti (v1).
//
// Şema kaynağı: supabase/migrations/20260811180000_assistant_handoff_core.sql
// (sanitize_assistant_handoff). Veri zaten sunucuda izin listeli, boyutu
// sınırlı ve sır alanlarından (edit_token/session_token/ocode) arındırılmış
// olarak üretilir — bu dosya yalnız istemci tarafında ikinci bir savunma
// katmanı olarak şekli doğrular, GÖSTERMEK dışında bir işlem yapmaz.

export interface AssistantHandoffMessageV1 {
  role: "assistant" | "user";
  text: string;
}

export interface AssistantHandoffV1 {
  version: 1;
  completedSteps: string[];
  nextStep: string | null;
  messages: AssistantHandoffMessageV1[];
}

/**
 * RPC'den (get_working_draft_for_session) gelen ham JSON'ı ayrıştırır.
 * Beklenmeyen şekil (eski sürüm, bozuk veri, boş geçmiş) sessizce `null`
 * döner — asistan paneli bu durumda normal karşılama akışına düşer,
 * hata fırlatmaz veya kullanıcıyı bloklamaz.
 */
export function parseAssistantHandoff(raw: unknown): AssistantHandoffV1 | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as Record<string, unknown>;
  if (data.version !== 1) return null;
  if (!Array.isArray(data.messages)) return null;

  const messages: AssistantHandoffMessageV1[] = [];
  for (const item of data.messages) {
    if (!item || typeof item !== "object") continue;
    const { role, text } = item as Record<string, unknown>;
    if ((role !== "assistant" && role !== "user") || typeof text !== "string") {
      continue;
    }
    const trimmed = text.trim();
    if (!trimmed) continue;
    messages.push({ role, text: trimmed });
  }
  if (messages.length === 0) return null;

  const completedSteps = Array.isArray(data.completed_steps)
    ? data.completed_steps.filter((s): s is string => typeof s === "string")
    : [];
  const nextStep = typeof data.next_step === "string" ? data.next_step : null;

  return { version: 1, completedSteps, nextStep, messages };
}
