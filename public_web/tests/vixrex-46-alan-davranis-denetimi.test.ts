import { describe, expect, it } from "vitest";
import { VIXREX_NIYET_SOZLUGU } from "../src/lib/vixrexNiyetSozlugu";
import { resolveVixrexIntent, resolveVixrexIntentsAll } from "../src/lib/vixrexIntentResolver";
import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

/**
 * 46 alanın yalnız sözlükte SAYILMASINI değil, sözlüğün kendi konuşma
 * örneklerinin gerçek resolver tarafından tanınmasını kilitler.
 *
 * Bu test tek tek seçilmiş birkaç mutlu yol kullanmaz: Vixrex'in kendi
 * `shared/vixrex_niyet_sozlugu.json` kaynağındaki HER alanın HER örneği
 * ürün davranışına sokulur. Yeni alan/örnek eklendiğinde otomatik kapsanır.
 */
describe("Vixrex Assistant 46 alan davranış denetimi", () => {
  it("46 alanın her sözlük örneği kendi alanına çözülür", () => {
    expect(VIXREX_NIYET_SOZLUGU).toHaveLength(46);

    const hatalar: string[] = [];
    for (const alan of VIXREX_NIYET_SOZLUGU) {
      for (const ornek of alan.ornekIfadeler) {
        const input = ornek.replaceAll("{deger}", "Örnek Değer");
        const bulunan = resolveVixrexIntent(input);
        if (bulunan?.anahtar !== alan.anahtar) {
          hatalar.push(`${alan.anahtar}: ${JSON.stringify(input)} -> ${bulunan?.anahtar ?? "null"}`);
        }
      }
    }

    expect(hatalar, hatalar.join("\n")).toEqual([]);
  });

  it("kısa alan adı sıradan kelimenin içinden yanlış niyet üretmez", () => {
    const alanlar = resolveVixrexIntentsAll("Ailece müşterilerimize hizmet veriyoruz.");
    expect(alanlar.map((a) => a.anahtar)).not.toContain("il");
  });

  it("aç/kapat komutları gerçek pipeline sonucunda boolean üretir", async () => {
    const ac = await handleVixrexNluMessage("Puanı göster");
    expect(ac.outcome).toBe("handled");
    expect(ac.anahtar).toBe("puanGoster");
    expect(ac.deger).toBe(true);

    const kapat = await handleVixrexNluMessage("Yol tarifi butonunu gizle");
    expect(kapat.outcome).toBe("handled");
    expect(kapat.anahtar).toBe("yolTarifiGoster");
    expect(kapat.deger).toBe(false);
  });

  it("çoklu niyette bir alan özel akış isterse diğer alanı kısmi başarı diye döndürmez", async () => {
    const result = await handleVixrexNluMessage(
      "Telefonu 0212 123 45 67 yap, ili İstanbul yap"
    );
    expect(result.outcome).toBe("needsClarification");
    expect(result.tumu).toBeUndefined();
  });
});
