import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

describe("Vitrinim görsel kabuk paritesi", () => {
  const flutterForm = oku("../../lib/screens/my_vitrin/sections/vitrin_form_section.dart");
  const flutterMeter = oku("../../lib/widgets/editor/vitrin_completion_meter.dart");
  const flutterAccordion = oku("../../lib/widgets/editor/form_accordion_section.dart");
  const appCss = oku("../src/app/vixrex-app-ui.css");
  const webEditor = oku("../src/components/owner/VitrinimEditor.tsx");

  it("form kartı Flutter'daki 22px radius ve aynı border/surface sözleşmesini kullanır", () => {
    expect(flutterForm).toContain("borderRadius: BorderRadius.circular(22)");
    expect(flutterForm).toContain("color: AppColors.surface");
    expect(flutterForm).toContain("border: Border.all(color: AppColors.cardBorderDark)");
    expect(webEditor).toContain('aria-labelledby="vitrinim-editor-title"');
    expect(appCss).toContain("--vx-app-radius-vitrin-form: 22px");
    expect(appCss).toContain('[aria-labelledby="vitrinim-editor-title"]');
  });

  it("tamamlanma ölçeri Flutter 24/20/24/16 ve blueSurface ayırıcısını izler", () => {
    expect(flutterMeter).toContain("AppColors.spacing24");
    expect(flutterMeter).toContain("AppColors.spacing20");
    expect(flutterMeter).toContain("AppColors.spacing16");
    expect(flutterMeter).toContain("AppColors.blueSurface");
    expect(appCss).toContain("padding: 20px 24px 16px");
    expect(appCss).toContain("border-bottom-color: var(--vx-app-blue-surface)");
  });

  it("yüzde ve yardımcı metin tipografisi Flutter değerlerini izler", () => {
    expect(flutterMeter).toContain("fontWeight: FontWeight.w700");
    expect(appCss).toContain("font-size: 12px");
    expect(appCss).toContain("font-weight: 700");
    expect(appCss).toContain("font-weight: 400");
    expect(appCss).toContain("line-height: 1.4");
  });

  it("akordeon Flutter gibi yalnız alt ayırıcı kullanır ve başlık padding'i 24x16'dır", () => {
    expect(flutterAccordion).toContain("border: Border(bottom: BorderSide(color: AppColors.blueSurface))");
    expect(flutterAccordion).toContain("horizontal: AppColors.spacing24");
    expect(flutterAccordion).toContain("vertical: AppColors.spacing16");
    expect(appCss).toContain("border-right-width: 0 !important");
    expect(appCss).toContain("padding: 16px 24px");
  });

  it("akordeon başlığı Flutter subTitle 16/w800 ve gövde alt padding 20 değerini izler", () => {
    expect(flutterAccordion).toContain("Text(title, style: AppTextStyles.subTitle)");
    expect(flutterAccordion).toContain("AppColors.spacing20");
    expect(appCss).toContain("font-size: 16px");
    expect(appCss).toContain("font-weight: 800");
    expect(appCss).toContain("padding-bottom: 20px");
  });
});
