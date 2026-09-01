import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { yayinSahiplikKarari } from "@/lib/yayinSahiplikKarari";

describe("create-store anonim sahiplik akışı", () => {
  it("Flutter gibi anonim oturumda yayını tamamlar ve cihaz sahipliğini korur", () => {
    expect(yayinSahiplikKarari({ is_anonymous: true })).toEqual({
      claimStore: false,
      hesapKorumasiz: true,
    });
  });

  it("kalıcı kullanıcıda claim_store_for_user güvenlik kapısını korur", () => {
    expect(yayinSahiplikKarari({ is_anonymous: false })).toEqual({
      claimStore: true,
      hesapKorumasiz: false,
    });
  });

  it("API sahiplik çağrısını ortak karara göre koşullu çalıştırır", () => {
    const kaynak = readFileSync(
      resolve(__dirname, "../src/app/api/create-store/route.ts"),
      "utf8",
    );
    expect(kaynak).toContain("yayinSahiplikKarari(user)");
    expect(kaynak).toContain("if (sahiplikKarari.claimStore)");
    expect(kaynak).toContain("hesapKorumasiz: sahiplikKarari.hesapKorumasiz");
    expect(kaynak).toContain('status: "Açık"');
    expect(kaynak).toContain("is_published: true");
  });
});
