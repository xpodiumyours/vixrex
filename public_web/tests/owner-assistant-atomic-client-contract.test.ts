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
  it("çok alanlı serbest mesajı batch endpoint üzerinden tek istekte gönderir", () => {
    const blok = serbestMesajBlogu();
    expect(blok).toContain("if (cozulen.length > 1)");
    expect(blok).toContain('fetch("/api/owner-draft-batch"');
    expect(blok).toContain("degisiklikler: cozulen.map");
  });

  it("çok alanlı dalda alan başına owner-draft döngüsü kurmaz", () => {
    const blok = serbestMesajBlogu();
    const cokluBaslangic = blok.indexOf("if (cozulen.length > 1)");
    const tekliBaslangic = blok.indexOf("} else {", cokluBaslangic);
    const coklu = blok.slice(cokluBaslangic, tekliBaslangic);
    expect(coklu).not.toContain('fetch("/api/owner-draft"');
  });

  it("tek alan için mevcut owner-draft yolu korunur", () => {
    const blok = serbestMesajBlogu();
    expect(blok).toContain("Tek alan için mevcut kanonik yol korunur");
    expect(blok).toContain('fetch("/api/owner-draft"');
  });

  it("yerel görünümü pipeline tahmini yerine sunucu kayıt sonucundan günceller", () => {
    const blok = serbestMesajBlogu();
    expect(blok).toContain("govde.degisiklikler");
    expect(blok).toContain("setAlan(item.kolon, item.deger)");
    expect(blok).toContain("kaydedilen.length !== cozulen.length");
  });
});
