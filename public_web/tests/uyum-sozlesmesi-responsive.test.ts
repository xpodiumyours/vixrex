import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

const flutterShell = oku("../../lib/screens/home_shell_screen.dart");
const flutterTheme = oku("../../lib/theme/app_theme.dart");
const webNav = oku("../src/components/app/AppSidebar.tsx");
const webBoundary = oku("../src/components/app/AppShellBoundary.tsx");

function sirayiKoru(kaynak: string, etiketler: readonly string[]) {
  let onceki = -1;
  for (const etiket of etiketler) {
    const index = kaynak.indexOf(etiket, onceki + 1);
    expect(index, `${etiket} kaynakta bulunmalı`).toBeGreaterThan(onceki);
    onceki = index;
  }
}

describe("Uyum Sözleşmesi 05 — Responsive / ana uygulama shell", () => {
  it("masaüstü eşiği Flutter >900 ile Next 901px başlangıcı olarak aynı kalır", () => {
    expect(flutterShell).toContain("MediaQuery.of(context).size.width > 900");
    expect(webNav).toContain("min-[901px]:flex");
    expect(webNav).toContain("min-[901px]:hidden");
    expect(webBoundary).toContain("min-[901px]:pb-0");
  });

  it("masaüstünde sidebar, mobilde alt NavigationBar kullanılır", () => {
    expect(flutterShell).toContain("if (isDesktop)");
    expect(flutterShell).toContain("ShellSidebar(");
    expect(flutterShell).toContain("bottomNavigationBar:");
    expect(flutterShell).toContain("NavigationBar(");

    expect(webBoundary).toContain("<AppSidebar />");
    expect(webBoundary).toContain("<AppBottomNav />");
  });

  it("mobil alt bar yüksekliği ve içerik telafisi iki renderer'da 68px'tir", () => {
    expect(flutterTheme).toContain("height: 68");
    expect(webNav).toContain("h-[68px]");
    expect(webBoundary).toContain("pb-[68px]");
  });

  it("dört ana bölüm iki renderer'da aynı sıradadır", () => {
    const anaBolumler = ["Vitrinim", "Keşfet", "Vixrex", "Profil"] as const;
    sirayiKoru(flutterShell, anaBolumler);
    sirayiKoru(webNav, anaBolumler);
  });

  it("masaüstü sidebar genişliği Flutter ve Next'te 220px'tir", () => {
    const flutterSidebar = oku("../../lib/widgets/shell/shell_sidebar.dart");
    expect(flutterSidebar).toContain("this.width = 220");
    expect(webNav).toContain("w-[220px]");
  });
});
