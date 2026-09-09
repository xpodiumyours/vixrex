import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

const nav = vi.hoisted(() => ({ pathname: "/app" }));
vi.mock("next/navigation", () => ({
  usePathname: () => nav.pathname,
  useRouter: () => ({ push: vi.fn(), prefetch: vi.fn() }),
}));

import {
  AppShellProvider,
} from "@/components/app/AppShellContext";
import { AppBottomNav, AppSidebar } from "@/components/app/AppSidebar";

const flutterColors = readFileSync(
  resolve(__dirname, "../../lib/theme/app_colors.dart"),
  "utf8",
);
const globalsCss = readFileSync(
  resolve(__dirname, "../src/app/globals.css"),
  "utf8",
);
const layoutSource = readFileSync(
  resolve(__dirname, "../src/app/layout.tsx"),
  "utf8",
);

function flutterHex(name: string): string {
  const match = flutterColors.match(
    new RegExp(`static const Color ${name} = Color\\(0xFF([0-9A-Fa-f]{6})\\)`),
  );
  if (!match) throw new Error(`Flutter rengi bulunamadı: ${name}`);
  return match[1].toUpperCase();
}

function cssHex(varName: string): string {
  const match = globalsCss.match(
    new RegExp(`--owner-${varName}:\\s*#([0-9A-Fa-f]{6})`),
  );
  if (!match) throw new Error(`CSS değişkeni bulunamadı: --owner-${varName}`);
  return match[1].toUpperCase();
}

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

export function kontrast(on: string, of: string): number {
  const l1 = Math.max(luminance(on), luminance(of));
  const l2 = Math.min(luminance(on), luminance(of));
  return (l1 + 0.05) / (l2 + 0.05);
}

const PALET_ESLESMELERI: Array<[string, string]> = [
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

describe("WCAG kontrast — gerçek hesap", () => {
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
  it("yardımcı metin yüzeylerde AA (>= 4.5)", () => {
    expect(kontrast(v.muted, v.bgSoft)).toBeGreaterThanOrEqual(4.5);
    expect(kontrast(v.muted, v.surface)).toBeGreaterThanOrEqual(4.5);
  });
  it("birincil buton metni AA (>= 4.5)", () => {
    expect(kontrast(v.onPrimary, v.primary)).toBeGreaterThanOrEqual(4.5);
  });
  it("durum renkleri zeminde AA (>= 4.5)", () => {
    expect(kontrast(v.success, v.bg)).toBeGreaterThanOrEqual(4.5);
    expect(kontrast(v.warning, v.bg)).toBeGreaterThanOrEqual(4.5);
    expect(kontrast(v.error, v.bg)).toBeGreaterThanOrEqual(4.5);
  });
});

function renderNavigasyon() {
  return renderToStaticMarkup(
    createElement(
      AppShellProvider,
      null,
      createElement("div", null, createElement(AppSidebar), createElement(AppBottomNav)),
    ),
  );
}

describe("Erişilebilirlik kapıları — gerçek render + stil sözleşmesi", () => {
  it("arama alanının gerçek label'ı ve klavye ile bulunabilir id bağlantısı var", () => {
    const html = renderNavigasyon();
    expect(html).toContain('<label for="app-shell-search" class="sr-only">Vitrin veya ürün ara</label>');
    expect(html).toContain('id="app-shell-search"');
  });

  it("dekoratif ikonlar gerçek render'da aria-hidden taşır", () => {
    const html = renderNavigasyon();
    expect(html).toContain('aria-hidden="true"');
  });

  it("mobil alt menü gerçek render'da 68px ve adlandırılmış nav'dır", () => {
    const html = renderNavigasyon();
    expect(html).toContain('aria-label="Mobil uygulama menüsü"');
    expect(html).toContain("h-[68px]");
  });

  it("klavye odağı CSS kapısı 3px halka + 2px offset", () => {
    expect(globalsCss).toContain(":focus-visible");
    expect(globalsCss).toContain("outline: 3px solid");
    expect(globalsCss).toContain("outline-offset: 2px");
  });

  it("dokunma hedefi CSS kapısı: girdi/buton >= 48px", () => {
    expect(globalsCss).toMatch(/\.owner-input\s*{[^}]*min-height:\s*48px/);
    expect(globalsCss).toMatch(/owner-button-danger\s*{[^}]*min-height:\s*48px/);
  });

  it("hareket azaltma CSS kuralı var", () => {
    expect(globalsCss).toContain("@media (prefers-reduced-motion: reduce)");
  });

  it("%200 yakınlaştırma engellenmiyor: maximumScale sayısal olarak >= 2", () => {
    const match = layoutSource.match(/maximumScale:\s*([0-9.]+)/);
    expect(match).not.toBeNull();
    expect(Number(match?.[1])).toBeGreaterThanOrEqual(2);
  });

  it.todo(
    "dinamik hata state'inin role=alert duyurusu Katman C jsdom etkileşim testinde gerçek state değişimiyle kanıtlanacak",
  );
});
