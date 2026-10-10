import "server-only";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

let adminClient: SupabaseClient | null = null;

export function getSupabaseAdmin() {
  if (adminClient) return adminClient;

  const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl) {
    throw new Error("SUPABASE_URL is missing");
  }

  // Fail closed: PR #672'nin Preview işlemleri üretim DB'ye yazamaz.
  if (process.env.VERCEL_ENV === "preview" &&
    ["fix/fatura-cerrahi-birlesik-20261010", "fix/uretici-arastirma-izleme-20261010"].includes(process.env.VERCEL_GIT_COMMIT_REF ?? "") &&
    supabaseUrl !== "https://nfivinvdlxhyxsoxzarh.supabase.co") {
    throw new Error("MP_CER_PREVIEW_DB_MUST_BE_ISOLATED");
  }

  if (!serviceRoleKey) {
    throw new Error("SUPABASE_SERVICE_ROLE_KEY is missing");
  }

  adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  return adminClient;
}
