import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { beforeEach, describe, expect, it, vi } from "vitest";

const nav = vi.hoisted(() => ({
  pathname: "/app",
  push: vi.fn(),
  prefetch: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  usePathname: () => nav.pathname,
  useRouter: () => ({ push: nav.push, prefetch: nav.prefetch }),
}));
vi.mock("@/lib/supabase", () => ({ supabase: {} }));

import { AppShellBoundary } from "@/components/app/AppShellBoundary";

function renderShell(pathname = "/app") {
  nav.pathname = pathname;
  return renderToStaticMarkup(
    createElement(
      AppShellBoundary,
      null,
      createElement("div", { id: "test-child" }, "İçerik"),
    ),
  );
}

describe("Flutter Web ↔ Next.js tek-shell — gerçek render", () => {
  beforeEach(() => {
    nav.pathname = "/app";
    vi.clearAllMocks();
  });

  it("dört ana sekmeyi doğru sırada ve gerçek rotalarıyla çizer", () => {
    const html = renderShell();
    const sira = ["Vitrinim", "Keşfet", "Vixrex", "Profil"];
    const indeksler = sira.map((etiket) => html.indexOf(`>${etiket}<`));

    expect(indeksler.every((index) => index >= 0)).toBe(true);
    for (let i = 0; i < indeksler.length - 1; i += 1) {
      expect(indeksler[i]).toBeLessThan(indeksler[i + 1]);
    }
    expect(html).toContain('href="/app"');
    expect(html).toContain('href="/kesfet"');
    expect(html).toContain('href="/app/vixrex"');
    expect(html).toContain('href="/app/profil"');
  });

  it("tek desktop + mobil navigasyonu ve 68px alt menüyü gerçekten çizer", () => {
    const html = renderShell();

    expect(html).toContain('aria-label="Ana bölümler"');
    expect(html).toContain('aria-label="Mobil uygulama menüsü"');
    expect(html).toContain("w-[220px]");
    expect(html).toContain("h-[68px]");
  });

  it("ana sekme gövdesini mounted bölüm olarak ve durum çubuğuyla çizer", () => {
    const html = renderShell("/app");

    expect(html).toContain('data-app-tab="vitrinim"');
    expect(html).toContain('aria-current="page"');
    expect(html).toContain("Yayında değil");
    expect(html).toContain("Vitrininiz henüz yayınlanmadı");
    expect(html).toContain("Vitrini yayınla");
  });

  it("Profil alt ekranı shell dışında push ekranı olarak kalır", () => {
    const html = renderShell("/app/ayarlar");

    expect(html).toContain('id="test-child"');
    expect(html).not.toContain('aria-label="Ana bölümler"');
    expect(html).not.toContain('aria-label="Mobil uygulama menüsü"');
  });
});
