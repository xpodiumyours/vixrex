import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";

const mockRevalidateTag = vi.fn();
const mockRevalidatePath = vi.fn();

vi.mock("next/cache", () => ({
  revalidateTag: (...args: unknown[]) => mockRevalidateTag(...args),
  revalidatePath: (...args: unknown[]) => mockRevalidatePath(...args),
}));

import { POST } from "@/app/api/revalidate/route";

/**
 * `REVALIDATION_SECRET` kablosu.
 *
 * Uygulamadaki (Flutter) kayıt/publish sonrası `/api/revalidate` çağrısı web
 * önbelleğini anında düşürür. Uç, anahtar sunucuda tanımlı değilse ya da
 * başlık eşleşmiyorsa 401 döner (fail-closed).
 *
 * 2026-10-03 bulgusu: uç Vercel'de tanımlıydı ama HİÇBİR Flutter derlemesine
 * `--dart-define=REVALIDATION_SECRET` verilmiyordu → `String.fromEnvironment`
 * hep boş → `SeoService` isteği hiç atmıyor, atsa da 401 yeriyordu. Bu test
 * hem uç davranışını hem de derleme dosyalarındaki kabloyu kilitler.
 */
describe("POST /api/revalidate — güvenlik", () => {
  const ANAHTAR = "test-revalidation-secret";

  function istek(govde: unknown, secret?: string) {
    return new NextRequest("http://localhost/api/revalidate", {
      method: "POST",
      headers: secret ? { "x-revalidate-secret": secret } : {},
      body: JSON.stringify(govde),
    });
  }

  beforeEach(() => {
    vi.clearAllMocks();
    delete process.env.REVALIDATION_SECRET;
  });

  afterEach(() => {
    delete process.env.REVALIDATION_SECRET;
  });

  it("REVALIDATION_SECRET tanımlı değilse fail-closed 401 döner", async () => {
    const res = await POST(istek({ tags: ["store-x"] }, ANAHTAR));
    expect(res.status).toBe(401);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("başlık yoksa 401 döner, hiçbir önbellek düşürülmez", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(istek({ tags: ["store-x"] }));
    expect(res.status).toBe(401);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
  });

  it("başlık yanlışsa 401 döner", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(istek({ tags: ["store-x"] }, "yanlis-deger"));
    expect(res.status).toBe(401);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
  });

  it("doğru anahtarla tag düşürülür ve expire:0 verilir (anında tazelensin)", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(istek({ tags: ["store-x", "products-x"] }, ANAHTAR));

    expect(res.status).toBe(200);
    expect(mockRevalidateTag).toHaveBeenCalledTimes(2);
    expect(mockRevalidateTag).toHaveBeenCalledWith("store-x", { expire: 0 });
    expect(mockRevalidateTag).toHaveBeenCalledWith("products-x", {
      expire: 0,
    });
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("path istekleri revalidatePath ile karşılanır", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(
      istek({ paths: ["/v/x", "/v/x/urun/y"] }, ANAHTAR)
    );

    expect(res.status).toBe(200);
    expect(mockRevalidatePath).toHaveBeenCalledTimes(2);
    expect(mockRevalidatePath).toHaveBeenCalledWith("/v/x", "page");
    expect(mockRevalidateTag).not.toHaveBeenCalled();
  });

  it("tag + path birlikte gelebilir — ikisi de işlenir", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(
      istek({ tag: "sitemap", path: "/v/x" }, ANAHTAR)
    );

    expect(res.status).toBe(200);
    expect(mockRevalidateTag).toHaveBeenCalledWith("sitemap", { expire: 0 });
    expect(mockRevalidatePath).toHaveBeenCalledWith("/v/x", "page");
  });

  it("ne tag ne path varsa 400 döner", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(istek({}, ANAHTAR));
    expect(res.status).toBe(400);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
    expect(mockRevalidatePath).not.toHaveBeenCalled();
  });

  it("boş/whitespace tag'ler elenir", async () => {
    process.env.REVALIDATION_SECRET = ANAHTAR;
    const res = await POST(istek({ tags: ["   "] }, ANAHTAR));
    expect(res.status).toBe(400);
    expect(mockRevalidateTag).not.toHaveBeenCalled();
  });
});

describe("REVALIDATION_SECRET — derleme kablosu", () => {
  const oku = (goreli: string) =>
    readFileSync(resolve(__dirname, "..", "..", goreli), "utf8");

  it("APK/AAB derlemesi anahtarı ZORUNLU tutuyor ve dart-define ile veriyor", () => {
    const kaynak = oku(".github/workflows/android-apk.yml");

    // Zorunlu kılınmış — yoksa derleme düşsün, sessiz bozulma yaşanmasın.
    expect(kaynak).toContain("REVALIDATION_SECRET: ${{ secrets.REVALIDATION_SECRET }}");
    expect(kaynak).toContain("            REVALIDATION_SECRET");
    expect(kaynak).toContain('--dart-define=REVALIDATION_SECRET="$REVALIDATION_SECRET"');

    // APK ve AAB (Play Store) aynı anda derleniyor — ikisi de almalı.
    const adet = (
      kaynak.match(/--dart-define=REVALIDATION_SECRET=/g) || []
    ).length;
    expect(adet).toBe(2);
  });

  it("Flutter web derlemesi (vercel-build.sh) anahtarı dart-define ile veriyor", () => {
    const kaynak = oku("vercel-build.sh");
    expect(kaynak).toContain('--dart-define=REVALIDATION_SECRET="${REVALIDATION_SECRET:-}"');
  });

  it("Flutter tarafı boş anahtarla istek ATMIYOR (boşsa sessizce geçer)", () => {
    const kaynak = oku("lib/services/seo_service.dart");
    expect(kaynak).toContain("String.fromEnvironment('REVALIDATION_SECRET')");
    expect(kaynak).toMatch(/if \(secret\.isEmpty\) \{\s*return;/);
    expect(kaynak).toContain("'x-revalidate-secret': secret");
  });
});
