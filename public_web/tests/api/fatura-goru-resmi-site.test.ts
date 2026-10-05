import { beforeEach, describe, expect, it, vi } from "vitest";
import { faturayiOku } from "@/lib/faturaGoru";

function modelCevabi(govde: unknown): Response {
  return new Response(
    JSON.stringify({
      choices: [{ message: { content: JSON.stringify(govde) } }],
      usage: { cost: 0.001 },
    }),
    { status: 200 },
  );
}

const SATIR = {
  ham_satir: "500 g Peynir 2 AD 80,00 160,00",
  model: "",
  ad: "500 g Peynir",
  barkod: "",
  varyant: "",
  beden: "",
  marka: "",
  adet: 2,
  birim_fiyat: 80,
  tutar: 160,
};

describe("okuma — belgede yazmayan resmi site", () => {
  beforeEach(() => {
    process.env.OPENROUTER_API_KEY = "test-okuyucu-anahtari";
    vi.unstubAllGlobals();
  });

  it("okuma sorusunda resmi site alanı istenir", async () => {
    const fetchMock = vi.fn(async () =>
      modelCevabi({
        tedarikci: "Ornek Tekstil",
        tedarikci_site: "",
        tedarikci_resmi_site: "",
        satirlar: [SATIR],
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await faturayiOku("data:image/png;base64,eA==");

    const istek = (fetchMock.mock.calls as unknown[][])[0][1] as RequestInit;
    expect(String(istek.body)).toContain("tedarikci_resmi_site");
  });

  it("modelin söylediği adres ayrı alanda okunur, belgedeki siteyle karışmaz", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        modelCevabi({
          tedarikci: "Ornek Tekstil",
          tedarikci_site: "",
          tedarikci_resmi_site: "ornektekstil.com",
          satirlar: [SATIR],
        }),
      ),
    );

    const sonuc = await faturayiOku("data:image/png;base64,eA==");

    expect(sonuc.tedarikciResmiSite).toBe("ornektekstil.com");
    expect(sonuc.tedarikciSite).toBe("");
    expect(sonuc.tedarikci).toBe("Ornek Tekstil");
  });

  it("belgede site yazıyorsa o kalır, resmi site alanı boş döner", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        modelCevabi({
          tedarikci: "Ornek Tekstil",
          tedarikci_site: "belgedeki-site.com",
          tedarikci_resmi_site: "",
          satirlar: [SATIR],
        }),
      ),
    );

    const sonuc = await faturayiOku("data:image/png;base64,eA==");

    expect(sonuc.tedarikciSite).toBe("belgedeki-site.com");
    expect(sonuc.tedarikciResmiSite).toBe("");
  });
});
