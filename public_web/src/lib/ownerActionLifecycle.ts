import type { SmartEngineCommandResult } from "./smartEngineCommandClient";

export type OwnerActionLifecycleStatus =
  | "no_op"
  | "needs_input"
  | "succeeded"
  | "failed"
  | "partial_result"
  | "queued_offline";

export interface OwnerActionLifecycleResult {
  status: OwnerActionLifecycleStatus;
  commandId?: string;
  code?: string;
}

export const OWNER_ACTION_LIFECYCLE_EVENT = "vixrex:owner-action-lifecycle";

export function ownerLifecycleFromCommand(
  result: SmartEngineCommandResult,
): OwnerActionLifecycleResult {
  return {
    status: result.status,
    commandId: result.commandId,
    code: result.failed[0]?.code,
  };
}

export function ownerLifecycleRequiresAttention(
  result: OwnerActionLifecycleResult,
): boolean {
  return (
    result.status === "needs_input" ||
    result.status === "failed" ||
    result.status === "partial_result" ||
    result.status === "queued_offline"
  );
}

export function ownerLifecycleStatusText(
  result: OwnerActionLifecycleResult | null,
): string {
  if (!result) return "";
  switch (result.status) {
    case "no_op":
      return "";
    case "needs_input":
      return "Devam etmek için ek bilgi gerekiyor.";
    case "succeeded":
      return "Değişiklik kaydedildi.";
    case "failed":
      return "Değişiklik tamamlanamadı. Asistan mesajını kontrol et.";
    case "partial_result":
      return "Bazı değişiklikler kaydedildi; bazıları için kontrol gerekiyor.";
    case "queued_offline":
      return "Değişiklik henüz sunucuya kaydedilmedi.";
  }
}

export function dispatchOwnerActionLifecycle(result: OwnerActionLifecycleResult): void {
  if (typeof window === "undefined") return;
  window.dispatchEvent(
    new CustomEvent<OwnerActionLifecycleResult>(OWNER_ACTION_LIFECYCLE_EVENT, {
      detail: result,
    }),
  );
}
