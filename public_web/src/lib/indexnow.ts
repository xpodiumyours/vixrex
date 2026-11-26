// IndexNow bildirim yardımcı (Aktif Görev #6). Hata durumunda ana yayını
// kesmez; INDEXNOW_KEY tanımlı değilse sessizce pasif kalır.

const INDEXNOW_ENDPOINT = "https://api.indexnow.org/indexnow";

export async function indexnowBildir(urls: string[]): Promise<void> {
  const key = (process.env.INDEXNOW_KEY || "").trim();
  if (!key) return;
  const temiz = urls.map((u) => u.trim()).filter(Boolean);
  if (temiz.length === 0) return;

  const siteUrl = (process.env.NEXT_PUBLIC_SITE_URL || "").trim() || "https://vixrex.com";
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
    });
  } catch {
    // Sessizce yut: IndexNow hatası ana yayını kesmez.
  }
}
