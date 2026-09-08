"use client";

import { supabase } from "@/lib/supabase";
import { vixRexIntentSemasi, vixRexMesajlari } from "@/lib/vixrexMesajlari";

export type SharedAssistantMessage = {
  id: string;
  seq: number;
  role: "assistant" | "user";
  message_text: string;
  message_key?: string | null;
  created_at?: string;
};

export type SharedAssistantContext = {
  authenticated: boolean;
  conversationId: string | null;
  messages: SharedAssistantMessage[];
  hasStore: boolean;
  flowState: Record<string, unknown> | null;
};

function normalize(text: string): string {
  return text
    .toLocaleLowerCase("tr-TR")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replaceAll("ı", "i");
}

export function sharedAssistantReply(input: string): { key: string; text: string } {
  const normalized = normalize(input);
  const intent = vixRexIntentSemasi.find((candidate) =>
    candidate.anahtarKelimeler.some((keyword) => normalized.includes(normalize(keyword)))
  );
  const key = intent?.payload === "merhaba" ? "setup_invite" : intent?.payload ?? "anlasilamadi";
  return {
    key,
    text: vixRexMesajlari[key] ?? vixRexMesajlari.anlasilamadi,
  };
}

async function ensureConversation(): Promise<string | null> {
  const { data, error } = await supabase.rpc("ensure_assistant_conversation");
  if (error) throw error;
  const id = (data as { id?: string } | null)?.id;
  return typeof id === "string" ? id : null;
}

/**
 * Tek konuşma köprüsü (UI/UX cilası devamı, 2026-09-02) — landing, Keşfet
 * ve sahip paneli aynı `assistant_conversations` satırını paylaşabilsin
 * diye landing artık ilk gerçek niyet anında (ör. "Hazır Vitrin Seç")
 * sessizce anonim bir Supabase Auth oturumu açar. Kullanıcı sonra Google
 * ile `linkIdentity()` yaparsa (bkz. OwnerWorkspaceShell "hesabına bağla",
 * rent_demo_canonical akışı) auth.uid() DEĞİŞMEZ — aynı konuşma taşınır.
 * Salt gezinen, hiç niyet seçmeyen ziyaretçi için oturum açılmaz.
 */
export async function ensureAnonymousSession(): Promise<boolean> {
  const { data: { session } } = await supabase.auth.getSession();
  if (session) return true;
  const { error } = await supabase.auth.signInAnonymously();
  return !error;
}

/** Ham mesaj ekleme — `sendSharedAssistantMessage`'ın aksine metni NLP
 * eşleşmesiyle üretmez, çağıran taraf (landing akışı gibi) metni kendi
 * belirler. Hata sessizce yutulur — konuşma köprüsü, akışı bloklamaz. */
export async function appendRawSharedAssistantMessage(
  conversationId: string,
  role: SharedAssistantMessage["role"],
  text: string,
  messageKey: string | null = null,
): Promise<void> {
  try {
    await appendMessage(conversationId, role, text, messageKey);
  } catch {
    // Anonim oturum reddedilirse veya ağ hatası olursa sessizce yut.
  }
}

export { ensureConversation as ensureSharedAssistantConversation };

/**
 * Tek-kaynak kuralı (kanonik: Flutter Web): sohbette yalnız katalog damgalı
 * asistan satırları çizilir. `message_key` taşıyan her satır
 * `shared/vixrex_mesajlar.json` karşılığına bağlanır; damgasız asistan
 * satırları katalog-öncesi iç-durum dökümleridir (alan tik listeleri gibi)
 * ve kullanıcıya gösterilmez. Kullanıcı satırları her zaman geçer.
 */
export function isDisplayableAssistantMessage(
  message: Pick<SharedAssistantMessage, "role" | "message_key">,
): boolean {
  if (message.role === "user") return true;
  return message.message_key !== null && message.message_key !== undefined;
}

export function selectDisplayableMessages(
  messages: SharedAssistantMessage[],
): SharedAssistantMessage[] {
  return messages.filter(isDisplayableAssistantMessage);
}

export async function loadSharedAssistantContext(): Promise<SharedAssistantContext> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) {
    return {
      authenticated: false,
      conversationId: null,
      messages: [],
      hasStore: false,
      flowState: null,
    };
  }

  const conversationId = await ensureConversation();
  const [{ data: bootstrapData, error: bootstrapError }, { data: conversationData, error: conversationError }] = await Promise.all([
    supabase.rpc("get_owner_workspace_bootstrap"),
    supabase.rpc("get_assistant_conversation"),
  ]);
  if (bootstrapError) throw bootstrapError;
  if (conversationError) throw conversationError;
  const bootstrap = (bootstrapData ?? {}) as {
    store?: Record<string, unknown> | null;
    flow_state?: Record<string, unknown> | null;
  };
  const conversation = (conversationData ?? {}) as {
    id?: string;
    messages?: SharedAssistantMessage[];
  };
  return {
    authenticated: true,
    conversationId: conversation.id ?? conversationId,
    messages: selectDisplayableMessages(
      Array.isArray(conversation.messages) ? conversation.messages : [],
    ),
    hasStore: Boolean(bootstrap.store),
    flowState: bootstrap.flow_state ?? null,
  };
}

async function appendMessage(
  conversationId: string,
  role: SharedAssistantMessage["role"],
  text: string,
  messageKey: string | null,
): Promise<SharedAssistantMessage> {
  const clientId = `next-${crypto.randomUUID()}`;
  const { data, error } = await supabase.rpc("append_assistant_message", {
    p_conversation_id: conversationId,
    p_client_message_id: clientId,
    p_role: role,
    p_message_key: messageKey,
    p_message_text: text,
    p_catalog_snapshot: messageKey ? vixRexMesajlari[messageKey] ?? null : null,
  });
  if (error) throw error;
  return data as SharedAssistantMessage;
}

export async function sendSharedAssistantMessage(
  conversationId: string,
  input: string,
): Promise<[SharedAssistantMessage, SharedAssistantMessage]> {
  const text = input.trim();
  if (!text) throw new Error("EMPTY_MESSAGE");
  const user = await appendMessage(conversationId, "user", text, null);
  const reply = sharedAssistantReply(text);
  const assistant = await appendMessage(
    conversationId,
    "assistant",
    reply.text,
    reply.key,
  );
  return [user, assistant];
}
