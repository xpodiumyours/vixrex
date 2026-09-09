import { readFileSync, readdirSync, statSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { FIELD_BY_KEY, VITRIN_FIELDS } from "@/lib/vitrinFieldSchema";

/**
 * Vitrin alan etiketleri — TEK KAYNAK kilidi (eski "SSS paritesi" testinin
 * yerine geçer).
 *
 * Eski test neyi ölçüyordu: bir testte yalnız Flutter dosyasında, başka bir
 * testte yalnız web dosyasında kelime arıyordu; ikisini hiç karşılaştırmıyordu.
 * Üstelik yanlış yüzeyleri eşleştiriyordu — Flutter'ın hem soru-cevap hem
 * bölüm başlıklarını düzenleyen ekranı, web'in YALNIZ soru-cevap düzenleyen
 * ekranıyla. "SSS paritesi ✓" demek, pratikte "Dart dosyasında `items`, TSX
 * dosyasında `FaqItem` kelimesi geçiyor" demekti.
 *
 * 2026-09-09 ölçümünde bunun altından gerçek bir ayrışma çıktı: web
 * "SSS Üst Başlığı" / "Blog Başlığı" derken şema ve Flutter "SSS Üst Başlık" /
 * "Blog Bölüm Başlığı" diyordu. Esnaf iki yüzde farklı isim görüyordu.
 *
 * Bu test farkı ÖLÇMEZ; farkın yeniden oluşmasını ENGELLER. Flutter tarafının
 * aynası: `test/vitrin_alan_tek_kaynak_test.dart`.
 */

const SAHIP = resolve(__dirname, "../src/components/owner");

function tsxDosyalari(dizin: string): string[] {
  const cikti: string[] = [];
  for (const ad of readdirSync(dizin)) {
    const tam = resolve(dizin, ad);
    if (statSync(tam).isDirectory()) cikti.push(...tsxDosyalari(tam));
    else if (ad.endsWith(".tsx") || ad.endsWith(".ts")) cikti.push(tam);
  }
  return cikti;
}

function yorumsuz(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .split("\n")
    .filter((satir) => !satir.trimStart().startsWith("//"))
    .join("\n");
}

describe("vitrin alan etiketleri — tek kaynak", () => {
  it("sahip düzenleyicileri alan etiketini elle yazmaz", () => {
    const suclular: string[] = [];
    for (const dosya of tsxDosyalari(SAHIP)) {
      const govde = yorumsuz(readFileSync(dosya, "utf8"));
      for (const alan of VITRIN_FIELDS) {
        if (govde.includes(`"${alan.etiket}"`)) {
          suclular.push(`${dosya.replace(SAHIP, "owner")} → ${alan.etiket}`);
        }
      }
    }

    expect(
      suclular,
      "Bu ekranlar alan etiketini elle yazıyor. Şemadan okuyun " +
        "(alanEtiketi / FIELD_BY_KEY); yoksa shared/vitrin_alanlari.json " +
        "değiştiğinde bu ekran eskisini gösterir ve Flutter ile ayrışır."
    ).toEqual([]);
  });

  it("SSS bölüm alanları şemada tanımlı ve sınırları var", () => {
    for (const anahtar of ["sssUstBaslik", "sssBaslik", "sssAciklama"]) {
      const alan = FIELD_BY_KEY.get(anahtar);
      expect(alan, `şemada yok: ${anahtar}`).toBeTruthy();
      expect(alan!.etiket.length).toBeGreaterThan(0);
      expect(alan!.maxUzunluk, `${anahtar} uzunluk sınırı`).toBeTruthy();
    }
  });

  it("SSS soru-cevap düzenleyicisi hâlâ soru ve cevap alanı sunuyor", () => {
    // Bu, yüzeyin var olduğunun kontrolü — parite iddiası değil.
    const faq = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/components/FaqEditor.tsx"),
      "utf8"
    );
    expect(faq).toContain("question");
    expect(faq).toContain("answer");
  });
});
