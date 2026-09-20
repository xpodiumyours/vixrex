import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("main Flutter referanslı uygulama UI sözleşmesi", () => {
  const flutterColors = oku("../../lib/theme/app_colors.dart");
  const flutterTheme = oku("../../lib/theme/app_theme.dart");
  const flutterSidebar = oku("../../lib/widgets/shell/shell_sidebar.dart");
  const flutterFields = oku("../../lib/widgets/editor/common_form_fields.dart");
  const flutterVitrin = oku("../../lib/screens/my_vitrin_screen.dart");
  const globals = oku("../src/app/globals.css");
  const appCss = oku("../src/app/vixrex-app-ui.css");
  const appBoundary = oku("../src/components/app/AppShellBoundary.tsx");
  const appNav = oku("../src/components/app/AppSidebar.tsx");
  const vitrinEditor = oku("../src/components/owner/VitrinimEditor.tsx");

  it("uygulama shell'i ortak web marka tokenlarını yeniden kopyalamadan kullanır", () => {
    const uretilenRenkler = oku("../../lib/theme/renkler.g.dart");
    expect(flutterColors).toContain("primary = OrtakRenkler.lpPrimary");
    expect(flutterColors).toContain("secondary = OrtakRenkler.lpSecondary");
    expect(flutterColors).toContain("bgEditor = OrtakRenkler.lpBgEditor");
    expect(flutterColors).toContain("surface = OrtakRenkler.lpSurface");
    expect(flutterColors).toContain("border = OrtakRenkler.lpBorder");
    expect(uretilenRenkler).toContain("lpPrimary = Color(0xFF147DFF)");
    expect(uretilenRenkler).toContain("lpSecondary = Color(0xFF57B7FF)");
    expect(uretilenRenkler).toContain("lpBgEditor = Color(0xFF050B1A)");
    expect(uretilenRenkler).toContain("lpSurface = Color(0xFF0B1730)");
    expect(uretilenRenkler).toContain("lpBorder = Color(0xFF294D88)");

    expect(globals).toContain("--color-lp-primary: #147DFF");
    expect(globals).toContain("--color-lp-secondary: #57B7FF");
    expect(globals).toContain("--color-lp-bg-editor: #050B1A");
    expect(globals).toContain("--color-lp-surface: #0B1730");
    expect(globals).toContain("--color-lp-border: #294D88");

    expect(appCss).toContain("--vx-app-primary: var(--color-lp-primary)");
    expect(appCss).toContain("--vx-app-secondary: var(--color-lp-secondary)");
    expect(appCss).toContain("--vx-app-bg-editor: var(--color-lp-bg-editor)");
    expect(appCss).toContain("--vx-app-surface: var(--color-lp-surface)");
    expect(appCss).toContain("--vx-app-border: var(--color-lp-border)");
    expect(appCss).not.toContain("--vx-app-primary: #147DFF");
  });

  it("UI sözleşmesi yalnız uygulama shell'ine scoped kalır", () => {
    expect(appCss).toContain(".vixrex-app-shell");
    expect(appBoundary).toContain("vixrex-app-shell");
    expect(appCss).not.toContain(".vitrin-shell");
    expect(appCss).not.toContain('[data-app-tab="vitrinim"] input');
  });

  it("sidebar ve mobil NavigationBar ölçüleri Flutter ile aynıdır", () => {
    expect(flutterSidebar).toContain("this.width = 220");
    expect(flutterTheme).toContain("height: 68");
    expect(appCss).toContain("--vx-app-sidebar-width: 220px");
    expect(appCss).toContain("--vx-app-bottom-nav-height: 68px");
    expect(appNav).toContain("vixrex-app-sidebar");
    expect(appNav).toContain("vixrex-app-bottom-nav");
  });

  it("sidebar seçili/pasif satır ağırlığı ve seçili yüzey Flutter ile aynıdır", () => {
    expect(flutterSidebar).toContain("isSelected ? FontWeight.w800 : FontWeight.w600");
    expect(flutterColors).toContain("primary.withValues(alpha: 0.16)");
    expect(appNav).toContain("font-extrabold");
    expect(appNav).toContain("font-semibold");
    expect(appCss).toContain("rgba(20, 125, 255, 0.16)");
  });

  it("mobil navigasyon ikon ölçüleri ve aktif gösterge Flutter değerlerini izler", () => {
    expect(flutterTheme).toContain("indicatorColor: AppColors.primary.withValues(alpha: 0.22)");
    expect(flutterTheme).toContain("IconThemeData(color: AppColors.secondary, size: 22)");
    expect(appCss).toContain("rgba(20, 125, 255, 0.22)");
    expect(appNav).toContain('item.label === "Vixrex" ? 24 : 22');
    expect(appNav).not.toContain("scale-110");
  });

  it("sidebar arama odağı Flutter InputDecorationTheme 1.5px secondary sınırını izler", () => {
    expect(flutterTheme).toContain("color: AppColors.focusedBorder");
    expect(flutterTheme).toContain("width: 1.5");
    expect(flutterColors).toContain("focusedBorder = secondary");
    expect(appCss).toContain("border-color: var(--vx-app-secondary)");
    expect(appCss).toContain("border-width: 1.5px");
  });

  it("Vitrinim dış sayfa ölçüleri Flutter ile aynı kalır", () => {
    expect(flutterVitrin).toContain("constraints: const BoxConstraints(maxWidth: 1200)");
    expect(flutterVitrin).toContain("horizontal: isDesktop ? 32 : 16");
    expect(flutterVitrin).toContain("vertical: isDesktop ? 28 : 18");
    expect(vitrinEditor).toContain("max-w-[1200px]");
    expect(vitrinEditor).toContain("px-4 py-[18px]");
    expect(vitrinEditor).toContain("min-[901px]:px-8 min-[901px]:py-7");
    expect(appCss).toContain("--vx-app-page-max-width: 1200px");
  });

  it("Vitrinim alan tokenları Flutter EditorTextField referans değerlerini kaydeder", () => {
    expect(flutterFields).toContain("fillColor: AppColors.inputBg");
    expect(flutterFields).toContain("BorderRadius.circular(AppColors.radius14)");
    expect(flutterFields).toContain("fontWeight: FontWeight.w700");
    expect(flutterFields).toContain("horizontal: 14");
    expect(flutterFields).toContain("vertical: 14");
    expect(flutterFields).toContain("width: 1.4");

    expect(appCss).toContain("--vx-app-input-bg: #0D1C38");
    expect(appCss).toContain("--vx-app-radius-editor-field: 14px");
    expect(appCss).toContain("--vx-app-field-pad-x: 14px");
    expect(appCss).toContain("--vx-app-field-pad-y: 14px");
    expect(appCss).toContain("--vx-app-field-font-size: 14px");
    expect(appCss).toContain("--vx-app-field-font-weight: 700");
  });
});
