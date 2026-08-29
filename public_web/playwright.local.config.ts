import { defineConfig } from "@playwright/test";
import temelYapilandirma from "./playwright.config";

/**
 * Yerel derlemeye karşı E2E — `npm run e2e:local`.
 *
 * NEDEN AYRI DOSYA: hedefi ortam değişkeniyle vermek Windows'ta ek bir
 * bağımlılık (cross-env) gerektiriyordu. Ayrı yapılandırma hem bağımlılıksız
 * hem de her platformda aynı komutla çalışıyor.
 *
 * Asıl kullanım: ana sayfanın görsel temellerini (`anasayfa-*.png`) yeniden
 * üretmek. Varsayılan yapılandırma CANLI siteye bakar; oraya karşı
 * `--update-snapshots` çalıştırmak yayınlanmamış sayfayı değil, yayındaki
 * eski sürümü fotoğraflar.
 *
 *   npm run e2e:local -- visual-regression --update-snapshots
 */
export default defineConfig({
  ...temelYapilandirma,
  use: {
    ...temelYapilandirma.use,
    baseURL: "http://localhost:3000",
    video: "on",
    trace: "on",
    screenshot: "on",
  },
  webServer: {
    command: "npm run build && npm run start",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
    timeout: 180_000,
  },
});
