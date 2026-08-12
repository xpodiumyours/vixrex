import type { HazirlikRaporu } from "./vitrinReadiness";

const COMPLETED_STEPS = [
  "name",
  "category",
  "whatsapp",
  "location",
  "legal",
  "publishing",
] as const;
const NEXT_STEPS = [...COMPLETED_STEPS, "done"] as const;
const SECRET_KEY = /^(edit_token|session_token|ocode)$/i;
const SECRET_TEXT = /(edit_token|session_token|ocode)\s*[:=]/i;
const MAX_HANDOFF_BYTES = 16 * 1024;

export type AssistantHandoffStep = (typeof NEXT_STEPS)[number];

export interface AssistantHandoffMessage {
  role: "assistant" | "user";
  text: string;
}

export interface AssistantHandoffV1 {
  version: 1;
  completed_steps: Array<(typeof COMPLETED_STEPS)[number]>;
  next_step: AssistantHandoffStep | null;
  messages: AssistantHandoffMessage[];
}

export interface OwnerChatMessage {
  id: number;
  kimden: "asistan" | "kullanici";
  metin: string;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function containsSecretKey(value: unknown): boolean {
  if (Array.isArray(value)) return value.some(containsSecretKey);
  if (!isRecord(value)) return false;
  return Object.entries(value).some(
    ([key, child]) => SECRET_KEY.test(key) || containsSecretKey(child)
  );
}

function isCompletedStep(value: unknown): value is (typeof COMPLETED_STEPS)[number] {
  return typeof value === "string" && COMPLETED_STEPS.includes(value as never);
}

function isNextStep(value: unknown): value is AssistantHandoffStep {
  return typeof value === "string" && NEXT_STEPS.includes(value as never);
}

/**
 * CORE'dan gelen JSON'u Server Component → Client Component sınırında
 * yalnız izin verilen, serileştirilebilir handoff_v1 alanlarına indirger.
 */
export function parseAssistantHandoff(value: unknown): AssistantHandoffV1 | null {
  if (!isRecord(value) || containsSecretKey(value)) return null;

  try {
    if (new TextEncoder().encode(JSON.stringify(value)).byteLength > MAX_HANDOFF_BYTES) {
      return null;
    }
  } catch {
    return null;
  }

  if (value.version !== 1) return null;
  if (!Array.isArray(value.completed_steps) || value.completed_steps.length > 6) {
    return null;
  }
  if (!value.completed_steps.every(isCompletedStep)) return null;
  if (new Set(value.completed_steps).size !== value.completed_steps.length) return null;
  if (value.next_step !== null && !isNextStep(value.next_step)) return null;
  if (!Array.isArray(value.messages) || value.messages.length > 24) return null;

  const messages: AssistantHandoffMessage[] = [];
  for (const message of value.messages) {
    if (!isRecord(message)) return null;
    if (message.role !== "assistant" && message.role !== "user") return null;
    if (typeof message.text !== "string") return null;
    const text = message.text.trim();
    if (!text || Array.from(text).length > 500 || SECRET_TEXT.test(text)) return null;
    messages.push({ role: message.role, text });
  }

  return {
    version: 1,
    completed_steps: [...value.completed_steps],
    next_step: value.next_step,
    messages,
  };
}

const STEP_CONTINUATION: Record<Exclude<AssistantHandoffStep, "done">, string> = {
  name: "İşletme adı adımından kaldığımız yerden devam edelim.",
  category: "İşletme kategorisi adımından kaldığımız yerden devam edelim.",
  whatsapp: "WhatsApp bilgisi adımından kaldığımız yerden devam edelim.",
  location: "Konum bilgisi adımından kaldığımız yerden devam edelim.",
  legal: "Yasal onay adımından kaldığımız yerden devam edelim.",
  publishing: "Yayınlama adımından kaldığımız yerden devam edelim.",
};

const EDIT_PROMPT =
  "Değiştirmek istediğin yazıya vitrinde tıkla — buradan düzenleriz.";

function readinessMessages(rapor: HazirlikRaporu): Array<Omit<OwnerChatMessage, "id">> {
  const greeting = rapor.temelTamam
    ? `Vitrinin yayına hazır görünüyor. Doluluk: %${rapor.yuzde}.`
    : `Vitrininin doluluk oranı %${rapor.yuzde}. Birkaç alan eksik.`;
  return [
    { kimden: "asistan", metin: greeting },
    ...(rapor.sonrakiAdim
      ? [{ kimden: "asistan" as const, metin: rapor.sonrakiAdim }]
      : []),
    { kimden: "asistan", metin: EDIT_PROMPT },
  ];
}

/** Geçerli handoff varsa konuşmayı taşır; yoksa mevcut hazırlık akışını korur. */
export function ownerChatInitialMessages(
  rapor: HazirlikRaporu,
  handoff: AssistantHandoffV1 | null
): OwnerChatMessage[] {
  const initial: Array<Omit<OwnerChatMessage, "id">> = handoff
    ? handoff.messages.map((message) => ({
        kimden: message.role === "assistant" ? "asistan" : "kullanici",
        metin: message.text,
      }))
    : readinessMessages(rapor);

  if (handoff) {
    const continuation =
      handoff.next_step && handoff.next_step !== "done"
        ? STEP_CONTINUATION[handoff.next_step]
        : rapor.sonrakiAdim;
    if (continuation && initial.at(-1)?.metin !== continuation) {
      initial.push({ kimden: "asistan", metin: continuation });
    }
    if (initial.at(-1)?.metin !== EDIT_PROMPT) {
      initial.push({ kimden: "asistan", metin: EDIT_PROMPT });
    }
  }

  return initial.map((message, index) => ({ id: index + 1, ...message }));
}
