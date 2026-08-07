import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// Ölü alan adı nöbetçisi.
//
// 2026-08-07: vitrin sayfasında üç yerde `https://vixrex.com` elle yazılıydı.
// O alan adı KAYITLI DEĞİL — DNS'te yok. "Vitrin Oluştur" ve "Bu vitrini
// kirala" düğmeleri hiçbir yere gitmiyordu; paylaşım kutusunda da ölü bir
// adres yazıyordu. En sinsisi buydu: "Kopyala" doğru adresi kopyalıyordu,
// ekrandaki yazı yalan söylüyordu. Adresi okuyup elle yazan ya da
// müşterisine sözlü söyleyen esnaf kaybediyordu.
//
// Casper'ın turunda çıktı. Ürünün tek cümlelik vaadi "tek linkte hazır
// vitrin" — link ölüyse geri kalan her şey anlamsız.

/** Yorumları çıkarır — açıklamada adı geçmesi hata değil, kodda geçmesi hata. */
function kodSatirlari(kaynak: string): string {
  const blokYorumsuz = kaynak.replace(/\/\*[\s\S]*?\*\//g, "");
  return blokYorumsuz
    .split("\n")
    .filter((satir) => !satir.trim().startsWith("//"))
    .join("\n");
}

const KAYNAKLAR = [
  "../src/app/v/[slug]/VitrinProfileView.tsx",
  "../src/app/v/[slug]/OwnerAssistantPanel.tsx",
  "../src/app/page.tsx",
  "../src/lib/siteUrl.ts",
];

describe("Adresler tek kaynaktan gelir", () => {
  for (const yol of KAYNAKLAR) {
    it(`${yol.split("/").pop()} içinde elle yazılmış vixrex.com yok`, () => {
      const kod = kodSatirlari(readFileSync(resolve(__dirname, yol), "utf-8"));
      expect(
        kod.includes("vixrex.com"),
        "Elle yazılmış vixrex.com bulundu. O alan adı kayıtlı değil; " +
          "adres getSiteUrl() / getAppUrl() üzerinden gelmeli."
      ).toBe(false);
    });
  }

  it("uygulama adresi tek bir yerde tanımlı", () => {
    const siteUrl = readFileSync(
      resolve(__dirname, "../src/lib/siteUrl.ts"),
      "utf-8"
    );
    expect(siteUrl).toContain("export function getAppUrl");

    // page.tsx kendi kopyasını tutmamalı — iki kaynak iki gerçek demek.
    const page = readFileSync(resolve(__dirname, "../src/app/page.tsx"), "utf-8");
    expect(page).toContain('from "@/lib/siteUrl"');
    expect(page).not.toContain("function getAppUrl");
  });

  it("paylaşım kutusu kopyalananla aynı adresi gösterir", () => {
    const view = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
      "utf-8"
    );
    expect(view).toContain("{formattedUrlDisplay}");
  });
});
