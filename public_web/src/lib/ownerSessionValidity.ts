import { createHash } from "node:crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { OwnerSession } from "@/lib/ownerSession";

/**
 * İmzalı çerez tek başına yetki değildir: owner_sessions kaydı da hâlâ
 * tüketilmiş ve süresi dolmamış olmalıdır. Bu okuma oturum süresini uzatmaz.
 * DB hatası veya eksik kayıt erişim vermez (fail-closed).
 */
export async function ownerSessionStillActive(
  admin: SupabaseClient,
  session: OwnerSession,
): Promise<boolean> {
  try {
    const tokenHash = createHash("sha256")
      .update(session.sessionToken, "utf8")
      .digest("hex");
    const { data, error } = await admin
      .from("owner_sessions")
      .select("store_id")
      .eq("session_token_hash", tokenHash)
      .eq("store_id", session.storeId)
      .not("consumed_at", "is", null)
      .gt("expires_at", new Date().toISOString())
      .maybeSingle();

    if (error) {
      console.error("[owner-session] session lookup failed", {
        code: error.code ?? "OWNER_SESSION_LOOKUP_FAILED",
      });
      return false;
    }
    return data?.store_id === session.storeId;
  } catch {
    console.error("[owner-session] session lookup failed", {
      code: "OWNER_SESSION_LOOKUP_EXCEPTION",
    });
    return false;
  }
}
