import "server-only";
import { getSupabaseAdmin } from "./supabaseAdmin";

export interface ServerAssistantMessage {
  role: "assistant" | "user";
  message_text: string;
  message_key: string | null;
}

export interface ServerAssistantHistory {
  conversationId: string | null;
  messages: ServerAssistantMessage[];
}

const BOS: ServerAssistantHistory = { conversationId: null, messages: [] };

export async function loadAssistantMessagesForStore(
  slug: string,
  expectedStoreId?: string | null,
): Promise<ServerAssistantHistory> {
  const temizSlug = slug.trim();
  if (!temizSlug) return BOS;

  try {
    const admin = getSupabaseAdmin();
    const { data: store, error: storeError } = await admin
      .from("stores")
      .select("id, user_id")
      .eq("slug", temizSlug)
      .maybeSingle();
    if (storeError) {
      console.warn("[assistant-history] vitrin okunamadı", storeError.message);
      return BOS;
    }

    const storeId = (store as { id?: string | null } | null)?.id;
    if (!storeId) return BOS;
    if (expectedStoreId && storeId !== expectedStoreId) return BOS;

    if (!expectedStoreId) return BOS;

    const userId = (store as { user_id?: string | null } | null)?.user_id;
    if (!userId) return BOS;

    const { data: conversation, error: conversationError } = await admin
      .from("assistant_conversations")
      .select("id")
      .eq("user_id", userId)
      .maybeSingle();
    if (conversationError) {
      console.warn("[assistant-history] konuşma okunamadı", conversationError.message);
      return BOS;
    }

    const conversationId = (conversation as { id?: string } | null)?.id;
    if (!conversationId) return BOS;

    const { data: rows, error: messagesError } = await admin
      .from("assistant_messages")
      .select("role, message_key, message_text")
      .eq("conversation_id", conversationId)
      .order("seq", { ascending: false })
      .limit(500);
    if (messagesError || !Array.isArray(rows)) {
      if (messagesError) {
        console.warn("[assistant-history] mesajlar okunamadı", messagesError.message);
      }
      return BOS;
    }

    const messages = (rows as Array<{
      role: string;
      message_key: string | null;
      message_text: string;
    }>)
      .reverse()
      .map((row) => ({
        role: row.role === "assistant" ? "assistant" : "user",
        message_text: row.message_text,
        message_key: row.message_key ?? null,
      })) as ServerAssistantMessage[];

    return { conversationId, messages };
  } catch (error) {
    console.warn(
      "[assistant-history] konuşma geçmişi okunamadı",
      error instanceof Error ? error.message : error,
    );
    return BOS;
  }
}

export async function loadOwnerFlowStateForStore(
  slug: string,
  expectedStoreId?: string | null,
): Promise<Record<string, unknown> | null> {
  const temizSlug = slug.trim();
  if (!temizSlug || !expectedStoreId) return null;

  try {
    const admin = getSupabaseAdmin();
    const { data: store, error: storeError } = await admin
      .from("stores")
      .select("id, user_id")
      .eq("slug", temizSlug)
      .maybeSingle();
    if (storeError || !store) return null;

    const storeId = (store as { id?: string | null }).id;
    if (!storeId || storeId !== expectedStoreId) return null;

    const userId = (store as { user_id?: string | null }).user_id;
    if (!userId) return null;

    const { data: flow, error: flowError } = await admin
      .from("owner_flow_states")
      .select("current_step")
      .eq("user_id", userId)
      .maybeSingle();
    if (flowError || !flow) return null;

    const currentStep = (flow as { current_step?: string | null }).current_step;
    if (typeof currentStep !== "string" || !currentStep.trim()) return null;
    return { current_step: currentStep };
  } catch {
    return null;
  }
}
