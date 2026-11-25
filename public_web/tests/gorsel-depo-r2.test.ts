import { createHash, createHmac } from "node:crypto";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";

const supabaseMocks = vi.hoisted(() => ({
  getSupabaseAdmin: vi.fn(),
}));

vi.mock("@/lib/supabaseAdmin", () => ({
  getSupabaseAdmin: supabaseMocks.getSupabaseAdmin,
}));

import {
  gorselDepoyaYukle,
  imzaliR2Istek,
  r2Yapilandirmasi,
  vitrinR2GorselleriniSil,
  vitrinR2OnekSil,
  yonetilenR2Originleri,
} from "@/lib/gorselDepo";
import { vitrinGorsellerinisil } from "@/lib/depoTemizle";
import {
  validateProductImageUrls,
  yonetilenUrunGorseliMi,
} from "@/lib/productImagePolicy";

const ORNEK_R2_ENV = {
  R2_ACCOUNT_ID: "acct123456",
  R2_ACCESS_KEY_ID: "AKIAEXAMPLEKEY",
  R2_SECRET_ACCESS_KEY: "secret-example-key-value",
  R2_BUCKET_NAME: "vixrex-images",
  R2_PUBLIC_URL: "https://cdn.vixrex.com",
  NEXT_PUBLIC_R2_PUBLIC_URL: "https://cdn.vixrex.com",
};

function r2EnvKur(ekstra: Partial<Record<keyof typeof ORNEK_R2_ENV, string>> = {}) {
  const birlesik = { ...ORNEK_R2_ENV, ...ekstra };
  for (const [anahtar, deger] of Object.entries(birlesik)) {
    vi.stubEnv(anahtar, deger);
  }
}

function r2EnvTemizle() {
  for (const anahtar of Object.keys(ORNEK_R2_ENV)) {
    vi.stubEnv(anahtar, "");
  }
}

const gercekFetch = globalThis.fetch;

afterEach(() => {
  vi.unstubAllEnvs();
  vi.restoreAllMocks();
  supabaseMocks.getSupabaseAdmin.mockReset();
  globalThis.fetch = gercekFetch;
});

describe("r2Yapilandirmasi ve fail-closed davranışı", () => {
  it("tüm R2 env değişkenleri boşsa null döner", () => {
    r2EnvTemizle();
    expect(r2Yapilandirmasi()).toBeNull();
  });

  it("kısmi env tanımlıysa fail-closed Error fırlatır", () => {
    r2EnvTemizle();
    vi.stubEnv("R2_ACCOUNT_ID", "acct123456");
    vi.stubEnv("R2_BUCKET_NAME", "vixrex-images");
    expect(() => r2Yapilandirmasi()).toThrow(/R2 yapılandırması eksik/);
  });

  it("R2_PUBLIC_URL http:// ise fail-closed Error fırlatır", () => {
    r2EnvKur({ R2_PUBLIC_URL: "http://cdn.vixrex.com", NEXT_PUBLIC_R2_PUBLIC_URL: "" });
    expect(() => r2Yapilandirmasi()).toThrow(/https:\/\//);
  });

  it("R2_PUBLIC_URL geçersiz URL ise fail-closed Error fırlatır", () => {
    r2EnvKur({ R2_PUBLIC_URL: "not-a-url", NEXT_PUBLIC_R2_PUBLIC_URL: "" });
    expect(() => r2Yapilandirmasi()).toThrow(/geçerli bir adres değil/);
  });

  it("NEXT_PUBLIC_R2_PUBLIC_URL origin uyuşmuyorsa fail-closed Error fırlatır", () => {
    r2EnvKur({
      R2_PUBLIC_URL: "https://cdn.vixrex.com",
      NEXT_PUBLIC_R2_PUBLIC_URL: "https://baska.vixrex.com",
    });
    expect(() => r2Yapilandirmasi()).toThrow(/origin uyuşmuyor/);
  });

  it("yonetilenR2Originleri yalnız geçerli https:// origin'lerini döndürür", () => {
    r2EnvKur({
      R2_PUBLIC_URL: "https://cdn.vixrex.com/alt-yol",
      NEXT_PUBLIC_R2_PUBLIC_URL: "http://guvensiz.example.com",
    });
    const originler = yonetilenR2Originleri();
    expect(originler.has("https://cdn.vixrex.com")).toBe(true);
    expect(originler.has("http://guvensiz.example.com")).toBe(false);
  });
});

describe("R2 SigV4 imzalama ve PutObject", () => {
  it("AWS4-HMAC-SHA256 imzası sabit zaman damgasıyla deterministik ve doğru üretilir", () => {
    r2EnvKur();
    const r2 = r2Yapilandirmasi();
    expect(r2).not.toBeNull();
    const bayt = new Uint8Array([1, 2, 3, 4]);
    const tarih = new Date("2026-11-25T10:00:00.000Z");

    const imzali = imzaliR2Istek({
      r2: r2!,
      method: "PUT",
      canonicalUri: "/vixrex-images/magaza-1/products/test.webp",
      headers: {
        "content-type": "image/webp",
        "cache-control": "public, max-age=31536000, immutable",
      },
      body: bayt,
      tarih,
    });

    expect(imzali.url).toBe(
      "https://acct123456.r2.cloudflarestorage.com/vixrex-images/magaza-1/products/test.webp",
    );
    expect(imzali.headers["x-amz-date"]).toBe("20261125T100000Z");
    expect(imzali.headers["x-amz-content-sha256"]).toBe(
      createHash("sha256").update(bayt).digest("hex"),
    );

    const auth = imzali.headers.authorization;
    expect(auth).toMatch(
      /^AWS4-HMAC-SHA256 Credential=AKIAEXAMPLEKEY\/20261125\/auto\/s3\/aws4_request, SignedHeaders=cache-control;content-type;host;x-amz-content-sha256;x-amz-date, Signature=[0-9a-f]{64}$/,
    );

    const kDate = createHmac("sha256", "AWS4secret-example-key-value").update("20261125").digest();
    const kRegion = createHmac("sha256", kDate).update("auto").digest();
    const kService = createHmac("sha256", kRegion).update("s3").digest();
    const kSigning = createHmac("sha256", kService).update("aws4_request").digest();
    const beklenenCanonical = [
      "PUT",
      "/vixrex-images/magaza-1/products/test.webp",
      "",
      "cache-control:public, max-age=31536000, immutable\n" +
        "content-type:image/webp\n" +
        "host:acct123456.r2.cloudflarestorage.com\n" +
        `x-amz-content-sha256:${imzali.headers["x-amz-content-sha256"]}\n` +
        "x-amz-date:20261125T100000Z\n",
      "cache-control;content-type;host;x-amz-content-sha256;x-amz-date",
      imzali.headers["x-amz-content-sha256"],
    ].join("\n");
    const beklenenStringToSign = [
      "AWS4-HMAC-SHA256",
      "20261125T100000Z",
      "20261125/auto/s3/aws4_request",
      createHash("sha256").update(beklenenCanonical).digest("hex"),
    ].join("\n");
    const beklenenImza = createHmac("sha256", kSigning).update(beklenenStringToSign).digest("hex");
    expect(auth.endsWith(`Signature=${beklenenImza}`)).toBe(true);
  });

  it("R2 aktifken PUT atar, Supabase admin çağırmaz ve public URL döner", async () => {
    r2EnvKur({ R2_PUBLIC_URL: "https://cdn.vixrex.com/" });
    const adminUpload = vi.fn();
    const fetcher = vi.fn(async () => new Response(null, { status: 200 }));

    const url = await gorselDepoyaYukle({
      admin: {
        storage: {
          from: () => ({
            upload: adminUpload,
            getPublicUrl: () => ({ data: { publicUrl: "https://supa.example/x" } }),
          }),
        },
      },
      yol: "magaza-1/products/p1/foto.webp",
      bayt: new Uint8Array([10, 20, 30]),
      contentType: "image/webp",
      cacheControl: "31536000",
      upsert: false,
      fetcher: fetcher as never,
    });

    expect(url).toBe("https://cdn.vixrex.com/magaza-1/products/p1/foto.webp");
    expect(adminUpload).not.toHaveBeenCalled();
    expect(fetcher).toHaveBeenCalledTimes(1);
    const [istekUrl, istekInit] = fetcher.mock.calls[0] as unknown as [string, RequestInit];
    expect(istekUrl).toBe(
      "https://acct123456.r2.cloudflarestorage.com/vixrex-images/magaza-1/products/p1/foto.webp",
    );
    expect(istekInit.method).toBe("PUT");
    const basliklar = istekInit.headers as Record<string, string>;
    expect(basliklar["content-type"]).toBe("image/webp");
    expect(basliklar["cache-control"]).toBe("public, max-age=31536000, immutable");
    expect(basliklar.authorization).toContain("AWS4-HMAC-SHA256");
  });

  it("boşluk, Türkçe karakter, # ve ? içeren yollarda PUT yolu ile dönen URL birebir kodlanmış eşleşir", async () => {
    r2EnvKur({ R2_PUBLIC_URL: "https://cdn.vixrex.com" });
    const fetcher = vi.fn(async () => new Response(null, { status: 200 }));
    const hamYol = "magaza-1/products/ürün #1?v=2.webp";

    const donenUrl = await gorselDepoyaYukle({
      yol: hamYol,
      bayt: new Uint8Array([1, 2, 3]),
      contentType: "image/webp",
      cacheControl: "31536000",
      fetcher: fetcher as never,
    });

    const [putUrl] = fetcher.mock.calls[0] as unknown as [string];
    const kodlanmisYol = "magaza-1/products/%C3%BCr%C3%BCn%20%231%3Fv%3D2.webp";
    expect(putUrl).toBe(
      `https://acct123456.r2.cloudflarestorage.com/vixrex-images/${kodlanmisYol}`,
    );
    expect(donenUrl).toBe(`https://cdn.vixrex.com/${kodlanmisYol}`);
  });

  it("SigV4 canonical query string sıralaması URI-encode sonrası değerlere göre yapılır", () => {
    r2EnvKur();
    const r2 = r2Yapilandirmasi();
    const imzali = imzaliR2Istek({
      r2: r2!,
      method: "GET",
      canonicalUri: "/vixrex-images",
      queryParams: [
        ["a-", "1"],
        ["a:", "2"],
      ],
      tarih: new Date("2026-11-25T10:00:00.000Z"),
    });

    expect(new URL(imzali.url).search).toBe("?a%3A=2&a-=1");
  });

  it("R2 PUT hata yanıtında Error fırlatır ve gizli anahtar sızdırmaz", async () => {
    r2EnvKur();
    const fetcher = vi.fn(async () => new Response("AccessDenied", { status: 403 }));

    await expect(
      gorselDepoyaYukle({
        yol: "magaza-1/products/p1/foto.webp",
        bayt: new Uint8Array([1, 2, 3]),
        contentType: "image/webp",
        cacheControl: "31536000",
        fetcher: fetcher as never,
      }),
    ).rejects.toThrow("R2 yukleme hatasi: HTTP 403");
  });

  it("R2 env boşken Supabase Storage fallback çalışır", async () => {
    r2EnvTemizle();
    const upload = vi.fn(async () => ({ error: null }));
    const getPublicUrl = vi.fn((yol: string) => ({
      data: { publicUrl: `https://ornek.supabase.co/storage/v1/object/public/shelf-images/${yol}` },
    }));
    const fetcher = vi.fn();

    const url = await gorselDepoyaYukle({
      admin: {
        storage: {
          from: () => ({ upload, getPublicUrl }),
        },
      },
      yol: "magaza-1/owner/logo/a.webp",
      bayt: new Uint8Array([1, 2, 3]),
      contentType: "image/webp",
      cacheControl: "31536000",
      upsert: false,
      fetcher: fetcher as never,
    });

    expect(fetcher).not.toHaveBeenCalled();
    expect(upload).toHaveBeenCalledWith("magaza-1/owner/logo/a.webp", expect.any(Uint8Array), {
      contentType: "image/webp",
      cacheControl: "31536000",
      upsert: false,
    });
    expect(url).toBe(
      "https://ornek.supabase.co/storage/v1/object/public/shelf-images/magaza-1/owner/logo/a.webp",
    );
  });

  it("Supabase fallback upload hatasında Error fırlatır", async () => {
    r2EnvTemizle();
    await expect(
      gorselDepoyaYukle({
        admin: {
          storage: {
            from: () => ({
              upload: async () => ({ error: { message: "bucket full" } }),
              getPublicUrl: () => ({ data: { publicUrl: "" } }),
            }),
          },
        },
        yol: "magaza-1/products/x.webp",
        bayt: new Uint8Array([1]),
        contentType: "image/webp",
        cacheControl: "31536000",
      }),
    ).rejects.toThrow("bucket full");
  });
});

describe("R2 ListObjectsV2 ve DeleteObjects", () => {
  it("sayfalama + 1000'erli batch ile nesneleri siler", async () => {
    r2EnvKur();
    const ilkSayfaAnahtarlar = Array.from(
      { length: 1000 },
      (_, i) => `<Contents><Key>magaza-1/products/f${i}.webp</Key></Contents>`,
    ).join("");
    const ikinciSayfaAnahtarlar = Array.from(
      { length: 5 },
      (_, i) => `<Contents><Key>magaza-1/owner/g${i}.webp</Key></Contents>`,
    ).join("");

    const silinenAnahtarlar: string[] = [];
    const fetcher = vi.fn(async (istekUrl: string, init?: RequestInit) => {
      if (init?.method === "GET") {
        const parsed = new URL(istekUrl);
        expect(parsed.searchParams.get("list-type")).toBe("2");
        expect(parsed.searchParams.get("prefix")).toBe("magaza-1/");
        const token = parsed.searchParams.get("continuation-token");
        if (!token) {
          return new Response(
            `<ListBucketResult><IsTruncated>true</IsTruncated><NextContinuationToken>sayfa-2</NextContinuationToken>${ilkSayfaAnahtarlar}</ListBucketResult>`,
            { status: 200 },
          );
        }
        expect(token).toBe("sayfa-2");
        return new Response(
          `<ListBucketResult><IsTruncated>false</IsTruncated>${ikinciSayfaAnahtarlar}</ListBucketResult>`,
          { status: 200 },
        );
      }

      expect(init?.method).toBe("POST");
      const parsed = new URL(istekUrl);
      expect(parsed.searchParams.has("delete")).toBe(true);
      const basliklar = init?.headers as Record<string, string>;
      const govde = String(init?.body ?? "");
      expect(basliklar["content-md5"]).toBe(
        createHash("md5").update(govde, "utf8").digest("base64"),
      );
      const eslesmeler = [...govde.matchAll(/<Key>(.*?)<\/Key>/g)].map((m) => m[1]);
      silinenAnahtarlar.push(...eslesmeler);
      const deletedXml = eslesmeler.map((k) => `<Deleted><Key>${k}</Key></Deleted>`).join("");
      return new Response(`<DeleteResult>${deletedXml}</DeleteResult>`, { status: 200 });
    });

    const toplam = await vitrinR2GorselleriniSil("magaza-1", fetcher as never);
    expect(toplam).toBe(1005);
    expect(silinenAnahtarlar).toHaveLength(1005);
    expect(fetcher).toHaveBeenCalledTimes(4);
  });

  it("boş veya yalnız geçersiz karakterli slug için listeleme yapmaz ve 0 döner", async () => {
    r2EnvKur();
    const fetcher = vi.fn();
    expect(await vitrinR2GorselleriniSil("", fetcher as never)).toBe(0);
    expect(await vitrinR2GorselleriniSil("../..", fetcher as never)).toBe(0);
    expect(await vitrinR2GorselleriniSil("///", fetcher as never)).toBe(0);
    expect(fetcher).not.toHaveBeenCalled();
  });

  it("R2 ağ/HTTP hatasında fırlatmaz, console.error basıp 0 döner", async () => {
    r2EnvKur();
    const errSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    const fetcher = vi.fn(async () => new Response("error", { status: 500 }));
    const sonuc = await vitrinR2GorselleriniSil("magaza-1", fetcher as never);
    expect(sonuc).toBe(0);
    expect(errSpy).toHaveBeenCalled();
  });

  it("vitrinR2OnekSil güvenli önek ile Instagram klasörünü siler ve tehlikeli önekleri reddeder", async () => {
    r2EnvKur();
    const tehlikeliFetcher = vi.fn();
    for (const kotu of [
      "",
      "   ",
      "/",
      "../gizli",
      "magaza-1/../baska/",
      "magaza-1/%2e%2e/instagram",
      "magaza-1/instagram?x=1",
    ]) {
      expect(await vitrinR2OnekSil(kotu, tehlikeliFetcher as never)).toBe(0);
    }
    expect(tehlikeliFetcher).not.toHaveBeenCalled();

    const fetcher = vi.fn(async (istekUrl: string, init?: RequestInit) => {
      if (init?.method === "GET") {
        expect(new URL(istekUrl).searchParams.get("prefix")).toBe("magaza-1/instagram/");
        return new Response(
          "<ListBucketResult><IsTruncated>false</IsTruncated><Contents><Key>magaza-1/instagram/m1.webp</Key></Contents></ListBucketResult>",
          { status: 200 },
        );
      }
      return new Response(
        "<DeleteResult><Deleted><Key>magaza-1/instagram/m1.webp</Key></Deleted></DeleteResult>",
        { status: 200 },
      );
    });
    expect(await vitrinR2OnekSil("magaza-1/instagram/", fetcher as never)).toBe(1);
    expect(fetcher).toHaveBeenCalledTimes(2);
  });
});

describe("productImagePolicy eski Supabase + yeni R2 + negatif güvenlik testleri", () => {
  it("eski Supabase Storage ürün URL'lerini kabul eder", () => {
    r2EnvTemizle();
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://ornek.supabase.co");
    const url =
      "https://ornek.supabase.co/storage/v1/object/public/shelf-images/magaza-1/products/urun.webp";
    expect(yonetilenUrunGorseliMi(url)).toBe(true);
    expect(validateProductImageUrls([url, url.replace("urun", "u2"), url.replace("urun", "u3")]).ok).toBe(
      true,
    );
  });

  it("yetkili R2 origin'indeki /products/ URL'lerini kabul eder", () => {
    r2EnvKur({
      R2_PUBLIC_URL: "https://cdn.vixrex.com",
      NEXT_PUBLIC_R2_PUBLIC_URL: "https://cdn.vixrex.com",
    });
    const url = "https://cdn.vixrex.com/magaza-1/products/fatura/abc123.webp";
    expect(yonetilenUrunGorseliMi(url)).toBe(true);
  });

  it("yetkisiz R2 hostunu ve /products/ dışındaki R2 yollarını reddeder", () => {
    r2EnvKur({
      R2_PUBLIC_URL: "https://cdn.vixrex.com",
      NEXT_PUBLIC_R2_PUBLIC_URL: "https://cdn.vixrex.com",
    });
    expect(yonetilenUrunGorseliMi("https://saldirgan.r2.dev/magaza-1/products/a.webp")).toBe(false);
    expect(yonetilenUrunGorseliMi("https://pub-baska.r2.dev/magaza-1/products/a.webp")).toBe(false);
    expect(yonetilenUrunGorseliMi("https://cdn.vixrex.com/magaza-1/owner/logo/a.webp")).toBe(false);
    expect(yonetilenUrunGorseliMi("https://cdn.vixrex.com/magaza-1/products/")).toBe(false);
  });

  it("path traversal (.. ve %2e%2e) içeren URL'leri reddeder", () => {
    r2EnvKur();
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://ornek.supabase.co");
    const kotuUrller = [
      "https://cdn.vixrex.com/magaza-1/products/../secret.webp",
      "https://cdn.vixrex.com/magaza-1/products/%2e%2e/secret.webp",
      "https://cdn.vixrex.com/magaza-1/products/%2E%2E/secret.webp",
      "https://ornek.supabase.co/storage/v1/object/public/shelf-images/magaza-1/products/%2e%2e/a.webp",
      "https://ornek.supabase.co/storage/v1/object/public/shelf-images/magaza-1/products/../a.webp",
    ];
    for (const url of kotuUrller) {
      expect(yonetilenUrunGorseliMi(url)).toBe(false);
    }
  });
});

describe("depoTemizle çift depo ve hata izolasyonu", () => {
  it("hem Supabase hem R2 silinen toplam dosya sayısını döndürür", async () => {
    r2EnvKur();
    supabaseMocks.getSupabaseAdmin.mockReturnValue({
      storage: {
        from: () => ({
          list: async () => ({
            data: [
              { id: "1", name: "a.webp" },
              { id: "2", name: "b.webp" },
            ],
            error: null,
          }),
          remove: async () => ({ error: null }),
        }),
      },
    });
    globalThis.fetch = vi.fn(async (_url: string, init?: RequestInit) => {
      if (init?.method === "GET") {
        return new Response(
          "<ListBucketResult><IsTruncated>false</IsTruncated><Contents><Key>magaza-1/products/c.webp</Key></Contents></ListBucketResult>",
          { status: 200 },
        );
      }
      return new Response("<DeleteResult><Deleted><Key>magaza-1/products/c.webp</Key></Deleted></DeleteResult>", {
        status: 200,
      });
    }) as never;

    const toplam = await vitrinGorsellerinisil("magaza-1");
    expect(toplam).toBe(3);
  });

  it("Supabase hata verirse R2 silmeyi engellemez", async () => {
    r2EnvKur();
    vi.spyOn(console, "error").mockImplementation(() => {});
    supabaseMocks.getSupabaseAdmin.mockImplementation(() => {
      throw new Error("supabase down");
    });
    globalThis.fetch = vi.fn(async (_url: string, init?: RequestInit) => {
      if (init?.method === "GET") {
        return new Response(
          "<ListBucketResult><IsTruncated>false</IsTruncated><Contents><Key>magaza-1/products/c.webp</Key></Contents></ListBucketResult>",
          { status: 200 },
        );
      }
      return new Response("<DeleteResult><Deleted><Key>magaza-1/products/c.webp</Key></Deleted></DeleteResult>", {
        status: 200,
      });
    }) as never;

    const toplam = await vitrinGorsellerinisil("magaza-1");
    expect(toplam).toBe(1);
  });

  it("boş veya traversal slug (../..) için 0 döner ve hiçbir depoyu çağırmaz", async () => {
    r2EnvKur();
    const fetchSpy = vi.fn();
    globalThis.fetch = fetchSpy as never;
    const toplam = await vitrinGorsellerinisil("../..");
    expect(toplam).toBe(0);
    expect(supabaseMocks.getSupabaseAdmin).not.toHaveBeenCalled();
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});

describe("mimari koruma sözleşmeleri", () => {
  it("gorselDepo.ts sharp veya gorselSikistir import etmez", () => {
    const kaynak = readFileSync(resolve(__dirname, "../src/lib/gorselDepo.ts"), "utf8");
    expect(kaynak).not.toMatch(/["']sharp["']/);
    expect(kaynak).not.toMatch(/gorselSikistir/);
  });

  it("next.config.ts CSP img-src r2.dev içerir ve unoptimized ile SHARP_ROUTES korunur", () => {
    const kaynak = readFileSync(resolve(__dirname, "../next.config.ts"), "utf8");
    expect(kaynak).toContain("https://*.r2.dev");
    expect(kaynak).toContain("unoptimized: true");
    expect(kaynak).toContain("const SHARP_ROUTES = [");
  });

  it("instagram/disconnect ve meta/data-deletion rotaları R2 Instagram klasörünü temizler", () => {
    const disconnect = readFileSync(
      resolve(__dirname, "../src/app/api/instagram/disconnect/route.ts"),
      "utf8",
    );
    const dataDeletion = readFileSync(
      resolve(__dirname, "../src/app/api/meta/data-deletion/route.ts"),
      "utf8",
    );
    expect(disconnect).toContain("vitrinR2OnekSil");
    expect(disconnect).toContain("/instagram/");
    expect(dataDeletion).toContain("vitrinR2OnekSil");
    expect(dataDeletion).toContain("/instagram/");
  });
});
