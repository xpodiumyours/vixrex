import "server-only";

import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import { smartEngineStorefrontEnabledFromRows } from "@/lib/smartEngineFlags";

/**
 * Authoritative runtime guard.
 *
 * `get_feature_flags()` + service-role üzerinden yalnız server'da okunur.
 * Secret/RPC/DB hatası veya eksik flag = OFF. Hiçbir hata motoru açamaz.
 */
export async function smartEngineStorefrontServerEnabled(): Promise<boolean> {
  try {
    const admin = getSupabaseAdmin();
    const { data, error } = await admin.rpc("get_feature_flags");

    if (error) {
      console.error("[smart-engine] feature flag read failed:", error.message);
      return false;
    }

    return smartEngineStorefrontEnabledFromRows(
      Array.isArray(data) ? data : null
    );
  } catch (error) {
    console.error("[smart-engine] feature flag service unavailable", error);
    return false;
  }
}
