import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { yonetimOnerileriUret } from "@/lib/yonetimOnerileri";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

describe("yonetimOnerileriUret — kural motoru", () => {
  it("her şey doluysa öneri yok", () => {
    const oneriler = yonetimOnerileriUret(
      { working_hours: "09:00-18:00", logo_url: "https://x.com/l.png" },
      0,
      0
    );
    expect(oneriler).toEqual([]);
  });

  it("fiyatsız ürün varsa uyarır", () => {
    const oneriler = yonetimOnerileriUret({}, 3, 0);
    expect(oneriler.find((o) => o.id === "urun_fiyat")?.mesaj).toContain("3 ürününde fiyat yok");
  });

  it("çalışma saatleri boşsa uyarır", () => {
    const oneriler = yonetimOnerileriUret({ working_hours: "" }, 0, 0);
    expect(oneriler.some((o) => o.id === "calisma_saatleri")).toBe(true);
  });

  it("logo boşsa uyarır", () => {
    const oneriler = yonetimOnerileriUret({ logo_url: null }, 0, 0);
    expect(oneriler.some((o) => o.id === "logo")).toBe(true);
  });

  it("açıklamasız ürün 3'ten azsa uyarmaz — gürültü yapmaz", () => {
    const oneriler = yonetimOnerileriUret({}, 0, 2);
    expect(oneriler.some((o) => o.id === "urun_aciklama")).toBe(false);
  });
});

describe("OwnerAssistantPanel — yönetim modu yalnız yayınlanmış vitrinde konuşur", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("öneriler sayfa açılınca sohbete yazılmaz — Öneriler sekmesinde durur", () => {
    expect(panel).not.toContain("yonetimOnerisiSoylendiRef");
    expect(panel).toContain('useState<"sohbet" | "oneriler">');
    expect(panel).toContain("yonetimOnerileriUret(");
  });

  it("ürün sayaçları page.tsx'te zaten çekilmiş visibleProducts'tan türetiliyor — yeni sorgu yok", () => {
    const sayfa = oku("app/v/[slug]/page.tsx");
    expect(sayfa).toContain("visibleProducts.filter((p) => !p.price).length");
    expect(sayfa).toContain("visibleProducts.filter((p) => !p.description?.trim()).length");
  });
});
