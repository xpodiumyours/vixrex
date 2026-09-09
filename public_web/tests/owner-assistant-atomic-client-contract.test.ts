import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const source = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/hooks/useOwnerActions.ts"),
  "utf8",
);

function serbestMesajBlogu(): string {
  const baslangic = source.indexOf("if (!seciliAlan) {");
  const bitis = source.indexOf("const alan = seciliAlan;", baslangic);
  if (baslangic < 0 || bitis < 0) throw new Error("Serbest mesaj bloğu bulunamadı");
  return source.slice(baslangic, bitis);
}

describe("Vixrex Assistant istemci atomik kayıt sözleşmesi", () => {
  it("serbest mesaj tek veya çok alan fark etmeksizin batch endpoint üzerinden tek istekte gider", () => {
    const blok = serbestMesajBlogu();
    expect(blok).toContain('fetch("/api/owner-draft-batch"');
    expect(blok).toContain("degisiklikler: cozulen.map");
    expect(blok).not.toContain('fetch("/api/owner-draft"');
    expect(blok).not.toContain("if (cozulen.length > 1)");
  });

  it("yerel görünümü pipeline tahmini yerine sunucu kayıt sonucundan günceller", () => {
    const blok = serbestMesajBlogu();
    expect(blok).toContain("govde.degisiklikler");
    expect(blok).toContain("setAlan(item.kolon, item.deger)");
    expect(blok).toContain("kaydedilen.length !== cozulen.length");
  });

  it("seçili alan içindeki bonus çıkarımlar da parçalı tekil yazım yapmaz", () => {
    const baslangic = source.indexOf("export async function bonusAlanlariCikarVeKaydet");
    const bitis = source.indexOf("export function useOwnerActions", baslangic);
    const bonus = source.slice(baslangic, bitis);
    expect(bonus).toContain('fetch("/api/owner-draft-batch"');
    expect(bonus).toContain("degisiklikler: bulunanlar.map");
    expect(bonus).not.toContain("Promise.all(");
    expect(bonus).not.toContain('fetch("/api/owner-draft"');
  });
});
