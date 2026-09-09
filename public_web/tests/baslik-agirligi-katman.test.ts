import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Katman dışı eleman kuralı kilidi.
 *
 * 2026-09-09 canlı ölçüm: vixrex.com'da `<h1 class="font-black tracking-[-0.8px]
 * text-lp-text">` yazıyordu ama tarayıcıda ağırlık 700, aralık -0.02em, renk
 * başka çıkıyordu. Sebep: `globals.css` içindeki
 *
 *     h1, h2, h3, h4, h5, h6 { font-weight: 700; letter-spacing: -0.02em; color: ... }
 *
 * kuralı KATMAN DIŞINDA yazılmıştı. CSS basamaklandırmasında katman dışı
 * kurallar, `@layer utilities` içindeki Tailwind sınıflarını ezer. Sonuç:
 * karşılama sayfasındaki 15 başlığın 12'si sayfada yazan ayarı kullanamıyordu.
 * Flutter aynı başlıkları w900 / -0.8 ile çizdiği için iki yüz görünür biçimde
 * ayrışıyordu.
 *
 * Kaynak kodu karşılaştıran hiçbir parite testi bunu yakalayamazdı — kaynak
 * doğruydu. Yalnız canlı ölçüm gösterdi.
 *
 * Bu test farkı ölçmez; katman dışı eleman kuralının geri gelmesini engeller.
 */

const CSS = readFileSync(
  resolve(__dirname, "../src/app/globals.css"),
  "utf8"
);

/** `@layer ... { ... }` bloklarını (iç içe süslü parantezler dahil) çıkarır. */
function katmanlariCikar(hamKaynak: string): string {
  // Yorumlar ÖNCE temizlenir: yorum içinde geçen "@layer" kelimesi gerçek
  // kural sanılırsa ayıklayıcı koca bir bloğu atlar ve kontrol sessizce
  // hiçbir şey görmez. (Bu testin ilk sürümünde tam olarak bu oldu.)
  const kaynak = hamKaynak.replace(/\/\*[\s\S]*?\*\//g, "");
  let cikti = "";
  let i = 0;
  while (i < kaynak.length) {
    const bas = kaynak.indexOf("@layer", i);
    if (bas === -1) {
      cikti += kaynak.slice(i);
      break;
    }
    cikti += kaynak.slice(i, bas);
    const acilis = kaynak.indexOf("{", bas);
    if (acilis === -1) {
      i = bas + 6;
      continue;
    }
    let derinlik = 1;
    let j = acilis + 1;
    while (j < kaynak.length && derinlik > 0) {
      if (kaynak[j] === "{") derinlik++;
      else if (kaynak[j] === "}") derinlik--;
      j++;
    }
    i = j;
  }
  return cikti;
}

describe("katman dışı eleman kuralı yok", () => {
  it("başlık tipografisi @layer base içinde", () => {
    const blok = /@layer base\s*\{[\s\S]*?h1,\s*h2,\s*h3,\s*h4,\s*h5,\s*h6\s*\{/;
    expect(
      blok.test(CSS),
      "h1..h6 kuralı @layer base içinde olmalı; katman dışında kalırsa " +
        "sayfadaki font-black / tracking / text-lp-* ayarlarını ezer."
    ).toBe(true);
  });

  it("katman dışında tipografi ezen eleman kuralı yok", () => {
    const katmansiz = katmanlariCikar(CSS);
    // Çıplak eleman seçicisi (sınıf/kimlik/öznitelik içermeyen) + tipografi
    const kalip =
      /(?:^|[};*/\n])\s*((?:h[1-6]|p|a|span|button|input|textarea|label|li|ul|ol)\s*(?:,\s*(?:h[1-6]|p|a|span|button|input|textarea|label|li|ul|ol)\s*)*)\{([^}]*)\}/g;
    const suclular: string[] = [];
    let m: RegExpExecArray | null;
    while ((m = kalip.exec(katmansiz)) !== null) {
      const govde = m[2];
      if (/(font-weight|letter-spacing|(^|;)\s*color)\s*:/.test(govde)) {
        suclular.push(m[1].trim());
      }
    }
    expect(
      suclular,
      "Bu eleman kuralları katman dışında ve Tailwind sınıflarını ezer. " +
        "@layer base içine alın."
    ).toEqual([]);
  });
});
