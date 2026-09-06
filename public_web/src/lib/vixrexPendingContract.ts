export const VIXREX_PENDING_SCHEMA_VERSION = 1 as const;

export type VixrexPendingKind =
  | "missing_value"
  | "confirm_candidate"
  | "special_flow";

export interface VixrexPendingEnvelope {
  schemaVersion: typeof VIXREX_PENDING_SCHEMA_VERSION;
  domain: "storefront";
  kind: VixrexPendingKind;
  fieldKey: string;
  fieldType: string;
  fieldLabel: string;
  proposedValue?: unknown;
  commandId?: string;
  attempt: number;
  createdAt: string;

  /** Geçiş uyumu: mevcut DB constraint / eski istemciler. */
  anahtar: string;
  etiket: string;
  tip: string;
  sorulduAt: string;
  deneme: number;
}

const KINDS = new Set<VixrexPendingKind>([
  "missing_value",
  "confirm_candidate",
  "special_flow",
]);

export function createPendingEnvelope(params: {
  fieldKey: string;
  fieldType: string;
  fieldLabel: string;
  kind?: VixrexPendingKind;
  proposedValue?: unknown;
  commandId?: string;
  attempt?: number;
  createdAt?: string;
}): VixrexPendingEnvelope {
  const createdAt = params.createdAt ?? new Date().toISOString();
  const attempt = Math.max(1, Math.trunc(params.attempt ?? 1));
  const kind = params.kind ?? "missing_value";

  return {
    schemaVersion: VIXREX_PENDING_SCHEMA_VERSION,
    domain: "storefront",
    kind,
    fieldKey: params.fieldKey,
    fieldType: params.fieldType,
    fieldLabel: params.fieldLabel,
    ...(params.proposedValue !== undefined
      ? { proposedValue: params.proposedValue }
      : {}),
    ...(params.commandId ? { commandId: params.commandId } : {}),
    attempt,
    createdAt,

    anahtar: params.fieldKey,
    etiket: params.fieldLabel,
    tip: params.fieldType,
    sorulduAt: createdAt,
    deneme: attempt,
  };
}

export function parsePendingEnvelope(raw: unknown): VixrexPendingEnvelope | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const record = raw as Record<string, unknown>;

  const schemaVersion =
    typeof record.schemaVersion === "number"
      ? Math.trunc(record.schemaVersion)
      : VIXREX_PENDING_SCHEMA_VERSION;
  const domain =
    typeof record.domain === "string" ? record.domain : "storefront";
  const rawKind =
    typeof record.kind === "string" ? record.kind : "missing_value";
  const fieldKey = String(record.fieldKey ?? record.anahtar ?? "").trim();
  const fieldType = String(record.fieldType ?? record.tip ?? "metin").trim();
  const fieldLabel = String(
    record.fieldLabel ?? record.etiket ?? fieldKey,
  ).trim();

  if (
    schemaVersion !== VIXREX_PENDING_SCHEMA_VERSION ||
    domain !== "storefront" ||
    !KINDS.has(rawKind as VixrexPendingKind) ||
    !fieldKey ||
    !fieldType ||
    !fieldLabel
  ) {
    return null;
  }

  const attemptRaw = Number(record.attempt ?? record.deneme ?? 1);
  const attempt = Number.isFinite(attemptRaw)
    ? Math.max(1, Math.trunc(attemptRaw))
    : 1;
  const createdAtRaw = String(
    record.createdAt ?? record.sorulduAt ?? "",
  ).trim();
  const createdAt = Number.isNaN(Date.parse(createdAtRaw))
    ? new Date().toISOString()
    : new Date(createdAtRaw).toISOString();
  const commandId =
    typeof record.commandId === "string" && record.commandId.trim()
      ? record.commandId.trim()
      : undefined;

  return createPendingEnvelope({
    fieldKey,
    fieldType,
    fieldLabel,
    kind: rawKind as VixrexPendingKind,
    proposedValue: record.proposedValue,
    commandId,
    attempt,
    createdAt,
  });
}
