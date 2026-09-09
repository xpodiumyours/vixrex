import { readFileSync, readdirSync, statSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
import {
  hizliSecenekEtiketi,
  vixRexHizliSecenekler,
  vixRexIntentSemasi,
} from "../src/lib/vixrexMesajlari";
import { sharedAssistantReply } from "../src/lib/assistantConversation";

/**
 * Hızlı seçeneklerin (Hazır Vitrin Seç / Sıfırdan Oluştur / Bakınıyorum)
 * TEK KAYNAK kilidi.
 *
 * Neden var: 2026-09-09'da ölçüldüğünde bu üç buton dört ayrı yüzeyde
 * (karşılama asistanı, uygulama içi asistan, kayıt sayfası, Flutter) farklı
 * yazılarla ve farklı davranışlarla duruyordu. Kayıt sayfasındaki etiketler
 * elle yazıldığı için "Bakiniyorum" diye hatalı bir yazı canlıda duruyordu ve
 * ortak kaynak değiştiğinde o sayfa değişmiyordu.
 *
 * Bu test farkı ÖLÇMEZ; farkın yeniden oluşmasını ENGELLER.
 */

const SRC = resolve(__dirname, "../src");

function tsxDosyalari(dizin: string): string[] {
  const cikti: string[] = [];
  for (const ad of readdirSync(dizin)) {
    const tam = resolve(dizin, ad);
    if (statSync(tam).isDirectory()) cikti.push(...tsxDosyalari(tam));
    else if (ad.endsWith(".tsx") || ad.endsWith(".ts")) cikti.push(tam);
  }
  return cikti;
}

/** Yorum satırlarını atar — yorumda etiket geçmesi serbesttir. */
function yorumsuz(kaynak: string): string {
  return kaynak
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .split("\n")
    .filter((satir) => !satir.trimStart().startsWith("//"))
    .join("\n");
}

describe("hızlı seçenekler — tek kaynak", () => {
  it("üç seçeneğin de etiketi ortak katalogdan geliyor", () => {
    for (const id of ["hazir_vitrin_sec", "sifirdan_olustur", "bakiniyorum"]) {
      expect(hizliSecenekEtiketi(id).length).toBeGreaterThan(0);
    }
    expect(vixRexHizliSecenekler).toHaveLength(3);
  });

  it("hiçbir ekran etiketi elle yazmıyor", () => {
    const etiketler = vixRexHizliSecenekler.map((s) => s.etiket);
    const suclular: string[] = [];

    for (const dosya of tsxDosyalari(SRC)) {
      if (dosya.endsWith("vixrexMesajlari.ts")) continue; // kaynağı okuyan dosya
      const govde = yorumsuz(readFileSync(dosya, "utf8"));
      for (const etiket of etiketler) {
        if (govde.includes(`"${etiket}"`) || govde.includes(`>${etiket}<`)) {
          suclular.push(`${dosya.replace(SRC, "src")} → ${etiket}`);
        }
      }
    }

    expect(
      suclular,
      "Bu ekranlar hızlı seçenek etiketini elle yazıyor. " +
        'hizliSecenekEtiketi("<id>") kullanın; yoksa ortak katalog ' +
        "değiştiğinde bu ekran eski yazıyı göstermeye devam eder."
    ).toEqual([]);
  });

  it("'Sıfırdan Oluştur' asistan tarafından anlaşılıyor", () => {
    // Uygulama içi asistanda bu buton, etiketi kullanıcı mesajı olarak
    // konuşmaya düşürür. Katalogda karşılığı yoksa asistan "anlayamadım"
    // der ve buton yine hiçbir şey yapmamış olur.
    const cevap = sharedAssistantReply(hizliSecenekEtiketi("sifirdan_olustur"));
    expect(cevap.key).not.toBe("anlasilamadi");
    expect(cevap.key).toBe("vitrin_kurulum");
  });

  it("katalogda 'sıfırdan oluştur' niyeti tanımlı", () => {
    const niyet = vixRexIntentSemasi.find((i) => i.payload === "vitrin_kurulum");
    expect(niyet, "shared/vixrex_mesajlar.json → intentler").toBeTruthy();
    expect(niyet!.anahtarKelimeler).toContain("sifirdan olustur");
  });
});
