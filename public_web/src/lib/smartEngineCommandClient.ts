export type SmartEngineCommandStatus =
  | "no_op"
  | "succeeded"
  | "failed"
  | "partial_result";

export interface SmartEngineCommandAction {
  anahtar: string;
  deger: unknown;
}

export interface SmartEngineSucceededAction extends SmartEngineCommandAction {
  actionId: string;
  draftVersion: number;
  replayed: boolean;
}

export interface SmartEngineFailedAction extends SmartEngineCommandAction {
  actionId: string;
  code: string;
  message: string;
}

export interface SmartEngineStoppedAction extends SmartEngineCommandAction {
  code: string;
}

export interface SmartEngineCommandResult {
  status: SmartEngineCommandStatus;
  commandId: string;
  draftVersion: number;
  succeeded: SmartEngineSucceededAction[];
  failed: SmartEngineFailedAction[];
  stopped: SmartEngineStoppedAction[];
}

interface ActionResponseBody {
  tamam?: boolean;
  replayed?: boolean;
  taslakSurumu?: number;
  hata?: string;
  kod?: string;
}

export interface ExecuteSmartEngineCommandOptions {
  slug: string;
  initialDraftVersion: number;
  actions: readonly SmartEngineCommandAction[];
  clientId?: string | null;
  fetchImpl?: typeof fetch;
  idFactory?: () => string;
}

const GLOBAL_STOP_CODES = new Set([
  "DRAFT_VERSION_CONFLICT",
  "IDEMPOTENCY_KEY_REUSE",
  "INVALID_SESSION_TOKEN",
  "OWNER_AUTHORIZATION_REQUIRED",
  "SMART_ENGINE_DISABLED",
  "RATE_LIMITED",
  "RATE_LIMIT_SERVICE_ERROR",
  "SERVICE_UNAVAILABLE",
  "UNKNOWN_MUTATION_ERROR",
  "UNKNOWN_MUTATION_OUTCOME",
  "NETWORK_ERROR",
]);

function commandStatus(
  total: number,
  succeeded: number,
  failed: number,
  stopped: number,
): SmartEngineCommandStatus {
  if (total === 0) return "no_op";
  if (succeeded === total) return "succeeded";
  if (succeeded === 0 && failed > 0 && stopped + failed === total) return "failed";
  return "partial_result";
}

function stopRemaining(
  actions: readonly SmartEngineCommandAction[],
  fromIndex: number,
  code: string,
): SmartEngineStoppedAction[] {
  return actions.slice(fromIndex).map((action) => ({ ...action, code }));
}

/**
 * 5.6 LOCK client orchestrator.
 *
 * - Tek kullanıcı komutu = tek commandId.
 * - Her alan mutation'ı ayrı actionId alır.
 * - Her başarılı authoritative response'un draft version'ı bir sonraki action'ın
 *   expectedDraftVersion'ıdır.
 * - Alan-seviyesi kesin no-write hataları diğer bağımsız alanları engellemez.
 * - Conflict/auth/idempotency/kill-switch/rate-limit/network/unknown outcome
 *   sonrası kalan action'lar gönderilmez; "başarısız" gibi sahte retry yapılmaz.
 */
export async function executeSmartEngineCommand({
  slug,
  initialDraftVersion,
  actions,
  clientId = null,
  fetchImpl = fetch,
  idFactory = () => crypto.randomUUID(),
}: ExecuteSmartEngineCommandOptions): Promise<SmartEngineCommandResult> {
  const commandId = idFactory();
  let draftVersion = initialDraftVersion;
  const succeeded: SmartEngineSucceededAction[] = [];
  const failed: SmartEngineFailedAction[] = [];
  let stopped: SmartEngineStoppedAction[] = [];

  if (actions.length === 0) {
    return {
      status: "no_op",
      commandId,
      draftVersion,
      succeeded,
      failed,
      stopped,
    };
  }

  for (let index = 0; index < actions.length; index += 1) {
    const action = actions[index];
    const actionId = idFactory();
    let response: Response;

    try {
      response = await fetchImpl("/api/owner-smart-engine-action", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          slug,
          anahtar: action.anahtar,
          deger: action.deger,
          expectedDraftVersion: draftVersion,
          actionId,
          commandId,
          clientId,
        }),
      });
    } catch {
      failed.push({
        ...action,
        actionId,
        code: "NETWORK_ERROR",
        message: "Bağlantı kurulamadı.",
      });
      stopped = stopRemaining(actions, index + 1, "NETWORK_ERROR");
      break;
    }

    const body = (await response.json().catch(() => ({}))) as ActionResponseBody;

    if (!response.ok) {
      const code = typeof body.kod === "string" && body.kod ? body.kod : `HTTP_${response.status}`;
      failed.push({
        ...action,
        actionId,
        code,
        message: typeof body.hata === "string" && body.hata ? body.hata : "Kaydedilemedi.",
      });

      if (GLOBAL_STOP_CODES.has(code) || response.status >= 500) {
        stopped = stopRemaining(actions, index + 1, code);
        break;
      }
      continue;
    }

    if (
      body.tamam !== true ||
      typeof body.taslakSurumu !== "number" ||
      !Number.isSafeInteger(body.taslakSurumu) ||
      body.taslakSurumu < 1
    ) {
      failed.push({
        ...action,
        actionId,
        code: "UNKNOWN_MUTATION_OUTCOME",
        message: "Kaydetme sonucu doğrulanamadı.",
      });
      stopped = stopRemaining(actions, index + 1, "UNKNOWN_MUTATION_OUTCOME");
      break;
    }

    draftVersion = body.taslakSurumu;
    succeeded.push({
      ...action,
      actionId,
      draftVersion,
      replayed: body.replayed === true,
    });
  }

  return {
    status: commandStatus(actions.length, succeeded.length, failed.length, stopped.length),
    commandId,
    draftVersion,
    succeeded,
    failed,
    stopped,
  };
}

export interface UndoSmartEngineCommandOptions {
  slug: string;
  commandId: string;
  clientId?: string | null;
  fetchImpl?: typeof fetch;
}

export type UndoSmartEngineCommandResult =
  | {
      ok: true;
      replayed: boolean;
      draftVersion: number;
      rolledBackActionCount: number;
    }
  | {
      ok: false;
      code: string;
      message: string;
    };

/** Command receipt'lerini server çözer; client alan listesi göndermez. */
export async function undoSmartEngineCommand({
  slug,
  commandId,
  clientId = null,
  fetchImpl = fetch,
}: UndoSmartEngineCommandOptions): Promise<UndoSmartEngineCommandResult> {
  let response: Response;
  try {
    response = await fetchImpl("/api/owner-smart-engine-undo", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ slug, commandId, clientId }),
    });
  } catch {
    return { ok: false, code: "NETWORK_ERROR", message: "Bağlantı kurulamadı." };
  }

  const body = (await response.json().catch(() => ({}))) as {
    tamam?: boolean;
    replayed?: boolean;
    taslakSurumu?: number;
    geriAlinanIslemSayisi?: number;
    kod?: string;
    hata?: string;
  };

  if (
    !response.ok ||
    body.tamam !== true ||
    typeof body.taslakSurumu !== "number" ||
    !Number.isSafeInteger(body.taslakSurumu)
  ) {
    return {
      ok: false,
      code: typeof body.kod === "string" && body.kod ? body.kod : `HTTP_${response.status}`,
      message: typeof body.hata === "string" && body.hata ? body.hata : "İşlem geri alınamadı.",
    };
  }

  return {
    ok: true,
    replayed: body.replayed === true,
    draftVersion: body.taslakSurumu,
    rolledBackActionCount:
      typeof body.geriAlinanIslemSayisi === "number" ? body.geriAlinanIslemSayisi : 0,
  };
}
