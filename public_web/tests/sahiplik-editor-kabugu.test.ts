import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (relativePath: string) =>
  readFileSync(resolve(__dirname, relativePath), "utf-8");

const bar = oku("../src/app/v/[slug]/components/OwnerEditorBar.tsx");
const panel = oku("../src/app/v/[slug]/OwnerAssistantPanel.tsx");
const vitrin = oku("../src/app/v/[slug]/VitrinProfileView.tsx");
const globals = oku("../src/app/globals.css");

describe("sahiplik modu editör kabuğu", () => {
  it("kabuk ölçüleri tek yerde tanımlı", () => {
    expect(globals).toContain("--owner-bar-h: 64px;");
    expect(globals).toContain("--owner-rail-w: 420px;");
  });

  it("editör çubuğu yalnız masaüstünde çizilir", () => {
    expect(bar).toContain("h-[var(--owner-bar-h)]");
    expect(bar).toContain("hidden");
    expect(bar).toContain("lg:flex");
  });

  it("çubuk panelin kendi durumundan besleniyor, yayın eksikse Eksikler sekmesine yönlendiriyor", () => {
    expect(panel).toContain("<OwnerEditorBar");
    expect(panel).toContain("kaydediliyor={actions.kaydediliyor}");
    expect(panel).toContain("rapor.temelTamam");
    expect(panel).toContain("actions.yayinla");
    expect(panel).toContain('setSekme("eksikler")');
  });

  it("yasal onay yoksa çubuk yayınlamaz, paneli açar", () => {
    expect(bar).toContain("yasalOnayli ? onYayinla : onYasalOnayGerek");
  });

  it("masaüstünde bilgi iki yerde tekrarlanmaz", () => {
    expect(bar).not.toContain("%{yuzde}");
    const top = oku("../src/app/v/[slug]/components/ChatTopBar.tsx");
    expect(top).toContain("lg:hidden");
    expect(top).toContain("hidden items-center gap-2 sm:flex lg:hidden");
  });

  it("masaüstü paneli sohbet / alanlar / eksikler olarak ayrılır", () => {
    expect(panel).toContain('useState<"sohbet" | "alanlar" | "eksikler">');
    expect(panel).toContain('data-vixrex-desktop-tabs="true"');
    expect(panel).toContain('["sohbet", "Sohbet"]');
    expect(panel).toContain('["alanlar", "Alanlar"]');
    expect(panel).toContain('["eksikler", "Eksikler"]');
    expect(panel).toContain("SectionProgressList");
    expect(panel).toContain("Yayın için gerekli");
    expect(panel).toContain("Kalite önerileri");
    expect(panel).toContain("yonetimOnerileriUret(");
  });

  it("koyu yüzey bildirimi tek yerde, vitrin kökü onu taşır", () => {
    expect(globals).toContain("html:has(.vixrex-koyu-yuzey)");
    expect(globals).toContain("color-scheme: dark;");
    expect(vitrin).toContain("vixrex-koyu-yuzey min-h-screen");
  });

  it("masaüstünde tuval kendi kaydırmasını yönetir, sayfa ikinci kez kaymaz", () => {
    expect(vitrin).toContain("lg:h-[calc(100vh-var(--owner-bar-h))] lg:overflow-y-auto");
  });

  it("tuval vurgusu sürekli glow yerine hover + tek seçim modeli kullanır", () => {
    expect(globals).toContain("outline: 1px solid transparent;");
    expect(globals).toContain("@media (hover: hover) and (pointer: fine)");
    expect(globals).toContain("outline: 2px solid rgba(56, 160, 228, 0.95) !important;");
    expect(globals).toContain("box-shadow: none !important;");
    expect(globals).not.toContain("outline: 2px dashed transparent;");
    expect(globals).not.toContain("--vrx-glow");
    expect(globals).not.toContain(
      'body.vixrex-asistan-acik [data-vixrex-editable][data-vixrex-onem="temel"]',
    );
  });

  it("alan seçimi sohbete yazılmaz — kart gösterir", () => {
    expect(oku("../src/app/v/[slug]/hooks/useFieldSelection.ts")).not.toContain(
      "alanını seçtin. Yeni değeri yaz"
    );
  });

  it("uzun asistan mesajları katlanır", () => {
    expect(oku("../src/app/v/[slug]/components/ChatBubble.tsx")).toContain(
      "UZUN_MESAJ_SATIRI"
    );
  });

  it("panel masaüstünde yüzen kutu değil, yerleşik sütun", () => {
    expect(panel).toContain("lg:top-[var(--owner-bar-h)]");
    expect(panel).toContain("lg:w-[var(--owner-rail-w)]");
    expect(panel).toContain("lg:rounded-none");
    const top = oku("../src/app/v/[slug]/components/ChatTopBar.tsx");
    expect(top).toContain("@media (min-width: 640px) and (max-width: 1023px)");
    expect(top).not.toContain("@media (min-width: 640px) {");
  });

  it("mobil compact composer masaüstünde çizilmez", () => {
    expect(panel).toContain('data-vixrex-mobile-dock="true"');
    expect(panel).toContain("sm:hidden");
    expect(panel).toContain("!masaustu && !haritaAcik");
  });

  it("vitrin tuvali çubuk ve sütun payını alır", () => {
    expect(vitrin).toContain("lg:pt-[var(--owner-bar-h)] lg:pr-[var(--owner-rail-w)]");
    expect(vitrin).toContain('ownerMode ? "lg:right-[var(--owner-rail-w)] lg:top-[var(--owner-bar-h)]" : ""');
  });
});


describe("masaüstü asistan bilgi mimarisi", () => {
  it("maskot geniş masaüstünde başlığın sağındadır", () => {
    const top = oku("../src/app/v/[slug]/components/ChatTopBar.tsx");
    expect(top).toContain("sm:order-1 lg:order-4");
    expect(top).toContain("<VixrexAvatar size={38} halo decorative />");
  });

  it("sohbet sekmesi sade compact composer kullanır", () => {
    expect(panel).toContain('sekme === "sohbet"');
    expect(panel).toContain("<FieldInputArea\n                      compact");
    expect(panel).toContain("Tek mesajla birden fazla alan");
  });

  it("yayın düğmesi panelde ikinci kez gösterilmez", () => {
    expect(panel).toContain("showPublishButton={false}");
    const publish = oku("../src/app/v/[slug]/components/PublishBar.tsx");
    expect(publish).toContain("showPublishButton = true");
    expect(publish).toContain("{showPublishButton ? (");
  });

  it("ayarlar butonu alanlar sekmesini açar", () => {
    expect(panel).toContain('setSekme("alanlar")');
    expect(panel).toContain("setHaritaAcik(true)");
  });

  it("yasal onay ihtiyacı eksikler sekmesine gider", () => {
    expect(panel).toContain('setSekme("eksikler")');
  });
});
