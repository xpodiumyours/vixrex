import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { GET as okuyucuDurumu } from "@/app/api/fatura-okuyucu-durumu/route";

// "Faturadan Ekle" düğmesi bu uca bakarak gösteriliyor. Okuyucu anahtarı
// yoksa düğme hiç çıkmamalı — esnaf çalışmayacak bir düğmeye basıp hata
// görmesin. Bu uç ayrıca anahtarın kendisini ASLA dışarı vermemeli.

describe("/api/fatura-okuyucu-durumu", () => {
  const onceki = process.env.OPENROUTER_API_KEY;

  beforeEach(() => {
    delete process.env.OPENROUTER_API_KEY;
  });

  afterEach(() => {
    if (onceki === undefined) delete process.env.OPENROUTER_API_KEY;
    else process.env.OPENROUTER_API_KEY = onceki;
  });

  it("anahtar yoksa hazır değil der", async () => {
    const govde = await (await okuyucuDurumu()).json();
    expect(govde).toEqual({ hazir: false });
  });

  it("anahtar varsa hazır der", async () => {
    process.env.OPENROUTER_API_KEY = "deneme-anahtari";
    const govde = await (await okuyucuDurumu()).json();
    expect(govde).toEqual({ hazir: true });
  });

  it("anahtarın hiçbir parçasını dışarı vermez", async () => {
    process.env.OPENROUTER_API_KEY = "sk-or-cok-gizli-deger-123456";
    const ham = await (await okuyucuDurumu()).text();
    expect(ham).not.toContain("sk-or");
    expect(ham).not.toContain("gizli");
    expect(ham).toBe(JSON.stringify({ hazir: true }));
  });
});
