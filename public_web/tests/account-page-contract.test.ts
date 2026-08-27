import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const accountPath = resolve(__dirname, "../src/app/app/hesap/page.tsx");
const dashboard = readFileSync(
  resolve(__dirname, "../src/app/app/page.tsx"),
  "utf8"
);

describe("hesap ve vitrin silme kullanıcı sözleşmesi", () => {
  it("hesap ekranına panodan ulaşılır", () => {
    expect(dashboard).toContain('href="/app/hesap"');
    expect(dashboard).toContain("Hesap");
  });

  it("üç işlemin etkisini işlemden önce açıklar", () => {
    expect(existsSync(accountPath), "hesap sayfası yok").toBe(true);
    const source = readFileSync(accountPath, "utf8");

    for (const text of [
      "Vitrini Yayından Kaldır",
      "Vitrini Kalıcı Sil",
      "Hesabı Kalıcı Sil",
      "Verileriniz korunur",
      "ürünleriniz",
      "blog yazılarınız",
      "randevularınız",
      "Bu işlem geri alınamaz",
    ]) {
      expect(source, `${text} açıklaması eksik`).toContain(text);
    }
    expect(source).toContain("owner-shell");
    expect(source.match(/#[0-9A-Fa-f]{6}/g) ?? []).toEqual([]);
  });

  it("kalıcı silmelerde SİL yazılmasını ve doğru API hedefini zorunlu tutar", () => {
    const source = readFileSync(accountPath, "utf8");

    expect(source).toContain('placeholder="SİL"');
    expect(source).toContain('vitrinOnayi.trim() !== "SİL"');
    expect(source).toContain('hesapOnayi.trim() !== "SİL"');
    expect(source).toContain('fetch("/api/account"');
    expect(source).toContain('target: "store"');
    expect(source).toContain('target: "account"');
    expect(source).toContain('method: "PATCH"');
    expect(source).toContain('method: "DELETE"');
  });
});
