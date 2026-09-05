import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Serbest metinle alan doldurma (2026-09-02) — ayrı bir ekran elemanı yok;
 * mevcut soru kutusu kullanılır. 5.6 itibarıyla motorun çıkardığı alanlar
 * authoritative command/action/version/Undo yoluna girer.
 */
describe("OwnerAssistantPanel — yeni bir ekran elemanı yok", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("panelde serbest anlatım kartına/state'ine dair hiçbir iz yok", () => {
    expect(panel).not.toContain("anlatimAcik");
    expect(panel).not.toContain("IsletmeniAnlatKarti");
    expect(panel).not.toContain("serbestMetindenAlanlariCikar");
  });

  it("panel açılınca otomatik ilk-alan seçimi eski hâliyle çalışıyor", () => {
    expect(panel).toContain("if (!acik || seciliAlan) return;");
  });
});

describe("useOwnerActions.gonder() — mevcut kutuda authoritative rich-text/bonus", () => {
  const kaynak = oku("app/v/[slug]/hooks/useOwnerActions.ts");

  it("kısa/tek kelimelik cevaplarda gereksiz motor çalıştırmaz", () => {
    expect(kaynak).toContain("metin.length >= 15");
  });

  it("az önce doğrudan cevaplanan alan bonus setinden hariç tutulur — çift yazma yok", () => {
    expect(kaynak).toContain("alan.kolon === cevaplananKolon");
  });

  it("çalışma saatleri generic bonus/rich-text mutation'a sokulmaz", () => {
    expect(kaynak).toContain('if (anahtar === "calismaSaatleri") return null');
    expect(kaynak).toContain('alan.anahtar !== "calismaSaatleri"');
  });

  it("bonus tek authoritative command kullanır ve legacy owner-draft'a düşmez", () => {
    const baslangic = kaynak.indexOf("export async function bonusAlanlariCikarVeKaydet");
    const bitis = kaynak.indexOf("export function useOwnerActions", baslangic);
    const fonksiyon = kaynak.slice(baslangic, bitis);
    expect(fonksiyon).toContain("executeSmartEngineCommand({");
    expect(fonksiyon).toContain("initialDraftVersion");
    expect(fonksiyon).toContain("onDraftVersion(commandResult.draftVersion)");
    expect(fonksiyon).not.toContain('fetch("/api/owner-draft"');
  });

  it("seçili rich-text ana değer ve bonusları tek command/Undo altında toplar", () => {
    const baslangic = kaynak.indexOf("if (richTextMotorEnabled) {");
    const bitis = kaynak.indexOf('const yanit = await fetch("/api/owner-draft"', baslangic);
    const blok = kaynak.slice(baslangic, bitis);
    expect(blok).toContain("executeSmartEngineCommand({");
    expect(blok).toContain("bonusAlanlar.map");
    expect(blok).toContain('payload: `geri_al:command:${commandResult.commandId}`');
  });

  it("bonus bulunca aynı ✓ liste stilini kullanır", () => {
    expect(kaynak).toContain("Yazdığından ayrıca şunları da anladım");
    expect(kaynak).toContain("basarili.map(({ etiket }) => `✓ ${etiket}`)");
  });
});
