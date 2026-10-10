import { describe, expect, it } from "vitest";
import { otomatikTaslakAdayi } from "@/lib/faturaTaslakAdayi";

describe("C7 — her gerçek fatura kalemi, eşleşmeden bağımsız gizli taslak adayıdır", () => {
  it("resmî kaynak yoksa da faturadaki adıyla gizli taslakta korunur", () => {
    expect(otomatikTaslakAdayi({ ad: "Sadece faturada geçen isim", sonuc: "iz-yok", katalog: null })).toBe(true);
  });
  it("çelişkili ürünün satırını kaybetmez; kimliği onayladığı anlamına gelmez", () => {
    expect(otomatikTaslakAdayi({ ad: "Barkod çelişkili ürün", sonuc: "celiski" })).toBe(true);
  });
  it("fotoğraf eksik olsa da resmî kod adayı saklanabilir", () => {
    expect(otomatikTaslakAdayi({ ad: "Ürün", model: "A12", sonuc: "eksik",
      katalog: { resmiAd: "Üretici ürün", kaynak: "https://uretici.example/a12", dayanak: "kod" } })).toBe(true);
  });
  it("adı hiç yoksa gerçek fatura model veya barkod metnini kullanır, değer uydurmaz", () => {
    expect(otomatikTaslakAdayi({ model: "STOK-55" })).toBe(true);
    expect(otomatikTaslakAdayi({ barkod: "8681234567890" })).toBe(true);
    expect(otomatikTaslakAdayi({ ad: " ", model: "", barkod: "", katalog: null })).toBe(false);
  });
  it("17 farklı fatura satırının tamamı kaydedilebilir", () => {
    const rows = Array.from({length:17}, (_, i)=>({ad: `Fatura ürün ${i+1}`, sonuc:i%2?"iz-yok":"eksik"}));
    expect(rows.filter(otomatikTaslakAdayi)).toHaveLength(17);
  });
});
