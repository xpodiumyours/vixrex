"use client";

const CACHE_TTL_MS = 15_000;

type CachedStatus = {
  enabled: boolean;
  expiresAt: number;
};

const cache = new Map<string, CachedStatus>();
const pending = new Map<string, Promise<boolean>>();

/**
 * Client guard. Ağ/JSON/401/500/missing flag = OFF.
 * Server mutation yolu ayrıca aynı capability'yi yeniden doğrular.
 */
export async function smartEngineStorefrontClientEnabled(
  slug: string
): Promise<boolean> {
  const key = slug.trim();
  if (!key) return false;

  const now = Date.now();
  const cached = cache.get(key);
  if (cached && cached.expiresAt > now) return cached.enabled;

  const mevcut = pending.get(key);
  if (mevcut) return mevcut;

  const istek = (async () => {
    try {
      const response = await fetch(
        `/api/owner-smart-engine-status?slug=${encodeURIComponent(key)}`,
        { cache: "no-store" }
      );
      if (!response.ok) return false;
      const body = (await response.json()) as { enabled?: unknown };
      return body?.enabled === true;
    } catch {
      return false;
    }
  })();

  pending.set(key, istek);
  try {
    const enabled = await istek;
    cache.set(key, { enabled, expiresAt: Date.now() + CACHE_TTL_MS });
    return enabled;
  } finally {
    pending.delete(key);
  }
}

/** Server authoritative guard OFF dönerse local cache'i anında kapatır. */
export function markSmartEngineStorefrontDisabled(slug: string): void {
  const key = slug.trim();
  if (!key) return;
  cache.set(key, { enabled: false, expiresAt: Date.now() + CACHE_TTL_MS });
}
