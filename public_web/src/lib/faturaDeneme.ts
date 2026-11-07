import { createHash } from "node:crypto";
import type { SupabaseClient } from "@supabase/supabase-js";

export type HataSinifi = "none" | "transient" | "permanent";

export type DenemeOlayi = {
  jobId: string;
  storeId: string;
  stage: "reading" | "cards" | "save";
  attempt: number;
  fromState?: string | null;
  toState?: string | null;
  reasonCode?: string | null;
  errorClass?: HataSinifi;
  httpStatus?: number | null;
  retryAfterMs?: number | null;
  durationMs?: number | null;
  model?: string | null;
  responseBytes?: number | null;
  bodySha256?: string | null;
};

export const EN_FAZLA_DENEME = 3;

export function govdeOzeti(govde: string): string {
  return createHash("sha256").update(govde, "utf8").digest("hex");
}

export function saglayiciHataKodu(http: number): string {
  if (http === 401 || http === 403) return "ANAHTAR_GECERSIZ";
  if (http === 402) return "KREDI_YOK";
  if (http === 429) return "OKUYUCU_YOGUN";
  if (http >= 500) return "OKUYUCU_GECICI_HATA";
  return "OKUYUCU_ISTEGI_GECERSIZ";
}

export async function hataSinifi(
  admin: SupabaseClient,
  http: number | null,
  kod: string | null,
): Promise<HataSinifi> {
  const { data, error } = await admin.rpc("invoice_error_class", { p_http: http, p_code: kod });
  if (error) return kod ? "permanent" : "none";
  return data === "transient" || data === "permanent" ? data : "none";
}

export async function beklemeMs(
  admin: SupabaseClient,
  deneme: number,
  retryAfterMs: number | null,
): Promise<number> {
  const { data, error } = await admin.rpc("invoice_backoff_ms", {
    p_attempt: deneme,
    p_class: "transient",
    p_retry_after_ms: retryAfterMs,
  });
  const ms = Number(data);
  if (error || !Number.isFinite(ms)) return 2000;
  return Math.min(60000, Math.max(0, Math.round(ms)));
}

export async function olayYaz(admin: SupabaseClient, olay: DenemeOlayi): Promise<void> {
  const { error } = await admin.rpc("record_invoice_job_event", {
    p_job_id: olay.jobId,
    p_store_id: olay.storeId,
    p_stage: olay.stage,
    p_attempt: olay.attempt,
    p_from_state: olay.fromState ?? null,
    p_to_state: olay.toState ?? null,
    p_reason_code: olay.reasonCode ?? null,
    p_error_class: olay.errorClass ?? "none",
    p_http_status: olay.httpStatus ?? null,
    p_retry_after_ms: olay.retryAfterMs ?? null,
    p_duration_ms: olay.durationMs ?? null,
    p_model: olay.model ?? null,
    p_response_bytes: olay.responseBytes ?? null,
    p_body_sha256: olay.bodySha256 ?? null,
  });
  if (error) console.error("[fatura-olay] yazilamadi:", error.code ?? "hata");
}

export async function kartDenemesiniTekrarla(
  admin: SupabaseClient,
  istek: { storeId: string; islemKimligi: string; deneme: number; govde: Record<string, unknown> },
): Promise<boolean> {
  if (istek.deneme >= EN_FAZLA_DENEME) return false;
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) return false;
  const bekleme = await beklemeMs(admin, istek.deneme, null);
  if (bekleme > 0) await new Promise((coz) => setTimeout(coz, bekleme));
  const { data, error } = await admin.rpc("retry_invoice_provider_job", {
    p_store_id: istek.storeId,
    p_job_id: istek.islemKimligi,
    p_body: istek.govde,
    p_api_key: anahtar,
  });
  if (error) return false;
  return (data as { success?: boolean } | null)?.success === true;
}
