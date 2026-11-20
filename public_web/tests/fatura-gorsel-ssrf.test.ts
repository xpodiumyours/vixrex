import { afterEach, describe, expect, it, vi } from "vitest";

const dnsMocks = vi.hoisted(() => ({
  lookup: vi.fn(),
}));

vi.mock("node:dns/promises", () => ({
  lookup: dnsMocks.lookup,
}));

import {
  gorselsizSatirlariTamamla,
  hostGuvenliMi,
  kaynakGorseliniDogrula,
  sayfaGorselAlanAdlari,
} from "@/lib/faturaGorsel";
import type { GoruSatiri } from "@/lib/faturaGoru";

const gercekFetch = globalThis.fetch;

afterEach(() => {
  globalThis.fetch = gercekFetch;
  dnsMocks.lookup.mockReset();
});

function akisYaniti(parcalar: Uint8Array[], contentLength?: string): Response {
  const govde = new ReadableStream<Uint8Array>({
    start(controller) {
      for (const parca of parcalar) {
        controller.enqueue(parca);
      }
      controller.close();
    },
  });
  const headers = new Headers({ "content-type": "text/html; charset=utf-8" });
  if (contentLength !== undefined) {
    headers.set("content-length", contentLength);
  }
  return new Response(govde, { status: 200, headers });
}

describe("faturaGorsel SSRF ve chunked HTML koruması", () => {
  it("cloud metadata, 0.0.0.0, CGNAT ve tüm yerel/özel/IPv4-mapped IPv6 adreslerini engeller", async () => {
    const yasakliHostlar = [
      "169.254.169.254",
      "0.0.0.0",
      "0.1.2.3",
      "100.64.0.1",
      "100.127.255.254",
      "[::1]",
      "::1",
      "[::]",
      "[fc00::1]",
      "[fd12:3456:789a::1]",
      "[fe80::1]",
      "[::ffff:127.0.0.1]",
      "[::ffff:169.254.169.254]",
      "[::ffff:7f00:1]",
    ];

    for (const host of yasakliHostlar) {
      expect(hostGuvenliMi(host)).toBe(false);
    }

    expect(hostGuvenliMi("93.184.216.34")).toBe(true);
    expect(hostGuvenliMi("100.63.255.254")).toBe(true);
    expect(hostGuvenliMi("100.128.0.1")).toBe(true);
    expect(hostGuvenliMi("cdn.marka.com.tr")).toBe(true);

    const fetcher = vi.fn();
    for (const hedef of [
      "https://169.254.169.254/latest/meta-data/",
      "https://0.0.0.0/urun.jpg",
      "https://100.64.0.1/urun.jpg",
      "https://[::1]/urun.jpg",
      "https://[::]/urun.jpg",
      "https://[fc00::1]/urun.jpg",
      "https://[fe80::1]/urun.jpg",
      "https://[::ffff:127.0.0.1]/urun.jpg",
      "https://[::ffff:169.254.169.254]/urun.jpg",
    ]) {
      const sonuc = await kaynakGorseliniDogrula(hedef, { fetcher: fetcher as never });
      expect(sonuc).toEqual({ tamam: false, sebep: "erisilemedi" });
      expect(await sayfaGorselAlanAdlari(hedef, fetcher as never)).toEqual([]);
    }
    expect(fetcher).not.toHaveBeenCalled();
  });

  it("DNS rebinding: enjekte edilen resolveHost özel IP döndürürse fetch çağrılmadan reddedilir", async () => {
    const fetcher = vi.fn();
    const resolveHost = vi.fn(async () => ["93.184.216.34", "169.254.169.254"]);

    const sonuc = await kaynakGorseliniDogrula("https://saldirgan.example/urun.jpg", {
      fetcher: fetcher as never,
      resolveHost,
    });
    expect(sonuc).toEqual({ tamam: false, sebep: "erisilemedi" });
    expect(resolveHost).toHaveBeenCalledWith("saldirgan.example");
    expect(fetcher).not.toHaveBeenCalled();

    const ipv6Rebind = await kaynakGorseliniDogrula("https://saldirgan6.example/urun.jpg", {
      fetcher: fetcher as never,
      resolveHost: async () => ["::ffff:127.0.0.1"],
    });
    expect(ipv6Rebind).toEqual({ tamam: false, sebep: "erisilemedi" });

    const hataRebind = await kaynakGorseliniDogrula("https://bozuk-dns.example/urun.jpg", {
      fetcher: fetcher as never,
      resolveHost: async () => {
        throw new Error("ENOTFOUND");
      },
    });
    expect(hataRebind).toEqual({ tamam: false, sebep: "erisilemedi" });
    expect(fetcher).not.toHaveBeenCalled();
  });

  it("302 yönlendirme hedefi özel IP'ye çözülürse yönlendirme zincirinde engellenir", async () => {
    const fetcher = vi.fn(async () =>
      new Response(null, {
        status: 302,
        headers: { location: "https://ic-ag.example/gizli.jpg" },
      }),
    );
    const resolveHost = vi.fn(async (host: string) =>
      host === "dis-site.example" ? ["93.184.216.34"] : ["10.0.0.5"],
    );

    const sonuc = await kaynakGorseliniDogrula("https://dis-site.example/urun.jpg", {
      fetcher: fetcher as never,
      resolveHost,
    });
    expect(sonuc).toEqual({ tamam: false, sebep: "erisilemedi" });
    expect(fetcher).toHaveBeenCalledTimes(1);
    expect(resolveHost).toHaveBeenCalledWith("dis-site.example");
    expect(resolveHost).toHaveBeenCalledWith("ic-ag.example");
  });

  it("varsayılan resolveHost node:dns/promises lookup(all:true) ile özel IP çözen hostu engeller", async () => {
    dnsMocks.lookup.mockResolvedValue([{ address: "169.254.169.254", family: 4 }]);
    let fetchCagrildi = false;
    globalThis.fetch = (async () => {
      fetchCagrildi = true;
      return new Response("ok", { status: 200 });
    }) as typeof fetch;

    const sonuc = await kaynakGorseliniDogrula("https://rebind-default.example/urun.jpg");
    expect(sonuc).toEqual({ tamam: false, sebep: "erisilemedi" });
    expect(dnsMocks.lookup).toHaveBeenCalledWith("rebind-default.example", { all: true });
    expect(fetchCagrildi).toBe(false);
  });

  it("Content-Length başlığı olmadan 3 MB üstü chunked HTML akışını keser ve og:image ayıklamaz", async () => {
    const bas = new TextEncoder().encode(
      '<html><head><meta property="og:image" content="https://cdn.example/urun.jpg"/></head><body>',
    );
    const birMb = new Uint8Array(1024 * 1024).fill(65);
    const fetcher = vi.fn(async () => akisYaniti([bas, birMb, birMb, birMb]));

    const alanlar = await sayfaGorselAlanAdlari("https://uretici.example/urun", fetcher as never);
    expect(alanlar).toEqual(["uretici.example"]);

    const satirlar: GoruSatiri[] = [
      {
        hamSatir: "Test",
        model: "M-1",
        ad: "Test Ürün",
        barkod: "",
        varyant: "",
        beden: "",
        marka: "Marka",
        adet: 1,
        birim: "adet",
        birimFiyat: 100,
        tutar: 100,
        okumaGuveni: 1,
        siteSayfa: "https://uretici.example/urun",
        dogrulamaDurumu: "Doğrulandı",
      },
    ];
    const tamamlanan = await gorselsizSatirlariTamamla({
      satirlar,
      bagimliliklar: { fetcher: fetcher as never },
    });
    expect(tamamlanan[0].siteGorsel).toBeUndefined();
    expect(tamamlanan[0].siteGorseller).toBeUndefined();
  });

  it("Content-Length olmadan 3 MB altı chunked HTML akışından og:image ayıklar", async () => {
    const parca1 = new TextEncoder().encode('<html><head><meta property="og:image" ');
    const parca2 = new TextEncoder().encode('content="https://cdn.myikas.com/urun.webp"/></head></html>');
    const fetcher = vi.fn(async () => akisYaniti([parca1, parca2]));

    const alanlar = await sayfaGorselAlanAdlari("https://uretici.example/urun", fetcher as never);
    expect(alanlar.sort()).toEqual(["cdn.myikas.com", "uretici.example"]);
  });
});
