import { getSiteUrl } from "@/lib/siteUrl";

const INDEXNOW_ENDPOINT = "https://api.indexnow.org/indexnow";
const INDEXNOW_KEY_PATTERN = /^[a-zA-Z0-9-]{8,128}$/;

export function readValidIndexNowKey(): string | null {
  const key = (process.env.INDEXNOW_KEY || "").trim();
  if (!INDEXNOW_KEY_PATTERN.test(key)) return null;
  return key;
}

export async function indexnowBildir(urls: string[]): Promise<void> {
  const key = readValidIndexNowKey();
  if (!key) return;
  const temiz = urls.map((u) => u.trim()).filter(Boolean);
  if (temiz.length === 0) return;

  const siteUrl = getSiteUrl();
  const host = new URL(siteUrl).host;
  const keyLocation = `${siteUrl.replace(/\/$/, "")}/api/indexnow/key`;

  try {
    await fetch(INDEXNOW_ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=utf-8" },
      body: JSON.stringify({
        host,
        key,
        keyLocation,
        urlList: temiz,
      }),
      signal: AbortSignal.timeout(5000),
    });
  } catch {
    return;
  }
}
