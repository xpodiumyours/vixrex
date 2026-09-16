import type { VitrinViewSource } from "@/lib/vitrinViewSource";

const STORAGE_KEY = "vixrex_source_handoff";
const MAX_AGE_MS = 60_000;

type InternalSource = Extract<VitrinViewSource, "kesfet">;

type SourceHandoff = {
  source: InternalSource;
  targetPath: string;
  createdAt: number;
};

export function kaydetVitrinKaynakHandoff(
  source: InternalSource,
  targetPath: string,
): void {
  if (typeof window === "undefined") return;
  const normalizedPath = targetPath.trim();
  if (!normalizedPath.startsWith("/v/")) return;

  const handoff: SourceHandoff = {
    source,
    targetPath: normalizedPath,
    createdAt: Date.now(),
  };

  try {
    window.sessionStorage.setItem(STORAGE_KEY, JSON.stringify(handoff));
  } catch {
    return;
  }
}

export function tuketVitrinKaynakHandoff(
  currentPath: string,
): InternalSource | null {
  if (typeof window === "undefined") return null;

  let raw: string | null = null;
  try {
    raw = window.sessionStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
  if (!raw) return null;

  let handoff: SourceHandoff;
  try {
    handoff = JSON.parse(raw) as SourceHandoff;
  } catch {
    try {
      window.sessionStorage.removeItem(STORAGE_KEY);
    } catch {
      return null;
    }
    return null;
  }

  const age = Date.now() - handoff.createdAt;
  if (
    handoff.source !== "kesfet" ||
    age < 0 ||
    age > MAX_AGE_MS ||
    handoff.targetPath !== currentPath
  ) {
    if (age < 0 || age > MAX_AGE_MS) {
      try {
        window.sessionStorage.removeItem(STORAGE_KEY);
      } catch {
        return null;
      }
    }
    return null;
  }

  try {
    window.sessionStorage.removeItem(STORAGE_KEY);
  } catch {
    return null;
  }
  return handoff.source;
}
