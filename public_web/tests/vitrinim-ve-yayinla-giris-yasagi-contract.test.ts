import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

describe("Vitrinim ve Yayinla Google giris yasagi sozlesmesi", () => {
  const appPage = oku("src/app/app/page.tsx");
  const landing = oku("src/components/landing/LandingAsistanSohbeti.tsx");

  it("app/page.tsx icinde /giris veya /kayit zorla yonlendirmesi yok", () => {
    expect(appPage).not.toContain('router.push("/giris")');
    expect(appPage).not.toContain('router.replace("/giris")');
    expect(appPage).not.toContain('router.push("/kayit")');
  });

  it("LandingAsistanSohbeti.tsx icinde /giris veya /kayit zorla yonlendirmesi yok", () => {
    expect(landing).not.toContain('router.push("/kayit")');
    expect(landing).not.toContain('router.push("/giris")');
  });

  it("anon basarisiz olsa bile /api/owner-workspace/current kontrolune ve VitrinimEditor creation ekranina ulasilir", () => {
    expect(appPage).toContain('fetch("/api/owner-workspace/current"');
    expect(appPage).toContain("<VitrinimEditor");
    expect(appPage).toContain("isCreationMode");
    expect(appPage).toContain('slug: "taslak"');
    expect(appPage).toContain("setStores([])");
  });

  it("onCreate icinde anon tekrar denenir ve redirect yok", () => {
    expect(appPage).toContain("signInAnonymously");
  });
});
