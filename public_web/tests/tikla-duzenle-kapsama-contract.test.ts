import { readdirSync, readFileSync, statSync } from "fs";
import { join, resolve } from "path";
import { describe, expect, it } from "vitest";

/**
 * Tıkla-düzenle kapsama sözleşmesi (2026-08-29).
 *
 * NEDEN BU TEST VAR
 * Vitrinin sahip tarafındaki tüm hakimiyeti tek bir mekanizmaya bağlı:
 * `editableProps(anahtar, ownerMode)` çağrısı JSX'e yayıldığında o öğe
 * tıklanıp düzenlenebilir oluyor (bkz. src/lib/vitrinEditableProps.ts).
 * Yayılım düşerse sayfa GÖRSEL OLARAK AYNI kalır, hiçbir test kırılmaz,
 * ama sahip o alanı bir daha düzenleyemez. Sessiz kayıp.
 *
 * 2026-08-29'da vitrin görünümü elden geçirilirken (1372 satırlık
 * VitrinProfileView.tsx) tam bu risk vardı ve o güne kadar bunu ölçen
 * hiçbir test yoktu: `data-vixrex-editable` hiçbir test dosyasında geçmiyordu.
 *
 * Bu test kaynak metnini okur — tarayıcı çalıştırmaz, veri gerektirmez.
 */

const semaKaynak = readFileSync(
  resolve(__dirname, "../src/lib/vitrinFieldSchema.ts"),
  "utf-8"
);

function tsxDosyalari(dizin: string, toplam: string[] = []): string[] {
  for (const ad of readdirSync(dizin)) {
    const yol = join(dizin, ad);
    if (statSync(yol).isDirectory()) {
      if (ad === "node_modules" || ad === ".next") continue;
      tsxDosyalari(yol, toplam);
    } else if (ad.endsWith(".tsx")) {
      toplam.push(yol);
    }
  }
  return toplam;
}

const kodKaynak = tsxDosyalari(resolve(__dirname, "../src"))
  .map((yol) => readFileSync(yol, "utf-8"))
  .join("\n");

const semadakiAlanlar = new Set(
  [...semaKaynak.matchAll(/anahtar:\s*"([a-zA-Z0-9_]+)"/g)].map((m) => m[1])
);

const isaretliAlanlar = new Set(
  [...kodKaynak.matchAll(/editableProps\(\s*"([a-zA-Z0-9_]+)"/g)].map((m) => m[1])
);

/**
 * Sayfada tıklanacak bir metin karşılığı OLMAYAN alanlar. Koordinatlar,
 * adresin parçaları (birleşik `adres` olarak gösteriliyor) ve aç/kapa
 * ayarları buraya girer. Bu liste UZARSA sebebi yazılmalı — bir alanın
 * sessizce "düzenlenemez" ilan edilmesi tam da bu testin engellediği şey.
 */
const GOSTERILMEYEN_ALANLAR = new Set([
  "enlem",
  "boylam",
  "il",
  "ilce",
  "mahalle",
  "isletmeTuru",
  "yolTarifiGoster",
  "galeriAksiyonLinki",
  "instagram",
]);

/** 2026-08-29 ölçümü. Kapsama bunun ALTINA düşemez. */
const TABAN_ISARETLI_SAYI = 37;

describe("tıkla-düzenle kapsaması — sahip hakimiyeti kaybolmasın", () => {
  it("şemadaki her görünür alan sayfada işaretli", () => {
    const eksikler = [...semadakiAlanlar]
      .filter((alan) => !isaretliAlanlar.has(alan))
      .filter((alan) => !GOSTERILMEYEN_ALANLAR.has(alan))
      .sort();

    expect(
      eksikler,
      `Bu alanlar şemada var ama hiçbir bileşende editableProps(...) ile ` +
        `işaretlenmemiş — sahip onları tıklayıp değiştiremez: ${eksikler.join(", ")}`
    ).toEqual([]);
  });

  it("işaretli alan sayısı tabanın altına düşmedi", () => {
    expect(
      isaretliAlanlar.size,
      `Önceden ${TABAN_ISARETLI_SAYI} alan işaretliydi, şimdi ` +
        `${isaretliAlanlar.size}. Bir editableProps(...) yayılımı düşmüş olabilir.`
    ).toBeGreaterThanOrEqual(TABAN_ISARETLI_SAYI);
  });

  it("kodda şemada olmayan anahtar işaretlenmemiş", () => {
    const tanimsizlar = [...isaretliAlanlar]
      .filter((alan) => !semadakiAlanlar.has(alan))
      .sort();

    expect(
      tanimsizlar,
      `Şemada olmayan anahtar işaretlenmiş — editableProps sessizce boş ` +
        `nesne döndürür, alan düzenlenemez görünür: ${tanimsizlar.join(", ")}`
    ).toEqual([]);
  });

  it("hero ve iletişim gibi temel alanlar kapsamda", () => {
    for (const alan of ["isletmeAdi", "kisaTanitim", "adres", "whatsapp", "kapakGorseli"]) {
      expect(isaretliAlanlar.has(alan), `${alan} işaretli değil`).toBe(true);
    }
  });
});
