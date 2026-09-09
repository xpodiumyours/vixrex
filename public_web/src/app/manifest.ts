import type { MetadataRoute } from "next";

/**
 * Web uygulama bildirimi (manifest).
 *
 * Neden var (2026-09-09): site telefonda açıldığında uygulama gibi
 * davranmıyordu — ana ekrana eklenemiyor, ikonu yok, tarayıcı çubuğu hep
 * duruyordu. Ölçüldüğünde bunların HİÇBİRİ yoktu (manifest yok, apple ikonu
 * yok, standalone yok).
 *
 * Bu ayrıca APK kararının ÖNKOŞULU: bir siteyi Android kabuğuna (Trusted Web
 * Activity) sarabilmek için Chrome'un "ana ekrana eklenebilir" ölçütlerini
 * karşılaması gerekir.
 *
 * Chrome'un kurulabilirlik ölçütleri (web.dev/articles/install-criteria):
 *   - HTTPS
 *   - `name` veya `short_name`
 *   - `icons` içinde 192px VE 512px
 *   - `start_url`
 *   - `display`: fullscreen | standalone | minimal-ui | window-controls-overlay
 *   - `prefer_related_applications` yok ya da false
 * Service worker ŞART DEĞİL.
 *
 * Kilidi: tests/manifest-kurulabilirlik.test.ts
 */
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Vixrex — İşletmenin dijital vitrini",
    short_name: "Vixrex",
    description:
      "İşletme bilgilerini, ürünlerini ve iletişimini tek vitrinde topla; " +
      "link ve QR kodla paylaş.",
    lang: "tr",
    dir: "ltr",

    // Uygulama açılınca tanıtım sayfası değil, işletmenin kendi paneli gelir.
    // Oturum yoksa /app zaten girişe yönlendiriyor.
    start_url: "/app",
    scope: "/",

    display: "standalone",
    orientation: "portrait",

    // Açılış ekranının zemini: uygulama kabuğunun ilk boyadığı renk
    // (--color-lp-bg-editor). Böylece açılışta beyaz parlama olmaz.
    background_color: "#050B1A",
    // Tarayıcı/sistem çubuğu rengi — layout.tsx'teki themeColor ile aynı.
    theme_color: "#0c0d10",

    categories: ["business", "productivity"],

    icons: [
      { src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
      // Android ikonu daire/kare kırptığı için kenardan pay bırakılmış sürüm.
      {
        src: "/icon-maskable-512.png",
        sizes: "512x512",
        type: "image/png",
        purpose: "maskable",
      },
    ],
  };
}
