import { afterEach, describe, expect, it, vi } from "vitest";
import { faturaSonucunuBekle } from "@/lib/faturaOtomatikBekleme";

const ISLEM = "11111111-1111-4111-8111-111111111111";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

afterEach(() => {
  vi.useRealTimers();
});

describe("faturaSonucunuBekle", () => {
  it("bekleyen işi 5 saniyelik fake-clock aralıklarla tamamlanan GET cevabına taşır", async () => {
    vi.useFakeTimers({ now: 0 });
    const beklemeler: number[] = [];
    const bekle = vi.fn(async (ms: number) => {
      beklemeler.push(ms);
      vi.advanceTimersByTime(ms);
    });
    const fetcher = vi.fn(async (url: RequestInfo | URL, init?: RequestInit) => {
      expect(String(url)).toBe(`/api/fatura-islem?slug=dukkan&islemKimligi=${ISLEM}`);
      expect(init?.method).toBeUndefined();
      return jsonResponse({ tamam: true, satirlar: [{ ad: "Ürün" }] });
    });

    const sonuc = await faturaSonucunuBekle(
      { tamam: false, hazirlaniyor: true, islemKimligi: ISLEM },
      { slug: "dukkan", fetcher, bekle },
    );

    expect(sonuc).toEqual({ tamam: true, satirlar: [{ ad: "Ürün" }] });
    expect(beklemeler).toEqual([5_000]);
    expect(fetcher).toHaveBeenCalledTimes(1);
    expect(fetcher.mock.calls.every(([, init]) => init?.method !== "POST")).toBe(true);
  });

  it("tamamlanan ama satırsız cevabı aynen çağırana bırakır", async () => {
    const bekle = vi.fn(async () => undefined);
    const cevap = { tamam: true, satirlar: [] };
    const sonuc = await faturaSonucunuBekle(
      { tamam: false, hazirlaniyor: true, islemKimligi: ISLEM },
      { slug: "dukkan", fetcher: vi.fn(async () => jsonResponse(cevap)), bekle },
    );

    expect(sonuc).toBeTruthy();
    expect(sonuc).toEqual(cevap);
  });

  it("HTTP hata gövdesindeki hata mesajını korur", async () => {
    const fetcher = vi.fn(async () => jsonResponse({ hata: "Bu fatura işlemi bulunamadı." }, 404));

    await expect(
      faturaSonucunuBekle(
        { hazirlaniyor: true, islemKimligi: ISLEM },
        { slug: "dukkan", fetcher, bekle: vi.fn(async () => undefined) },
      ),
    ).rejects.toThrow("Bu fatura işlemi bulunamadı.");
  });

  it("bekleme aralığında abort edilince GET göndermeden durur", async () => {
    vi.useFakeTimers({ now: 0 });
    const controller = new AbortController();
    const fetcher = vi.fn();
    const promise = faturaSonucunuBekle(
      { hazirlaniyor: true, islemKimligi: ISLEM },
      {
        slug: "dukkan",
        signal: controller.signal,
        fetcher,
        bekle: (ms) => new Promise<void>((resolve) => setTimeout(resolve, ms)),
      },
    );

    controller.abort();
    await expect(promise).rejects.toMatchObject({ name: "AbortError" });
    expect(fetcher).not.toHaveBeenCalled();
  });

  it("bekleyen cevabı aynı işlem kimliğini taşımıyorsa başarısız olur", async () => {
    const fetcher = vi.fn(async () => jsonResponse({ tamam: false, hazirlaniyor: true }));

    await expect(
      faturaSonucunuBekle(
        { hazirlaniyor: true, islemKimligi: ISLEM },
        { slug: "dukkan", fetcher, bekle: vi.fn(async () => undefined) },
      ),
    ).rejects.toThrow("işlem kimliği eksik");
    expect(fetcher).toHaveBeenCalledTimes(1);
  });
});
