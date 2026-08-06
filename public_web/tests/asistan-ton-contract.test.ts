import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

// docs/tek-asistan-plani.md Aşama 2 — tek yüz.
//
// Vixrex dört yüzeyde çıkıyor. Flutter tarafı esnafa "sen" diye hitap
// ediyordu, Next.js paneli "siz". Aynı esnaf, aynı vitrin, iki farklı ağız —
// "iki asistan" hissinin en somut kaynağı buydu.
//
// 2026-08-06 kararı: her yerde SEN. İlk teması Flutter kuruyor ve dört
// yüzeyin üçü orada; azınlığı çoğunluğa uydurmak hem daha az risk hem daha
// az metin değişikliği demekti.
//
// Bu dosya kaymayı yakalar: panele veya sahip uçlarına "siz" kipinde bir
// cümle eklenirse test kırılır.

const DOSYALAR = [
  "../src/app/v/[slug]/OwnerAssistantPanel.tsx",
  "../src/app/api/owner-draft/route.ts",
  "../src/app/api/owner-publish/route.ts",
  "../src/app/api/owner-discard/route.ts",
  "../src/app/api/owner-upload/route.ts",
  "../src/app/api/owner-session/route.ts",
];

/** "Siz" kipinin yaygın ekleri. Yalnız kullanıcıya gösterilen metinlerde aranır. */
const SIZ_KALIPLARI: Array<[string, RegExp]> = [
  ["-iniz/-ınız (vitrininiz, oturumunuz)", /[a-zçğıöşü](iniz|ınız|unuz|ünüz)\b/i],
  ["-eyin/-ayın (deneyin, tıklayın)", /[a-zçğıöşü](eyin|ayın)\b/i],
  ["misiniz / mısınız", /m[iı]s[iı]n[iı]z\b/i],
  ["-ebilirsiniz", /ebilirsiniz\b/i],
];

/** Yalnızca kullanıcıya gösterilen metinleri toplar (çift tırnaklı diziler). */
function kullaniciMetinleri(kaynak: string): string[] {
  const hepsi = kaynak.match(/"[^"\n]{12,}"/g) ?? [];
  return hepsi.filter((m) => {
    const icerik = m.slice(1, -1);
    // Sınıf adları, yollar ve teknik anahtarlar metin değildir.
    if (/^[a-z-]+\/[a-z-]+/.test(icerik)) return false;
    if (icerik.startsWith("/") || icerik.startsWith("http")) return false;
    if (/^[A-Z_]+$/.test(icerik)) return false;
    if (/(flex|rounded|text-|bg-|border|px-|py-|absolute|grid)/.test(icerik)) {
      return false;
    }
    // Türkçe cümle mi — en az bir boşluk ve bir harf.
    return /\s/.test(icerik) && /[a-zçğıöşüA-ZÇĞİÖŞÜ]/.test(icerik);
  });
}

describe("Vixrex Asistan tek ağızdan konuşur — hitap: sen", () => {
  for (const yol of DOSYALAR) {
    it(`${yol.split("/").pop()} içinde "siz" kipi yok`, () => {
      const kaynak = readFileSync(resolve(__dirname, yol), "utf-8");
      const metinler = kullaniciMetinleri(kaynak);

      for (const metin of metinler) {
        for (const [ad, kalip] of SIZ_KALIPLARI) {
          expect(
            kalip.test(metin),
            `"siz" kipi bulundu (${ad}):\n  ${metin}\n` +
              `Vixrex her yerde "sen" der. Bkz. docs/tek-asistan-plani.md`
          ).toBe(false);
        }
      }
    });
  }

  it("panelin bilinen cümleleri 'sen' kipinde", () => {
    const panel = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/OwnerAssistantPanel.tsx"),
      "utf-8"
    );
    expect(panel).toContain("Vitrinin yayınlandı");
    expect(panel).toContain("Değiştirmek istediğin yazıya");
    expect(panel).not.toContain("Vitrininiz yayınlandı");
  });
});
