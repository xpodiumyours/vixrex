import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const ownerActions = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/hooks/useOwnerActions.ts"),
  "utf8",
);

function secilialanBlogu(): string {
  const baslangic = ownerActions.indexOf("const alan = seciliAlan;");
  const bitis = ownerActions.indexOf("const alanAtla", baslangic);
  if (baslangic < 0) throw new Error("Seçili alan bloğu bulunamadı");
  return ownerActions.slice(baslangic, bitis < 0 ? undefined : bitis);
}

describe("Vixrex Asistan — motor önce sözleşmesi", () => {
  it("her cümle seçili alan olsa bile önce akıllı motora sorulur", () => {
    expect(ownerActions).toContain("resolveVixrexIntentsAll(metin).length > 0");
    expect(ownerActions).toContain("motorSonucu = await handleVixrexNluMessage(metin)");
  });

  it("motor yalnız kesin çözdüğünde seçili alanı devre dışı bırakır", () => {
    expect(ownerActions).toContain(
      'motorSonucu?.outcome === "handled" && (motorSonucu.tumu?.length ?? 0) > 0',
    );
    expect(ownerActions).toContain("if (!seciliAlan || motorCozdu) {");
  });

  it("motor emin değilken arka planda alan yazılmaz, yalnız sorulur", () => {
    const blok = secilialanBlogu();
    const soruIndex = blok.indexOf("Bu cümlede birden fazla bilgi var gibi görünüyor");
    expect(soruIndex).toBeGreaterThan(-1);
    const soruSonrasi = blok.slice(soruIndex, soruIndex + 400);
    expect(soruSonrasi).not.toContain("bonusAlanlariCikarVeKaydet");
  });
});
