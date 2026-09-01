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

export async function loadSharedAssistantContext(): Promise<SharedAssistantContext> {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session || session.user.is_anonymous) {
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
    messages: Array.isArray(conversation.messages) ? conversation.messages : [],
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
