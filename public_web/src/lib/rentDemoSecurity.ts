// "Bu vitrini kirala" oran sınırlaması için istemci kimliği — yalnız
// /api/rent-demo POST handler'ı çağırır (2026-08-15, güvenlik açığı
// kapatılırken eklendi).
//
// Ham IP veritabanına YAZILMAZ — HMAC-SHA256(RATE_LIMIT_SECRET, ip) ile
// geri döndürülemez bir parmak izine çevrilir, o parmak izi
// start_demo_trial'a p_client_key olarak geçer.

import { createHmac } from "node:crypto";

/**
 * Vercel deployment'larında x-forwarded-for/x-vercel-forwarded-for'ı
 * kendisi ayarlıyor ve spoofing'i önlemek için gelen değeri EZİYOR — yani
 * bu header'lara güvenmek yalnız Vercel'in kendi platformunda güvenli.
 * (bkz. https://vercel.com/docs/edge-network/headers — request headers)
 */
export function getClientIp(request: Request): string {
  const headers = request.headers;
  const vercelForwarded = headers.get("x-vercel-forwarded-for");
  if (vercelForwarded) return vercelForwarded.split(",")[0]!.trim();

  const forwarded = headers.get("x-forwarded-for");
  if (forwarded) return forwarded.split(",")[0]!.trim();

  const realIp = headers.get("x-real-ip");
  if (realIp) return realIp.trim();

  // Yerel geliştirme / header hiç yoksa — sabit bir anahtar, tüm istekler
  // aynı bucket'a düşer (yerelde rate-limit testi bile edilebilir).
  return "unknown";
}

/** Ham IP'yi kalıcı olarak saklanabilir, geri döndürülemez bir anahtara
 * çevirir. RATE_LIMIT_SECRET tanımlı değilse (yerel/test ortamı) IP'nin
 * kendisini döner — üretimde bu değişken .env.example'da işaretli, zorunlu
 * kabul edilmeli. */
export function fingerprintClient(ip: string): string {
  const secret = process.env.RATE_LIMIT_SECRET?.trim();
  if (!secret) return ip;
  return createHmac("sha256", secret).update(ip).digest("hex");
}
