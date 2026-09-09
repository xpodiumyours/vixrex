import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Erişilebilirlik matrisi parite testi (sözleşme §14).
 *
 * Kanıt kaynakları:
 *  - Flutter paleti: lib/theme/app_colors.dart
 *  - Next paleti:    public_web/src/app/globals.css (.owner-shell değişkenleri)
 *  - Kontrast: WCAG 2.1 göreli parlaklık formülüyle GERÇEK hesap —
 *    uydurma sayı yok; palet değişirse test kırılır (koruyucu kapı).
 */

const flutterColors = readFileSync(
  resolve(__dirname, "../../lib/theme/app_colors.dart"),
  "utf8",
);
const globalsCss = readFileSync(
  resolve(__dirname, "../src/app/globals.css"),
  "utf8",
);
const layout = readFileSync(
  resolve(__dirname, "../src/app/layout.tsx"),
  "utf8",
);
const sidebar = readFileSync(
  resolve(__dirname, "../src/components/app/AppSidebar.tsx"),
  "utf8",
);

// ── Palet çıkarımı ──────────────────────────────────────────────────────────

/** Dart `Color(0xFFRRGGBB)` sabitinden hex alır. */
function flutterHex(name: string): string {
  const m = flutterColors.match(
    new RegExp(`static const Color ${name} = Color\\(0xFF([0-9A-Fa-f]{6})\\)`),
  );
  if (!m) throw new Error(`Flutter rengi bulunamadı: ${name}`);
  return m[1].toUpperCase();
}

/** CSS `--owner-xxx: #RRGGBB;` değişkeninden hex alır. */
function cssHex(varName: string): string {
  const m = globalsCss.match(
    new RegExp(`--owner-${varName}:\\s*#([0-9A-Fa-f]{6})`),
  );
  if (!m) throw new Error(`CSS değişkeni bulunamadı: --owner-${varName}`);
  return m[1].toUpperCase();
}

// ── WCAG 2.1 kontrast hesabı ────────────────────────────────────────────────

function kanalLin(hex: string, index: number): number {
  const c = parseInt(hex.slice(index, index + 2), 16) / 255;
  return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function luminance(hex: string): number {
  return (
    0.2126 * kanalLin(hex, 0) +
    0.7152 * kanalLin(hex, 2) +
    0.0722 * kanalLin(hex, 4)
  );
}

/** WCAG kontrast oranı (1…21). */
export function kontrast(on: string, of: string): number {
  const l1 = Math.max(luminance(on), luminance(of));
  const l2 = Math.min(luminance(on), luminance(of));
  return (l1 + 0.05) / (l2 + 0.05);
}

// ── 1) Paletler birebir aynı (UI matrisi köprüsü) ──────────────────────────

const PALET_ESLESMELERI: Array<[string, string]> = [
  // [Flutter sabiti, CSS değişkeni]
  ["primary", "primary"],
  ["primaryDark", "primary-dark"],
  ["secondary", "secondary"],
  ["onPrimary", "on-primary"],
  ["bgEditor", "bg"],
  ["bgLight", "bg-soft"],
  ["surface", "surface"],
  ["surfaceSoft", "surface-soft"],
  ["darkText", "text"],
  ["darkTextAlt", "text-alt"],
  ["mutedText", "muted"],
  ["border", "border"],
  ["success", "success"],
  ["warning", "warning"],
  ["error", "error"],
];

describe("Erişilebilirlik palet paritesi", () => {
  it.each(PALET_ESLESMELERI)("Flutter %s == Next --owner-%s", (flutterAd, cssAd) => {
    expect(flutterHex(flutterAd)).toBe(cssHex(cssAd));
  });
});


// ── 2) Gerçek WCAG kontrast oranları (AA kapısı) ───────────────────────────

describe("WCAG kontrast (gerçek hesap)", () => {
  const v = {
    bg: cssHex("bg"),
    bgSoft: cssHex("bg-soft"),
    surface: cssHex("surface"),
    text: cssHex("text"),
    textAlt: cssHex("text-alt"),
    muted: cssHex("muted"),
    primary: cssHex("primary"),
    onPrimary: cssHex("on-primary"),
    success: cssHex("success"),
    warning: cssHex("warning"),
    error: cssHex("error"),
  };

  it("ana metin zeminde AAA (>= 7)", () => {
    expect(kontrast(v.text, v.bg)).toBeGreaterThanOrEqual(7);
  });

  it("etiket metni kart yüzeyinde AA (>= 4.5)", () => {
    expect(kontrast(v.textAlt, v.surface)).toBeGreaterThanOrEqual(4.5);
  });

  it("yardımcı metin form alanında AA (>= 4.5)", () => {
    // .owner-input zemini --owner-bg-soft, placeholder --owner-muted
    expect(kontrast(v.muted, v.bgSoft)).toBeGreaterThanOrEqual(4.5);
    expect(kontrast(v.muted, v.surface)).toBeGreaterThanOrEqual(4.5);
  });

  it("birincil buton metni en kötü gradyan ucunda AA (>= 4.5)", () => {
    // Gradyan: primary → primaryDark; en kötü (açık) uç primary.
    expect(kontrast(v.onPrimary, v.primary)).toBeGreaterThanOrEqual(4.5);
  });

  it("durum renkleri zeminde AA (>= 4.5)", () => {
    expect(kontrast(v.success, v.bg)).toBeGreaterThanOrEqual(4.5);
    expect(kontrast(v.warning, v.bg)).toBeGreaterThanOrEqual(4.5);
    expect(kontrast(v.error, v.bg)).toBeGreaterThanOrEqual(4.5);
  });
});

// ── 3) Sözleşme §14 satırlarının web karşılıkları ──────────────────────────

describe("Erişilebilirlik kapıları (Next.js)", () => {
  it("form etiketleri: .owner-label + sr-only kalıbı mevcut", () => {
    expect(globalsCss).toContain(".owner-label");
    const appPage = readFileSync(
      resolve(__dirname, "../src/app/app/page.tsx"),
      "utf8",
    );
    expect(appPage).toContain("sr-only");
  });

  it("hata duyurusu: role=\"alert\" kalıbı ekranlarda var", () => {
    const bildirimler = readFileSync(
      resolve(__dirname, "../src/app/app/bildirimler/page.tsx"),
      "utf8",
    );
    expect(bildirimler).toContain('role="alert"');
  });

  it("klavye odağı: focus-visible 3px halka + 2px offset", () => {
    expect(globalsCss).toContain(":focus-visible");
    expect(globalsCss).toContain("outline: 3px solid");
    expect(globalsCss).toContain("outline-offset: 2px");
  });

  it("dekoratif öğeler: aria-hidden kullanılıyor", () => {
    const profil = readFileSync(
      resolve(__dirname, "../src/app/app/profil/page.tsx"),
      "utf8",
    );
    expect(profil).toContain("aria-hidden");
  });

  it("dokunma hedefi: girdi/buton >= 48px, alt menü 68px", () => {
    expect(globalsCss).toMatch(/\.owner-input\s*{[^}]*min-height:\s*48px/);
    expect(globalsCss).toMatch(/owner-button-danger\s*{[^}]*min-height:\s*48px/);
    // 2026-09-09: alt menü yüksekliği sabit sınıftan CSS değişkenine
    // taşındı (--vx-app-bottom-nav-height). Değer aynı (68px), artık
    // tek yerden geliyor — kontrol de oraya bakıyor.
    expect(sidebar).toContain("vixrex-app-bottom-nav");
    expect(
      readFileSync(resolve(__dirname, "../src/app/vixrex-app-ui.css"), "utf8")
    ).toContain("--vx-app-bottom-nav-height: 68px");
  });

  it("hareket azaltma: prefers-reduced-motion kuralları var", () => {
    expect(globalsCss).toContain("@media (prefers-reduced-motion: reduce)");
  });

  it("%200 yakınlaştırma engellenmiyor (maximumScale 5)", () => {
    // iOS'un izin verdiği en yüksek değer; 200% zoom açıkça çalışır.
    expect(layout).toContain("maximumScale: 5");
    expect(layout).not.toMatch(/maximumScale:\s*1\b/);
  });
});

// ── 4) Dürüstlük notu ───────────────────────────────────────────────────────
// Sözleşme §14'te "○ Ölçülmedi" satırlar (ekran okuyucu sırası, canlı %200
// görsel doğrulaması, Flutter Semantics denetimi) bu testle KAPANMAZ —
// canlı cihaz ölçümü gerektirir. Bu test yalnız kaynak kodun kanıtlayabildiği
// kapıları kilitler.
