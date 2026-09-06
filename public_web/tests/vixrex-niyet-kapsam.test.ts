import { describe, expect, it } from "vitest";
import { resolveVixrexIntent } from "../src/lib/vixrexIntentResolver";
import { VIXREX_NIYET_SOZLUGU } from "../src/lib/vixrexNiyetSozlugu";

/**
 * NİYET KAPSAM BEKÇİSİ (2026-09-06)
 *
 * NEDEN VAR: Motor uzun süre "çalışıyor" sayıldı ama kendi sözlüğünde yazılı
 * örnek cümlelerin yalnız %83'ünü tanıyordu ve İKİ cümlede YANLIŞ ALANI
 * seçiyordu ("Kategori başlığını ... yap" → `kategori`). Bu test o günü
 * tekrar etmemek için var:
 *
 *  1. Sözlükteki her örnek cümle, kendi alanını bulmalı.
 *  2. Hiçbir cümle BAŞKA bir alana gitmemeli (yanlış alan = veri kaybı).
 *  3. Alan adı gibi görünen ama komut olmayan cümleler eşleşmemeli.
 *
 * Türkçe kuralları (kaynaştırma 'y', ünsüz yumuşaması k→g/p→b/t→d, çok
 * kelimeli ifadede baştaki kelimenin çekimi) bu testler olmadan sessizce
 * geriye gidebilir.
 */
describe("Vixrex niyet motoru — sözlük kapsamı", () => {
  it("sözlükteki HER örnek cümle kendi alanını bulur", () => {
    const basarisiz: string[] = [];

    for (const alan of VIXREX_NIYET_SOZLUGU) {
      for (const ornek of alan.ornekIfadeler ?? []) {
        const cumle = ornek.replace(/\{deger\}/g, "Ada");
        const bulunan = resolveVixrexIntent(cumle);
        if (bulunan?.anahtar !== alan.anahtar) {
          basarisiz.push(
            `${alan.anahtar} | "${cumle}" → ${bulunan?.anahtar ?? "HİÇ"}`,
          );
        }
      }
    }

    expect(basarisiz, `tanınmayan örnek cümleler:\n${basarisiz.join("\n")}`).toEqual([]);
  });

  it("hiçbir örnek cümle BAŞKA bir alana gitmez", () => {
    const yanlisAlan: string[] = [];

    for (const alan of VIXREX_NIYET_SOZLUGU) {
      for (const ornek of alan.ornekIfadeler ?? []) {
        const cumle = ornek.replace(/\{deger\}/g, "Ada");
        const bulunan = resolveVixrexIntent(cumle);
        if (bulunan && bulunan.anahtar !== alan.anahtar) {
          yanlisAlan.push(`"${cumle}" → ${bulunan.anahtar} (doğrusu: ${alan.anahtar})`);
        }
      }
    }

    // Yanlış alan, hiç tanımamaktan DAHA KÖTÜdür: esnaf başlığı değiştirmek
    // isterken kategorisi değişir. Bu liste her zaman boş kalmalı.
    expect(yanlisAlan, `yanlış alana giden cümleler:\n${yanlisAlan.join("\n")}`).toEqual([]);
  });

  it("komut olmayan cümlelerde alan eşleştirmez", () => {
    // "alan", "tür", "otel" gibi kelimeler sözlükte eş anlam olarak geçiyor;
    // günlük cümlede geçtiklerinde vitrin alanı değiştirmemeliler.
    const tuzaklar = [
      "Galeri alanını büyüt",
      "Bu alanı boş bırak",
      "Otel tavsiyesi ver",
      "Turu iptal et",
      "Menü fiyatlarını güncelle",
    ];

    const eslesenler = tuzaklar
      .map((cumle) => ({ cumle, alan: resolveVixrexIntent(cumle)?.anahtar }))
      .filter((x) => x.alan);

    expect(
      eslesenler,
      `komut olmayan cümlede eşleşme:\n${eslesenler.map((x) => `"${x.cumle}" → ${x.alan}`).join("\n")}`,
    ).toEqual([]);
  });

  it("gerçek esnaf cümleleri doğru alana gider", () => {
    const ornekler: ReadonlyArray<readonly [string, string]> = [
      ["İşletme adını Ada Kahve yap", "isletmeAdi"],
      ["Dükkan adımı Ada Kahve olarak değiştir", "isletmeAdi"],
      ["Açıklamayı güncelle", "kisaTanitim"],
      ["Whatsapp numaramı 05551234567 yap", "whatsapp"],
      ["Mahalleyi Caddebostan yap", "mahalle"],
      ["Semti Caddebostan yap", "mahalle"],
      ["İlçeyi Kadıköy yap", "ilce"],
      ["Kategoriyi Kafe yap", "kategori"],
      ["Kategori başlığını Ada yap", "kategoriBolumBaslik"],
      ["Galeri üst başlığı Ada yap", "galeriUstBaslik"],
      ["Kapağı değiştir", "kapakGorseli"],
      ["Puanı gizle", "puanGoster"],
      ["Navigasyonu kapat", "yolTarifiGoster"],
    ];

    const hatalar = ornekler
      .map(([cumle, beklenen]) => ({
        cumle,
        beklenen,
        bulunan: resolveVixrexIntent(cumle)?.anahtar ?? "HİÇ",
      }))
      .filter((x) => x.bulunan !== x.beklenen);

    expect(
      hatalar,
      `yanlış sonuç:\n${hatalar.map((x) => `"${x.cumle}" → ${x.bulunan} (bek: ${x.beklenen})`).join("\n")}`,
    ).toEqual([]);
  });
});
