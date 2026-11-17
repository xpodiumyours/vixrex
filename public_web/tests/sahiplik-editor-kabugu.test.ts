import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  alanSecimiPaneliAcarMi,
  asistanYuzeyi,
} from "../src/app/v/[slug]/asistanYuzeyi";

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

  it("çubuk panelin kendi durumundan besleniyor, yayın eksikse alan listesini açıyor", () => {
    expect(panel).toContain("<OwnerEditorBar");
    expect(panel).toContain("kaydediliyor={actions.kaydediliyor}");
    expect(panel).toContain("rapor.temelTamam");
    expect(panel).toContain("actions.yayinla");
    expect(panel).not.toContain("setSekme");
  });

  it("yasal onay yoksa çubuk yayınlamaz, paneli açar", () => {
    expect(bar).toContain("yasalOnayli ? onYayinla : onYasalOnayGerek");
  });

  it("masaüstünde bilgi iki yerde tekrarlanmaz", () => {
    expect(bar).not.toContain("%{yuzde}");
    const top = oku("../src/app/v/[slug]/components/ChatTopBar.tsx");
    expect(top).toContain("lg:hidden");
    expect(top).not.toContain("%{rapor.yuzde}");
    expect(top).toContain("<PublishBar {...yayin} yuzde={rapor.yuzde} />");
  });

  it("hazırlık yüzdesi yayın düğmesinin içinde doluluk olarak durur", () => {
    const publish = oku("../src/app/v/[slug]/components/PublishBar.tsx");
    expect(publish).toContain("style={{ width: `${doluluk}%` }}");
    expect(publish).toContain("%{doluluk}");
    expect(publish).toContain("yasalOnayli ? void yayinla() : setOnayAcik");
  });

  it("panel tek gövde: sekme yok, liste ve öneriler aynı sohbette", () => {
    expect(panel).toContain('data-vixrex-tek-govde="true"');
    expect(panel).not.toContain("data-vixrex-desktop-tabs");
    expect(panel).not.toContain('["alanlar", "Alanlar"]');
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
    const hook = oku("../src/app/v/[slug]/hooks/useFieldSelection.ts");
    expect(hook).not.toContain("alanını seçtin. Yeni değeri yaz");
    expect(hook).not.toContain("Bu alanı mı düzelteceksiniz");
  });

  it("alana tıklamak panel açmaz", () => {
    expect(alanSecimiPaneliAcarMi()).toBe(false);
    expect(panel).toContain("alanSecimiPaneliAcarMi()");
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

  it("telefon çubuğu masaüstünde ve tablette çizilmez, tablette kutu çizilir", () => {
    const telefon = asistanYuzeyi({
      masaustu: false,
      genisEkran: false,
      acik: false,
      haritaAcik: false,
      mobilGecmisAcik: false,
    });
    expect(telefon.telefonCubugu).toBe(true);

    const tablet = asistanYuzeyi({
      masaustu: false,
      genisEkran: true,
      acik: true,
      haritaAcik: false,
      mobilGecmisAcik: true,
    });
    expect(tablet.telefonCubugu).toBe(false);
    expect(tablet.panelKutusu).toBe(true);

    const masaustu = asistanYuzeyi({
      masaustu: true,
      genisEkran: true,
      acik: true,
      haritaAcik: false,
      mobilGecmisAcik: false,
    });
    expect(masaustu.telefonCubugu).toBe(false);
    expect(masaustu.panelKutusu).toBe(true);

    const telefondaPanel = asistanYuzeyi({
      masaustu: false,
      genisEkran: false,
      acik: true,
      haritaAcik: false,
      mobilGecmisAcik: true,
    });
    expect(telefondaPanel.telefonCubugu).toBe(true);
    expect(telefondaPanel.panelKutusu).toBe(false);
  });

  it("detay açılsa da tek gövde sohbet kalır, telefon çubuğu kaybolmaz", () => {
    const detay = asistanYuzeyi({
      masaustu: false,
      genisEkran: false,
      acik: true,
      haritaAcik: true,
      mobilGecmisAcik: true,
    });
    expect(detay.govde).toBe("sohbet");
    expect(detay.detayAcik).toBe(true);
    expect(detay.telefonCubugu).toBe(true);

    const detayKapali = asistanYuzeyi({
      masaustu: true,
      genisEkran: true,
      acik: true,
      haritaAcik: false,
      mobilGecmisAcik: false,
    });
    expect(detayKapali.govde).toBe("sohbet");
    expect(detayKapali.detayAcik).toBe(false);
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

  it("panel tek compact composer kullanır", () => {
    expect(panel).toContain("compact");
    expect(panel).toContain("kayitliDeger={seciliAlanKayitliDeger}");
  });

  it("yayın çubuğu başlıkta tek kez çizilir, altta yok", () => {
    expect(panel).not.toContain("<PublishBar");
    expect(panel).toContain("yayin={{");
    const top = oku("../src/app/v/[slug]/components/ChatTopBar.tsx");
    expect(top.split("<PublishBar").length - 1).toBe(1);
    expect(top).not.toContain("showPublishButton={false}");
  });

  it("ayarlar butonu alan listesini açar", () => {
    expect(panel).toContain("onAyarlar={() => {");
    expect(panel).toContain("setHaritaAcik(true)");
  });

  it("yasal onay ihtiyacı alan listesini açar", () => {
    expect(panel).toContain("onYasalOnayGerek={() => {");
    expect(panel).not.toContain("setSekme");
  });
});
