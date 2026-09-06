"use client";

const CACHE_TTL_MS = 15_000;

type CachedStatus = {
  enabled: boolean;
  expiresAt: number;
};

const cache = new Map<string, CachedStatus>();
const pending = new Map<string, Promise<boolean>>();

type SmartEngineDomain = "storefront" | "blog";

function cacheKey(slug: string, domain: SmartEngineDomain): string {
  return `${domain}:${slug}`;
}

async function smartEngineClientEnabled(
  slug: string,
  domain: SmartEngineDomain,
): Promise<boolean> {
  const normalizedSlug = slug.trim();
  if (!normalizedSlug) return false;

  const key = cacheKey(normalizedSlug, domain);
  const now = Date.now();
  const cached = cache.get(key);
  if (cached && cached.expiresAt > now) return cached.enabled;

  const mevcut = pending.get(key);
  if (mevcut) return mevcut;

  const istek = (async () => {
    try {
      const response = await fetch(
        `/api/owner-smart-engine-status?slug=${encodeURIComponent(normalizedSlug)}&domain=${domain}`,
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

/** Client guard. Ağ/JSON/401/500/missing flag = OFF. */
export async function smartEngineStorefrontClientEnabled(
  slug: string
): Promise<boolean> {
  return smartEngineClientEnabled(slug, "storefront");
}

/** Blog domain client guard. Server mutation ayrıca yeniden doğrular. */
export async function smartEngineBlogClientEnabled(slug: string): Promise<boolean> {
  return smartEngineClientEnabled(slug, "blog");
}

function markSmartEngineDisabled(slug: string, domain: SmartEngineDomain): void {
  const normalizedSlug = slug.trim();
  if (!normalizedSlug) return;
  cache.set(cacheKey(normalizedSlug, domain), {
    enabled: false,
    expiresAt: Date.now() + CACHE_TTL_MS,
  });
}

/** Server authoritative guard OFF dönerse local cache'i anında kapatır. */
export function markSmartEngineStorefrontDisabled(slug: string): void {
  markSmartEngineDisabled(slug, "storefront");
}

export function markSmartEngineBlogDisabled(slug: string): void {
  markSmartEngineDisabled(slug, "blog");
}
