import { describe, expect, it } from "vitest";
import { satirAramaCevabi } from "@/lib/faturaGoru";

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

describe("Luna ürün araştırma kararının korunması", () => {
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

  it("Luna eşleştirme kararını kod çelişkisinde ikinci kez değiştirmeyiz", () => {
    const satir = { ...girdi, model: "A-123" };
    const kayit = { eslesme_dayanagi: "kod", site_kodu: "B-999" };
    expect(satirAramaCevabi(satir, kaynakCevabi(kayit))?.ad).toBe("Siyah Pamuk Atlet");
    expect(satirAramaCevabi(satir, kaynakCevabi({ ...kayit, eslesti: false }))).toBeNull();
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


});
