import { afterEach, describe, expect, it, vi } from "vitest";
import { firmaAlaniniKilitle, satirAramaCevabi, ureticiKaynakAlintisiniDogrula } from "@/lib/faturaGoru";

afterEach(() => {
  vi.unstubAllEnvs();
});

function kaynakCevabi(degisiklik: Record<string, unknown> = {}) {
  return {
    status: "completed",
    usage: { server_tool_use: { web_fetch_requests: 1 } },
    output_text: JSON.stringify({
      eslesti: true,
      urun_adi: "Siyah Pamuk Atlet",
      aciklama: "Üreticinin siyah pamuklu atleti",
      kaynak_sayfa: "https://uretim.example/urun/atlet",
      gorsel_adresi: "https://cdn.example/atlet.jpg",
      kanit: "Markanın resmî ürün kaydında renk ve ürün adı yer alıyor.",
      eslesme_dayanagi: "ad-ve-ozellik",
      site_kodu: "",
      site_barkodu: "",
      site_markasi: "Elit",
      site_rengi: "Siyah",
      site_bedeni: "",
      fotograf_rengi_dogrulandi: true,
      ...degisiklik,
    }),
  };
}

describe("fatura kimlik ve üretici doğrulama kapısı", () => {
  const girdi = { alan: "uretim.example", model: "", barkod: "", ad: "Siyah Pamuk Atlet", marka: "Elit", varyant: "Siyah", beden: "" };

  it("renk yazisi eksik olsa da adi ve fotografi kartta kalir", () => {
    const eksik = kaynakCevabi({ site_rengi: "", fotograf_rengi_dogrulandi: false });
    const sonuc = satirAramaCevabi({ ...girdi, varyant: "" }, eksik);
    expect(sonuc?.ad).toBe("Siyah Pamuk Atlet");
    expect(sonuc?.gorsel).toBe("https://cdn.example/atlet.jpg");
  });

  it("sitede kod yazmiyorsa faturadaki kod satiri dusurmez", () => {
    expect(satirAramaCevabi({ ...girdi, model: "A-123" }, kaynakCevabi())?.gorsel).toBe("https://cdn.example/atlet.jpg");
  });

  it("kod çelişirse kanıtlı sayılmaz", () => {
    const satir = { ...girdi, model: "A-123" };
    expect(satirAramaCevabi(satir, kaynakCevabi({
      eslesme_dayanagi: "kod", site_kodu: "B-999",
    }))).toBeNull();
  });

  it("resmî sayfada kod uyuşuyorsa eşleşme geçebilir", () => {
    const satir = { ...girdi, model: "A-123" };
    expect(satirAramaCevabi(satir, kaynakCevabi({
      eslesme_dayanagi: "kod", site_kodu: "A-123",
    }))?.dayanak).toBe("kod");
  });

  it("kod yoksa aynı ad ile iki kaynak özelliği birlikte aranır", () => {
    expect(satirAramaCevabi(girdi, kaynakCevabi())?.dayanak).toBe("ad");
  });

  it("faturada yazan site kilitlenir", async () => {
    vi.stubEnv("OPENROUTER_API_KEY", "");
    expect(await firmaAlaniniKilitle({
      belgedeYazan: "bayi.example", esnafIpucu: "toptanci.example",
      tedarikciAdi: "Üretici", vergiNo: "", adres: "",
    })).toBe("bayi.example");
  });
  it("resmi kaynagin gercek metni modelin alintisini destekler", async () => {
    const kaynak = "https://uretim.example/hakkimizda";
    const kanit = "Üretim tesisimizde markamızı kendimiz üretiyoruz.";
    const fetcher = async () => new Response(
      `<html><body><p>${kanit}</p></body></html>`,
      { status: 200, headers: { "content-type": "text/html" } },
    );
    const resolveHost = async () => ["8.8.8.8"];
    expect(await ureticiKaynakAlintisiniDogrula("uretim.example", kaynak, kanit,
      { fetcher, resolveHost })).toBe(true);
    expect(await ureticiKaynakAlintisiniDogrula("uretim.example", kaynak,
      "Bu üretici başka bir fabrikanın sahibidir.", { fetcher, resolveHost })).toBe(false);
  });

  it("script icindeki reklam metnini uretim kaniti saymaz", async () => {
    const kaynak = "https://uretim.example/hakkimizda";
    const kanit = "Bu markanin uretimini kendimiz yapiyoruz.";
    const fetcher = async () => new Response(
      `<html><script>var fake = "${kanit}"</script><body>Sadece toptanciyiz.</body></html>`,
    );
    expect(await ureticiKaynakAlintisiniDogrula("uretim.example", kaynak, kanit, {
      fetcher, resolveHost: async () => ["8.8.8.8"],
    })).toBe(false);
  });

});
