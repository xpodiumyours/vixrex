import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const indeks = readFileSync(
  resolve(__dirname, "../../docs/research/uyum-sozlesmesi/README.md"),
  "utf-8",
);

describe("Vixrex Uyum Sözleşmesi indeksi", () => {
  it("tam olarak 17 ana matrisi numarası ve adıyla taşır", () => {
    const beklenen = [
      "01 | İşlev",
      "02 | Ekran ve Menü",
      "03 | UI Görünüm",
      "04 | UX Akış",
      "05 | Responsive",
      "06 | Durum",
      "07 | 46 Alan",
      "08 | Tek Veri / Senkronizasyon",
      "09 | Doğrulama ve İş Kuralı",
      "10 | Bağlantı / Servis",
      "11 | Yetki ve Güvenlik",
      "12 | Hata / Yükleniyor / Boş Durum",
      "13 | Görsel ve Dosya",
      "14 | Erişilebilirlik",
      "15 | SEO ve Public Vitrin",
      "16 | Performans",
      "17 | Test ve Yayına Alma",
    ];

    for (const satir of beklenen) {
      expect(indeks).toContain(`| ${satir} |`);
    }

    const matrisSatirlari = indeks.match(/^\| (?:0[1-9]|1[0-7]) \|/gm) ?? [];
    expect(matrisSatirlari).toHaveLength(17);
  });

  it("dokümanı PASS kaynağı değil indeks olarak tanımlar", () => {
    expect(indeks).toContain("Bu dosya **matrisin kendisi değildir**");
    expect(indeks).toContain("çalıştırılabilir doğrulamalardır");
    expect(indeks).toContain("yalnız doküman açıklaması PASS kanıtı değildir");
  });

  it("eksik kanıtı fail-closed BLOCK olarak tanımlar", () => {
    expect(indeks).toContain("çalıştırılabilir kanıt yoksa `BLOCK` olmalıdır");
    expect(indeks).toContain("GÜÇLÜ");
    expect(indeks).toContain("KISMİ");
    expect(indeks).toContain("EKSİK");
  });
});
