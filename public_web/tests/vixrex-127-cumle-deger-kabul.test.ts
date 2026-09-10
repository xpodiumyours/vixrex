import { describe, expect, it } from "vitest";
import { VIXREX_NIYET_SOZLUGU } from "../src/lib/vixrexNiyetSozlugu";
import { resolveVixrexIntent } from "../src/lib/vixrexIntentResolver";
import { extractVixrexValue } from "../src/lib/vixrexValueExtractor";
import { validateField } from "../src/lib/vitrinFieldValidation";

function gecerliHamDeger(anahtar: string, tip: string): string {
  if (anahtar === "whatsapp") return "0555 123 45 67";
  if (tip === "telefon") return "0212 555 44 33";
  if (tip === "eposta") return "info@aymira.com";
  if (anahtar === "adres") return "Atatürk Cad. No:24";
  if (anahtar === "kategori") return "Teknik Servis";
  if (anahtar === "enlem") return "41.025";
  if (anahtar === "boylam") return "29.05";
  if (anahtar === "galeriAksiyonLinki") return "#galeri";
  if (tip === "url" || tip === "gorsel") return "https://example.com/deger";
  if (anahtar === "calismaSaatleri") return "09:00-18:00";
  if (anahtar === "instagram") return "aymiragiyim";
  return "Örnek Değer";
}

const sabitBeklenen: Record<string, string> = {
  "İşletme adını 'Aymira Giyim' yap": "Aymira Giyim",
  "Rozeti 'Kadıköy'ün En İyisi' yap": "Kadıköy'ün En İyisi",
  "Konum metnini 'Kadıköy, İstanbul' yap": "Kadıköy, İstanbul",
  "Kategorimi Kuaför yap": "Kuaför",
  "İşletme türünü 'Erkek Kuaförü' yap": "Erkek Kuaförü",
  "WhatsApp numaramı 0555 123 45 67 yap": "0555 123 45 67",
  "Adresimi 'Atatürk Cad. No:24' yap": "Atatürk Cad. No:24",
  "İli İstanbul yap": "İstanbul",
  "İlçeyi Kadıköy yap": "Kadıköy",
  "Mahalleyi Caddebostan yap": "Caddebostan",
  "Harita etiketini 'Çarşı içi, otopark var' yap": "Çarşı içi, otopark var",
  "Çalışma saatlerini '09:00-18:00' yap": "09:00-18:00",
  "Instagramı aymiragiyim yap": "aymiragiyim",
  "Web sitemi https://aymira.com yap": "https://aymira.com",
  "Enlemi 41.025 yap": "41.025",
  "Boylamı 29.05 yap": "29.05",
  "Kampanya etiketini 'Bu haftaya özel' yap": "Bu haftaya özel",
  "Kampanya fiyatını '499 TL' yap": "499 TL",
};

describe("Vixrex mevcut 127 cümle — niyet + değer + doğrulama", () => {
  it("sözlükteki kayıtlı cümle sayısı 127", () => {
    const toplam = VIXREX_NIYET_SOZLUGU.reduce(
      (n, alan) => n + alan.ornekIfadeler.length,
      0,
    );
    expect(toplam).toBe(127);
  });

  it("{deger} içeren her kayıtlı kalıp değeri eksiksiz ayırır ve doğrular", () => {
    const hatalar: string[] = [];
    for (const alan of VIXREX_NIYET_SOZLUGU) {
      for (const ornek of alan.ornekIfadeler) {
        if (!ornek.includes("{deger}")) continue;
        const beklenen = gecerliHamDeger(alan.anahtar, alan.tip);
        const input = ornek.replaceAll("{deger}", beklenen);
        const bulunan = resolveVixrexIntent(input);
        const ham = bulunan ? extractVixrexValue(input, bulunan) : null;
        const dogrulama = ham === null ? null : validateField(alan.anahtar, ham);
        if (
          bulunan?.anahtar !== alan.anahtar ||
          ham !== beklenen ||
          dogrulama?.ok !== true
        ) {
          hatalar.push(
            `${alan.anahtar}: ${JSON.stringify(input)} -> intent=${bulunan?.anahtar ?? "null"}, deger=${JSON.stringify(ham)}, valid=${dogrulama?.ok ?? false}`,
          );
        }
      }
    }
    expect(hatalar, hatalar.join("\n")).toEqual([]);
  });

  it("değeri sabit yazılmış kritik doğal örnekleri de eksiksiz ayırır", () => {
    const hatalar: string[] = [];
    for (const [input, beklenen] of Object.entries(sabitBeklenen)) {
      const alan = resolveVixrexIntent(input);
      const ham = alan ? extractVixrexValue(input, alan) : null;
      if (!alan || ham !== beklenen) {
        hatalar.push(
          `${JSON.stringify(input)} -> ${alan?.anahtar ?? "null"} / ${JSON.stringify(ham)}; beklenen=${JSON.stringify(beklenen)}`,
        );
      }
    }
    expect(hatalar, hatalar.join("\n")).toEqual([]);
  });
});
