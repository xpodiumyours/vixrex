import "server-only";

import { getSupabaseAdmin } from "@/lib/supabaseAdmin";
import {
  smartEngineBlogEnabledFromRows,
  smartEngineStorefrontEnabledFromRows,
  type SmartEngineFlagRow,
} from "@/lib/smartEngineFlags";

async function readSmartEngineFlagRows(): Promise<SmartEngineFlagRow[] | null> {
  try {
    const admin = getSupabaseAdmin();
    const { data, error } = await admin.rpc("get_feature_flags");

    if (error) {
      console.error("[smart-engine] feature flag read failed:", error.message);
      return null;
    }
    return Array.isArray(data) ? (data as SmartEngineFlagRow[]) : null;
  } catch (error) {
    console.error("[smart-engine] feature flag service unavailable", error);
    return null;
  }
}

/** Secret/RPC/DB hatası veya eksik flag = OFF. */
export async function smartEngineStorefrontServerEnabled(): Promise<boolean> {
  return smartEngineStorefrontEnabledFromRows(await readSmartEngineFlagRows());
}

/** Blog capability de server tarafında global + blog flag ile fail-closed. */
export async function smartEngineBlogServerEnabled(): Promise<boolean> {
  return smartEngineBlogEnabledFromRows(await readSmartEngineFlagRows());
}
